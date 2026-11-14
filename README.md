# Agent Sandboxes

Run AI CLI agents inside a [microsandbox](https://github.com/superradcompany/microsandbox) VM. The agent works on the current directory, and secrets such as your GitHub token are swapped in by the host, so the agent never sees their real values.

## Requirements

- microsandbox (`msb`)
- Podman, to build the image

## Setup

Build the image from [`Containerfile`](Containerfile) and load it into microsandbox:

```sh
podman build -t agentbox .
podman save localhost/agentbox:latest | msb load
```

## Usage

From the project you want the agent to work on:

```sh
/path/to/agentbox claude
```

The arguments after `agentbox` are the command to run in the VM. The VM gets 2 CPUs and 4 GiB of memory, and the current directory is mounted at the same path.

## Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `AGENTBOX_GH_TOKEN` | unset | GitHub token, passed as a secret that only reaches `api.github.com` and `github.com`. |
| `AGENTBOX_CLAUDE_CODE_OAUTH_TOKEN` | unset | Claude Code OAuth token (from `claude setup-token`), passed as a secret that only reaches `api.anthropic.com`. |
| `AGENTBOX_DATA_DIR` | `~/.local/share/agentbox` | Host directory for agent state, with one subdirectory per agent. |
