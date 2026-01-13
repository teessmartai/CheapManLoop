# AI Agent Loop Script

A bash script that continuously runs an AI agent in a loop until a completion criteria is met or maximum iterations is reached. Handles rate limits intelligently by sleeping until the limit resets.

## Features

- ✅ Configurable AI agent command
- ✅ Automatic rate limit detection and smart sleep
- ✅ Completion marker detection
- ✅ Maximum iteration limit
- ✅ UTC timestamp logging
- ✅ Error handling and retry logic
- ✅ Docker-friendly

## Usage

```bash
./ai_agent_loop.sh <agent_command> [max_iterations] [prompt_file]
```

### Parameters

1. **agent_command** (required): The command to run your AI agent
2. **max_iterations** (optional, default: 10): Maximum number of iterations before giving up
3. **prompt_file** (optional, default: prompt.md): Path to the prompt file

### Examples

```bash
# Basic usage with default settings
./ai_agent_loop.sh "./my-agent"

# Custom max iterations
./ai_agent_loop.sh "./my-agent" 20

# Custom prompt file
./ai_agent_loop.sh "./my-agent" 10 custom_prompt.md

# Using with a Python agent
./ai_agent_loop.sh "python agent.py" 15 prompt.md
```

## How It Works

1. **Loop**: Runs the AI agent by piping the prompt file (`cat prompt.md | <agent_command>`)
2. **Completion Check**: Looks for "TASK_COMPLETE" in the agent output
3. **Rate Limit Handling**:
   - Detects message: "You've hit your limit. Limit resets at X pm/am (UTC)"
   - Calculates sleep duration until reset time
   - Sleeps and resumes (doesn't count as iteration)
4. **Error Handling**: Other failures are retried and count as iterations
5. **Max Iterations**: Exits with error if max iterations reached without completion

## Rate Limit Format

The script expects rate limit messages in this format:
```
You've hit your limit. Limit resets at 4 pm (UTC)
```

It will parse the time and calculate how long to sleep until that time arrives.

## Exit Codes

- **0**: Task completed successfully (TASK_COMPLETE marker found)
- **1**: Max iterations reached without completion, or error occurred

## Logging

All output is logged to stdout with timestamps:
- Iteration numbers
- UTC timestamps
- Agent output
- Rate limit sleep notifications
- Completion status

## Docker Usage

The script is designed to run in Docker containers. Simply include it in your Dockerfile:

```dockerfile
COPY ai_agent_loop.sh /app/
COPY prompt.md /app/
RUN chmod +x /app/ai_agent_loop.sh

CMD ["/app/ai_agent_loop.sh", "./my-agent", "10", "prompt.md"]
```

## Requirements

- Bash (version 4.0+)
- Standard Unix utilities: `date`, `grep`, `sed`
- Your AI agent binary or script
- A prompt file (default: prompt.md)

## Testing

A test agent (`test_agent.sh`) is included to demonstrate the script functionality:

```bash
# Run the test (will simulate rate limit and completion)
./ai_agent_loop.sh "./test_agent.sh" 10 prompt.md
```

The test agent will:
1. Complete steps 1 and 2
2. Hit a simulated rate limit on step 3
3. Sleep until the reset time
4. Complete remaining steps 3, 4, and 5
5. Output TASK_COMPLETE

**Note**: The test agent simulates a rate limit reset time. For quick testing, you may want to modify the reset time in `test_agent.sh` to be just a few minutes in the future.

## Notes

- The script does not persist state - the AI agent should track its own progress
- Rate limit retries do not count toward max iterations
- All times are handled in UTC
- A 60-second buffer is added after rate limit reset time to ensure the limit has actually reset
