# 0004. Pin general tools in a read-only global mise configuration

- Status: accepted
- Date: 2026-11-18

## Context

Agents use gh, jq, ripgrep, and python3 in every project. The image installs them as Debian packages, which lag behind upstream.

mise ([0002](0002-install-toolchains-with-mise.md)) only uses versions that are pinned, so tools every project needs must be pinned in mise's global configuration. The VM's filesystem doesn't outlive the session, so that configuration must live on the host. mise trusts the global configuration without asking, even in paranoid mode ([0003](0003-trust-project-mise-configurations-only-in-admin-mode.md)), so code in it runs in every session, including admin mode.

## Decision

We will install gh, jq, ripgrep, and python3 with mise, pinned globally, and remove them from the image. The image keeps only what it needs to start the agent and run mise: basic system utilities, curl, git, and the agent CLI.

The global configuration lives in `$AGENTBOX_DATA_DIR/mise/config`, separate from the host's. Agent sessions mount it read-only; admin mode mounts it writable, and the user adds tools there with `mise use -g`. Project pins take precedence.

## Alternatives considered

- **Keep the Debian packages.** They work without admin mode, but stay at Debian's versions.
- **Writable global configuration in agent sessions.** One session could change versions for every project, or add code that admin mode runs without asking.
- **Mounting the host's mise configuration.** Ties the sandbox to the host and exposes host files the guest doesn't need.

## Consequences

- General tools run at pinned versions, are updated in admin mode, and reach projects without their own mise configuration.
- An agent can't change what other sessions run or plant code for admin mode.
- A fresh `$AGENTBOX_DATA_DIR` has no gh, jq, ripgrep, or python3 until the user installs them.
- The tools depend on mise's sources, like the toolchains.
