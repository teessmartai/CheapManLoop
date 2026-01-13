#!/bin/bash

set -euo pipefail

# Configuration
AGENT_COMMAND="${1:-}"
MAX_ITERATIONS="${2:-10}"
PROMPT_FILE="${3:-prompt.md}"

# Usage check
if [ -z "$AGENT_COMMAND" ]; then
    echo "Usage: $0 <agent_command> [max_iterations] [prompt_file]"
    echo "Example: $0 './my-agent' 10 prompt.md"
    exit 1
fi

# Verify prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: Prompt file '$PROMPT_FILE' not found"
    exit 1
fi

echo "========================================="
echo "AI Agent Loop Script"
echo "========================================="
echo "Agent Command: $AGENT_COMMAND"
echo "Max Iterations: $MAX_ITERATIONS"
echo "Prompt File: $PROMPT_FILE"
echo "========================================="
echo ""

# Function to parse time and calculate sleep duration
calculate_sleep_duration() {
    local message="$1"

    # Extract time from message like "Limit resets at 4 pm (UTC)"
    if echo "$message" | grep -iq "Limit resets at"; then
        local time_str=$(echo "$message" | grep -oiE "[0-9]{1,2} (am|pm)" | head -1)

        if [ -z "$time_str" ]; then
            echo "Warning: Could not parse reset time from message. Defaulting to 1 hour sleep."
            echo 3600
            return
        fi

        # Parse hour and am/pm
        local hour=$(echo "$time_str" | grep -oE "[0-9]{1,2}")
        local period=$(echo "$time_str" | grep -oiE "(am|pm)" | tr '[:upper:]' '[:lower:]')

        # Convert to 24-hour format
        if [ "$period" = "pm" ] && [ "$hour" -ne 12 ]; then
            hour=$((hour + 12))
        elif [ "$period" = "am" ] && [ "$hour" -eq 12 ]; then
            hour=0
        fi

        # Get current UTC time
        local current_hour=$(date -u +%H | sed 's/^0//')
        local current_minute=$(date -u +%M | sed 's/^0//')
        local current_second=$(date -u +%S | sed 's/^0//')
        local current_seconds=$((current_hour * 3600 + current_minute * 60 + current_second))

        # Calculate target seconds (assuming reset is at top of the hour)
        local target_seconds=$((hour * 3600))

        # Calculate sleep duration
        local sleep_seconds
        if [ $target_seconds -gt $current_seconds ]; then
            # Reset is later today
            sleep_seconds=$((target_seconds - current_seconds))
        else
            # Reset is tomorrow
            sleep_seconds=$((86400 - current_seconds + target_seconds))
        fi

        # Add 60 seconds buffer to ensure we're past the reset time
        sleep_seconds=$((sleep_seconds + 60))

        echo "$sleep_seconds"
    else
        # Default to 1 hour if can't parse
        echo 3600
    fi
}

# Function to format seconds into human-readable duration
format_duration() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))

    if [ $hours -gt 0 ]; then
        echo "${hours}h ${minutes}m ${secs}s"
    elif [ $minutes -gt 0 ]; then
        echo "${minutes}m ${secs}s"
    else
        echo "${secs}s"
    fi
}

# Main loop
iteration=0

while [ $iteration -lt $MAX_ITERATIONS ]; do
    iteration=$((iteration + 1))

    echo "[Iteration $iteration/$MAX_ITERATIONS] Starting at $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "----------------------------------------"

    # Run the AI agent with the prompt
    output=$(cat "$PROMPT_FILE" | $AGENT_COMMAND 2>&1 || true)

    # Log the output
    echo "$output"
    echo ""

    # Check for completion marker
    if echo "$output" | grep -q "TASK_COMPLETE"; then
        echo "========================================="
        echo "✓ Task completed successfully!"
        echo "Total iterations: $iteration"
        echo "Finished at: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo "========================================="
        exit 0
    fi

    # Check for rate limit
    if echo "$output" | grep -iq "You've hit your limit"; then
        echo "⚠ Rate limit detected!"

        # Calculate sleep duration
        sleep_duration=$(calculate_sleep_duration "$output")
        formatted_duration=$(format_duration $sleep_duration)

        echo "Sleeping for $formatted_duration until rate limit resets..."
        echo "Will resume at: $(date -u -d "+${sleep_duration} seconds" '+%Y-%m-%d %H:%M:%S UTC')"
        echo ""

        sleep $sleep_duration

        echo "[Resumed] Rate limit should be reset. Continuing..."
        echo ""

        # Don't increment iteration counter for rate limit retries
        iteration=$((iteration - 1))
        continue
    fi

    echo "[Iteration $iteration/$MAX_ITERATIONS] Completed"
    echo ""
done

# Max iterations reached without completion
echo "========================================="
echo "⚠ Maximum iterations ($MAX_ITERATIONS) reached without completion"
echo "Finished at: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "========================================="
exit 1
