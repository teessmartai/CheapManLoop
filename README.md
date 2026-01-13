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
./ai_agent_loop.sh <agent_command> <user_prompt> <completion_criteria> [max_iterations] [agent_prompt_file]
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
./ai_agent_loop.sh "claude" "Fix the login bug in auth.js" "All tests pass and users can log in"

# Using file-based prompts with @filename syntax
./ai_agent_loop.sh "claude" @task.md @criteria.md

# Custom max iterations
./ai_agent_loop.sh "./my-agent" "Refactor the database layer" "Code compiles and all tests pass" 20

# Using with a Python agent
./ai_agent_loop.sh "python agent.py" @feature_request.md "Feature implemented and documented" 15
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
./ai_agent_loop.sh "./test_agent.sh" "Complete the test task" "All 5 steps completed"
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

## Notes

- The script does not persist state - the AI agent should track its own progress in `AGENT_PROGRESS.md`
- Rate limit retries do not count toward max iterations
- All times are handled in UTC
- A 60-second buffer is added after rate limit reset time to ensure the limit has actually reset
- Use @filename syntax to read prompts from files instead of inline text
