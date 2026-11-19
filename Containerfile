# Image for agentbox: Debian with mise and Claude Code installed for a
# non-root user. General tools and toolchains come from mise (see
# docs/decisions/0002 and 0004), installed in agentbox admin mode.
# Build: podman build -t agentbox . && podman save localhost/agentbox:latest | msb load

FROM debian:trixie-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  ca-certificates curl less procps git tzdata xz-utils \
  && rm -rf /var/lib/apt/lists/*

# UID/GID 1000 to match the usual host user, so files written to mounted
# directories keep the host owner.
RUN groupadd --gid 1000 agent \
  && useradd --uid 1000 --gid agent --create-home --shell /bin/bash agent

USER agent
WORKDIR /home/agent

# mise shims resolve each tool's version from the current directory, so
# tools work without shell activation.
ENV LANG=C.UTF-8 \
  PATH=/home/agent/.local/share/mise/shims:/home/agent/.local/bin:$PATH \
  CLAUDE_CONFIG_DIR=/home/agent/.claude \
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

# Ignore scratchpad/ in every repo: agent skills write drafts there.
# The mise directories are mount points for agentbox's shared mise data.
RUN mkdir -p .config/git .claude .config/mise .local/share/mise .local/state/mise \
  && echo scratchpad > .config/git/ignore \
  && curl -fsSL https://mise.run | sh \
  && curl -fsSL https://claude.ai/install.sh | bash

CMD ["claude"]
