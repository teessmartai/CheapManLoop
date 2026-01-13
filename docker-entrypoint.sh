#!/bin/bash
set -euo pipefail

# docker-entrypoint.sh
# Handles git setup, repo cloning, and running the cheap_man_loop

#######################################
# Configuration from environment
#######################################
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GIT_USER_NAME="${GIT_USER_NAME:-AI Agent}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-agent@example.com}"
REPO_URL="${REPO_URL:-}"
BRANCH="${BRANCH:-}"
AGENT_COMMAND="${AGENT_COMMAND:-claude}"
MAX_ITERATIONS="${MAX_ITERATIONS:-10}"

# Arguments
USER_PROMPT="${1:-}"
COMPLETION_CRITERIA="${2:-}"

#######################################
# Usage
#######################################
usage() {
    cat <<EOF
Usage: docker run cheap_man_loop '<user_prompt>' '<completion_criteria>'

Required environment variables:
  GITHUB_TOKEN      GitHub Personal Access Token (with repo scope)
  REPO_URL          Repository URL (e.g., https://github.com/owner/repo)

Optional environment variables:
  GIT_USER_NAME     Git user name for commits (default: AI Agent)
  GIT_USER_EMAIL    Git user email for commits (default: agent@example.com)
  BRANCH            Branch to create/checkout (default: ai-agent-changes)
  AGENT_COMMAND     AI agent command (default: claude)
  MAX_ITERATIONS    Maximum loop iterations (default: 10)

Example:
  docker run -e GITHUB_TOKEN=ghp_xxx -e REPO_URL=https://github.com/owner/repo \\
    cheap_man_loop 'Fix the login bug in auth.py' 'All tests pass and PR is created'
EOF
    exit 1
}

#######################################
# Validation
#######################################
if [ -z "$USER_PROMPT" ] || [ -z "$COMPLETION_CRITERIA" ]; then
    echo "Error: Missing required arguments"
    usage
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is required"
    usage
fi

if [ -z "$REPO_URL" ]; then
    echo "Error: REPO_URL environment variable is required"
    usage
fi

#######################################
# Git Setup
#######################################
echo "Setting up git credentials..."

# Configure git
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
git config --global init.defaultBranch main

# Set up credential helper to use the token
# This allows git to authenticate using the GITHUB_TOKEN
git config --global credential.helper store

# Convert HTTPS URL to include token for authentication
# Supports both github.com and other git hosts
if [[ "$REPO_URL" =~ ^https://([^/]+)/(.+)$ ]]; then
    GIT_HOST="${BASH_REMATCH[1]}"
    REPO_PATH="${BASH_REMATCH[2]}"
    AUTH_REPO_URL="https://x-access-token:${GITHUB_TOKEN}@${GIT_HOST}/${REPO_PATH}"
else
    echo "Error: REPO_URL must be an HTTPS URL (e.g., https://github.com/owner/repo)"
    exit 1
fi

# Configure gh CLI
echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null || true

#######################################
# Clone Repository
#######################################
echo "Cloning repository: $REPO_URL"

# Extract repo name from URL
REPO_NAME=$(basename "$REPO_URL" .git)
WORK_DIR="/workspace/$REPO_NAME"

# Clone the repo
git clone "$AUTH_REPO_URL" "$WORK_DIR"
cd "$WORK_DIR"

# Set up branch
if [ -n "$BRANCH" ]; then
    echo "Creating/checking out branch: $BRANCH"
    git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
else
    # Generate a unique branch name
    BRANCH="ai-agent-$(date +%Y%m%d-%H%M%S)"
    echo "Creating branch: $BRANCH"
    git checkout -b "$BRANCH"
fi

# Store the remote URL with auth for pushing
git remote set-url origin "$AUTH_REPO_URL"

#######################################
# Prepare Enhanced Completion Criteria
#######################################
# Append git/PR instructions to the completion criteria
ENHANCED_CRITERIA=$(cat <<EOF
$COMPLETION_CRITERIA

Additionally, you must:
- Commit all changes with descriptive commit messages
- Push commits to the remote branch '$BRANCH'
- Create a pull request using: gh pr create --title "<descriptive title>" --body "<description of changes>"
- The PR should be created against the default branch
EOF
)

#######################################
# Run the Agent Loop
#######################################
echo "========================================="
echo "Starting AI Agent Loop"
echo "========================================="
echo "Repository: $REPO_URL"
echo "Branch: $BRANCH"
echo "Working directory: $WORK_DIR"
echo "========================================="

# Run the cheap_man_loop
/app/cheap_man_loop.sh "$AGENT_COMMAND" "$USER_PROMPT" "$ENHANCED_CRITERIA" "$MAX_ITERATIONS" "/app/agent_prompt.md"

exit_code=$?

echo "========================================="
echo "Agent loop finished with exit code: $exit_code"
echo "========================================="

exit $exit_code
