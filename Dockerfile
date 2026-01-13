FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    git \
    curl \
    ca-certificates \
    jq \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Create workspace directory
WORKDIR /workspace

# Copy the loop script and related files
COPY cheap_man_loop.sh /app/cheap_man_loop.sh
COPY agent_prompt.md /app/agent_prompt.md
COPY docker-entrypoint.sh /app/docker-entrypoint.sh

RUN chmod +x /app/cheap_man_loop.sh /app/docker-entrypoint.sh

# Environment variables (to be provided at runtime)
# GITHUB_TOKEN - Personal Access Token for git operations
# GIT_USER_NAME - Git user name for commits
# GIT_USER_EMAIL - Git user email for commits
# REPO_URL - Repository to clone (e.g., https://github.com/owner/repo)
# AGENT_COMMAND - The AI agent command (default: claude)

ENV AGENT_COMMAND="claude"
ENV MAX_ITERATIONS="10"

ENTRYPOINT ["/app/docker-entrypoint.sh"]
