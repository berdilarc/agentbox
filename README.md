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

The image has no general tools or language toolchains; they come from [mise](https://mise.jdx.dev). Install the general tools once in [admin mode](#admin-mode):

```sh
/path/to/agentbox --admin
mise use -g gh jq ripgrep python
```

## Usage

From the project you want the agent to work on:

```sh
/path/to/agentbox claude
```

The arguments after `agentbox` are the command to run in the VM (default: `claude`). The VM gets 2 CPUs and 4 GiB of memory, and the current directory is mounted at the same path.

Tools run at the versions the project pins in `mise.toml` or `.tool-versions`, and at the global versions otherwise. Agent sessions load a project's mise configuration only after you trust it in admin mode. In agent sessions the toolchains, the global mise configuration and mise's trust record are read-only. A pinned version that isn't installed fails until you install it in admin mode.

## Admin mode

```sh
/path/to/agentbox --admin [command]    # default: bash
```

Admin mode mounts the shared mise directories writable. Run it from a project to manage what agents get:

- `mise install` installs the project's pinned versions.
- `mise use -g <tool>@<version>` adds or updates a global tool.
- `mise uninstall <tool>@<version>` removes a version. To find candidates, run `mise prune --dry-run`. Don't run `mise prune` itself: only the current project is mounted, so it treats every other project as deleted, removes the versions they use and forgets that you trusted them. For the same reason the dry run also lists versions that other projects still pin, so check before you remove one.
- `mise trust` trusts the project's configuration, so agent sessions load it. Until you do, mise reports the configuration as not trusted.

mise runs in [paranoid mode](https://mise.jdx.dev/paranoid.html), so trust is tied to the file's content. Any edit makes the configuration untrusted again. Read the change before you trust it again. Don't run agents in admin mode.

See [ADRs 0002–0004](docs/decisions/) for the reasoning.

## Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `AGENTBOX_GH_TOKEN` | unset | GitHub token, passed as a secret that only reaches `api.github.com` and `github.com`. |
| `AGENTBOX_CLAUDE_CODE_OAUTH_TOKEN` | unset | Claude Code OAuth token (from `claude setup-token`), passed as a secret that only reaches `api.anthropic.com`. |
| `AGENTBOX_SHARE_TZ` | unset | If set to any non-empty value, the VM uses the host's timezone: `$TZ` if set, otherwise the zone `/etc/localtime` links to. Otherwise the VM uses UTC. |
| `AGENTBOX_SHARE_DIRS` | unset | Space-separated names of host variables that hold directory paths, such as `TF_PLUGIN_CACHE_DIR`. Each one that is set is passed to the VM, and its directory is mounted read-only at the same path. |
| `AGENTBOX_DATA_DIR` | `~/.local/share/agentbox` | Host directory for agent state: one subdirectory per agent, plus `mise/` with the toolchains (`data`), the global mise configuration (`config`) and the trust record (`state`), and `cache/` with admin mode's cache (`admin`) and one cache per project (`projects/`). |
