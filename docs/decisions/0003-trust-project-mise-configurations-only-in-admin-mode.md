# 0003. Trust project mise configurations only in admin mode

- Status: accepted
- Date: 2026-11-18

## Context

A mise configuration can set environment variables, define hooks, and run template commands, so mise loads such a file only after the user trusts it. By default, configurations that only pin versions load without trust, and trust is tied to the directory path, so later edits stay trusted.

Agents can edit the project's configuration, which is shared with the host. An agent could add code to an already-trusted file that then runs in admin mode ([0002](0002-install-toolchains-with-mise.md)), with write access to the shared toolchains, or in the user's mise on the host.

## Decision

We will grant trust only in admin mode, and run mise in [paranoid](https://mise.jdx.dev/paranoid.html) mode in every session, which ties trust to the file's content hash.

The trust record is kept in `$AGENTBOX_DATA_DIR/mise/state`. Agent sessions mount it read-only, so they load a project configuration only if the user trusted it in admin mode.

## Alternatives considered

- **Trust by path (the default).** No re-approval after edits, but an agent's edits would stay trusted.
- **Discard the trust record after each admin session.** Nothing persists to exploit, but the user re-approves every project each time.
- **Writable trust record in agent sessions.** Agents could trust their own edits.

## Consequences

- Every project configuration needs the user's trust in admin mode before agent sessions load it.
- Any edit makes a configuration untrusted until the user approves it again.
- `mise prune` can't be used unless every tracked configuration is mounted in admin mode: prune treats unmounted projects as deleted, removing their versions and their trust.
- In agent sessions a trusted configuration can run commands in the VM, which the agent can do anyway.
