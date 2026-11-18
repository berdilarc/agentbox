# 0005. Persist a per-project cache

- Status: accepted
- Date: 2026-11-18

## Context

The VM's filesystem doesn't outlive the session, so `~/.cache` is empty at the start of every session. Tools that cache there, such as pip, uv and the Go build cache, download and build the same things again each time.

A cache shared by all projects would be writable by every agent session. An agent could put poisoned artifacts there, and sessions for other projects would then use them. This is the cross-project risk that the earlier decisions avoid for the toolchains ([0002](0002-install-toolchains-with-mise.md)), the global mise configuration ([0004](0004-pin-general-tools-in-a-read-only-global-mise-configuration.md)) and the trust record ([0003](0003-trust-project-mise-configurations-only-in-admin-mode.md)).

## Decision

In agent sessions, we will mount a writable host directory at `/home/agent/.cache`, with one directory per project in `$AGENTBOX_DATA_DIR/cache/projects/`. Each is named after the project's host path, with characters other than `A-Za-z0-9._-` replaced by `-`, plus the first 8 hex characters of the path's SHA-256, such as `home-user-src-myproject-63e9dfde`. The name shows which project a cache belongs to, and the hash keeps paths with the same name, such as `/a/b-c` and `/a/b/c`, apart.

Admin mode gets its own cache in `$AGENTBOX_DATA_DIR/cache/admin`, shared by all projects and never mounted in agent sessions. If admin mode used a project's cache, an agent could plant downloads in `~/.cache/mise` that the next admin `mise install` puts into the shared toolchains.

The scope is the XDG cache only. Tool directories outside `~/.cache`, such as `~/go/pkg/mod`, `~/.cargo/registry` and `~/.npm`, are not covered.

## Alternatives considered

- **No persistent cache (the current setup).** Nothing persists between sessions, but every session downloads and builds again.
- **One cache shared by all projects.** The most reuse, but any session could poison what other projects use.
- **Also redirect tool-specific caches (`GOMODCACHE`, `CARGO_HOME`, npm) into it.** More reuse, but it's not yet clear which tools matter. Left for later.
- **No persistent cache in admin mode.** Nothing to poison, but every admin session downloads again.

## Consequences

- Later agent sessions in the same project reuse what tools cached under `~/.cache`.
- An agent can poison its own project's cache for later sessions of that project. Unlike edits to the project, this isn't visible in git and survives reverting them; the user clears it by deleting the project's cache directory. The cache is only used inside the VM, never on the host.
- Admin sessions reuse downloads across projects. Anything run in admin mode can write to that cache, so admin mode's rule still holds: don't run agents there.
- Disk use grows with each project, and projects keep their own copies of the same artifacts. Nothing removes stale caches; the user deletes them by hand.
- Moving or renaming a project starts a fresh cache, and the old one stays until deleted.
- Tools that don't use `~/.cache` still download again.
- Revisit if disk use becomes a problem, or if tool-specific caches turn out to matter.
