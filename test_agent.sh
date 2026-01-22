#!/bin/bash

# Test AI agent for demonstrating the cheap_man_loop.sh script
# This simulates an AI agent that:
# - Reads prompt from stdin
# - Tracks progress in a file
# - Sometimes hits rate limits
# - Eventually completes the task

PROGRESS_FILE="test_progress.txt"

# Read prompt from stdin (consume it)
prompt=$(cat)

# Initialize progress if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
    echo "0" > "$PROGRESS_FILE"
fi

# Read current progress
progress=$(cat "$PROGRESS_FILE")

echo "=== Test AI Agent ==="
echo "Received prompt (first 100 chars): ${prompt:0:100}..."
echo "Current progress: $progress/5 steps completed"

# Simulate rate limit on iteration 3
if [ "$progress" -eq 2 ]; then
    echo ""
    echo "You've hit your limit · resets 11pm (UTC)"
    exit 0
fi

# Increment progress
progress=$((progress + 1))
echo "$progress" > "$PROGRESS_FILE"

echo "Completed step $progress"
echo ""

# Check if complete
if [ "$progress" -ge 5 ]; then
    echo "All steps completed!"
    echo ""
    echo "TASK_COMPLETE"
    rm -f "$PROGRESS_FILE"  # Clean up
    exit 0
fi

echo "Continuing to next iteration..."
exit 0
