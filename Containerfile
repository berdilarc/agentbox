# Image for agentbox: Debian with Claude Code installed for a non-root user.
# Build: podman build -t agentbox . && podman save localhost/agentbox:latest | msb load

FROM debian:trixie-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  ca-certificates curl jq less procps ripgrep git gh python3 \
  && rm -rf /var/lib/apt/lists/*

# UID/GID 1000 to match the usual host user, so files written to mounted
# directories keep the host owner.
RUN groupadd --gid 1000 agent \
  && useradd --uid 1000 --gid agent --create-home --shell /bin/bash agent

USER agent
WORKDIR /home/agent

ENV LANG=C.UTF-8 \
  PATH=/home/agent/.local/bin:$PATH \
  CLAUDE_CONFIG_DIR=/home/agent/.claude \
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

# Ignore scratchpad/ in every repo: agent skills write drafts there.
RUN mkdir -p .config/git .claude \
  && echo scratchpad > .config/git/ignore \
  && curl -fsSL https://claude.ai/install.sh | bash

CMD ["claude"]
