#!/bin/bash

# Test AI agent for demonstrating the ai_agent_loop.sh script
# This simulates an AI agent that:
# - Tracks progress in a file
# - Sometimes hits rate limits
# - Eventually completes the task

PROGRESS_FILE="test_progress.txt"

# Initialize progress if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
    echo "0" > "$PROGRESS_FILE"
fi

# Read current progress
progress=$(cat "$PROGRESS_FILE")

echo "=== Test AI Agent ==="
echo "Current progress: $progress/5 steps completed"

# Simulate rate limit on iteration 3
if [ "$progress" -eq 2 ]; then
    echo ""
    echo "You've hit your limit. Limit resets at 11 pm (UTC)"
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
