# AI Agent Loop Script

A bash script that continuously runs an AI agent in a loop for software development tasks. The agent runs until completion criteria are met or maximum iterations is reached. Handles rate limits intelligently by sleeping until the limit resets.

## Features

- Configurable AI agent command
- User-defined task prompts and completion criteria
- Software development focused agent prompt
- Automatic rate limit detection and smart sleep
- Completion marker detection
- Maximum iteration limit
- UTC timestamp logging
- Support for inline text or file-based prompts (@filename syntax)

## Usage

```bash
./cheap_man_loop.sh <agent_command> <user_prompt> <completion_criteria> [max_iterations] [agent_prompt_file]
```

### Parameters

1. **agent_command** (required): The command to run your AI agent
2. **user_prompt** (required): The task for the agent (text or @filename)
3. **completion_criteria** (required): Criteria for task completion (text or @filename)
4. **max_iterations** (optional, default: 10): Maximum number of iterations
5. **agent_prompt_file** (optional, default: agent_prompt.md): Path to the agent system prompt

### Examples

```bash
# Simple inline task with completion criteria
./cheap_man_loop.sh "claude" "Fix the login bug in auth.js" "All tests pass and users can log in"

# Using file-based prompts with @filename syntax
./cheap_man_loop.sh "claude" @task.md @criteria.md

# Custom max iterations
./cheap_man_loop.sh "./my-agent" "Refactor the database layer" "Code compiles and all tests pass" 20

# Using with a Python agent
./cheap_man_loop.sh "python agent.py" @feature_request.md "Feature implemented and documented" 15
```

## How It Works

1. **Prompt Assembly**: Combines the agent prompt (software dev focused) with your task and completion criteria
2. **Loop**: Runs the AI agent with the combined prompt via stdin
3. **Completion Check**: Looks for "TASK_COMPLETE" in the agent output
4. **Rate Limit Handling**:
   - Detects message: "You've hit your limit. Limit resets at X pm/am (UTC)"
   - Calculates sleep duration until reset time
   - Sleeps and resumes (doesn't count as iteration)
5. **Max Iterations**: Exits with error if max iterations reached without completion

## Agent Prompt Structure

The `agent_prompt.md` file contains a software development focused system prompt that:

- Instructs the agent to track progress in `AGENT_PROGRESS.md`
- Guides incremental, commit-friendly work
- Embeds the completion criteria you provide
- Appends your user task prompt

The placeholders `{COMPLETION_CRITERIA}` and `{USER_PROMPT}` in the agent prompt are replaced with your actual content at runtime.

## Rate Limit Format

The script expects rate limit messages in this format:
```
You've hit your limit. Limit resets at 4 pm (UTC)
```

It will parse the time and calculate how long to sleep until that time arrives.

## Exit Codes

- **0**: Task completed successfully (TASK_COMPLETE marker found)
- **1**: Max iterations reached without completion, or error occurred

## Testing

A test agent (`test_agent.sh`) is included to demonstrate the script functionality:

```bash
# Run the test (will simulate rate limit and completion)
./cheap_man_loop.sh "./test_agent.sh" "Complete the test task" "All 5 steps completed"
```

The test agent will:
1. Complete steps 1 and 2
2. Hit a simulated rate limit on step 3
3. Sleep until the reset time
4. Complete remaining steps 3, 4, and 5
5. Output TASK_COMPLETE

**Note**: The test agent simulates a rate limit reset time. For quick testing, you may want to modify the reset time in `test_agent.sh` to be just a few minutes in the future.

## Requirements

- Bash (version 4.0+)
- Standard Unix utilities: `date`, `grep`, `sed`
- Your AI agent binary or script
- Agent prompt file (default: agent_prompt.md)

## Docker Usage

Run the agent in a Docker container that automatically clones a repo, makes changes, and creates a PR.

### Build the Image

```bash
docker build -t cheap_man_loop .
```

### Run the Container

```bash
docker run \
  -e GITHUB_TOKEN=ghp_your_token_here \
  -e REPO_URL=https://github.com/owner/repo \
  -e GIT_USER_NAME="Your Name" \
  -e GIT_USER_EMAIL="your@email.com" \
  cheap_man_loop \
  'Fix the authentication bug in login.py' \
  'All tests pass and a PR is created with the fix'
```

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GITHUB_TOKEN` | Yes | - | GitHub Personal Access Token with `repo` scope |
| `REPO_URL` | Yes | - | Repository HTTPS URL (e.g., `https://github.com/owner/repo`) |
| `GIT_USER_NAME` | No | `AI Agent` | Git user name for commits |
| `GIT_USER_EMAIL` | No | `agent@example.com` | Git user email for commits |
| `BRANCH` | No | `ai-agent-<timestamp>` | Branch name to create |
| `AGENT_COMMAND` | No | `claude` | AI agent command to run |
| `MAX_ITERATIONS` | No | `10` | Maximum loop iterations |

### Examples

```bash
# Basic usage - fix a bug and create PR
docker run \
  -e GITHUB_TOKEN=$GITHUB_TOKEN \
  -e REPO_URL=https://github.com/myorg/myrepo \
  cheap_man_loop \
  'Fix the null pointer exception in UserService.java' \
  'Bug is fixed, tests pass, PR created'

# Specify a custom branch name
docker run \
  -e GITHUB_TOKEN=$GITHUB_TOKEN \
  -e REPO_URL=https://github.com/myorg/myrepo \
  -e BRANCH=fix/auth-bug \
  cheap_man_loop \
  'Fix authentication bypass vulnerability' \
  'Security fix implemented with tests, PR created for review'

# Use a different AI agent with more iterations
docker run \
  -e GITHUB_TOKEN=$GITHUB_TOKEN \
  -e REPO_URL=https://github.com/myorg/myrepo \
  -e AGENT_COMMAND="./my-custom-agent" \
  -e MAX_ITERATIONS=20 \
  cheap_man_loop \
  'Implement dark mode feature' \
  'Dark mode toggle works, CSS variables used, PR created'
```

### Getting a GitHub Token

1. Go to GitHub Settings > Developer settings > Personal access tokens > Tokens (classic)
2. Click "Generate new token (classic)"
3. Select the `repo` scope (full control of private repositories)
4. Copy the generated token and use it as `GITHUB_TOKEN`

### Security Notes

- **Never commit your `GITHUB_TOKEN`** - always pass it as an environment variable
- Use tokens with minimal required scopes
- Consider using GitHub's fine-grained tokens for more restrictive permissions
- The token is used in-memory only and is not persisted in the container

### How It Works

1. Container starts and validates required environment variables
2. Configures git with provided credentials
3. Clones the specified repository
4. Creates a new branch (or uses specified branch)
5. Runs the `cheap_man_loop.sh` with enhanced completion criteria that include:
   - Committing changes
   - Pushing to the remote branch
   - Creating a pull request using GitHub CLI (`gh`)
6. Agent works iteratively until completion criteria are met
7. Container exits with success (0) or failure (1) status

## Notes

- The script does not persist state - the AI agent should track its own progress in `AGENT_PROGRESS.md`
- Rate limit retries do not count toward max iterations
- All times are handled in UTC
- A 60-second buffer is added after rate limit reset time to ensure the limit has actually reset
- Use @filename syntax to read prompts from files instead of inline text
