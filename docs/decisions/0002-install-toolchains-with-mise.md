# 0002. Install toolchains with mise into a shared read-only directory

- Status: accepted
- Date: 2026-11-18

## Context

agentbox runs every agent from one image, `localhost/agentbox:latest`, which has only general tools. Agents working on Go, Rust, JavaScript, or other projects can't build, test, or run their code, and can't install system packages because they run without sudo.

We need:

- **Per-project versions.** The agent uses the toolchain versions the project pins.
- **Low maintenance.** Adding a language, version, or tool doesn't mean building and loading another image.

Language servers, linters, and per-language agent configuration are out of scope.

## Decision

We will install [mise](https://mise.jdx.dev) in the image and use it to provide toolchains. Its data directory is mounted from `$AGENTBOX_DATA_DIR/mise/data` and shared by all projects.

Agent sessions mount it read-only and use the versions the project pins (`mise.toml` or `.tool-versions`). A separate admin mode mounts it writable and opens a shell, not as root, where the user installs, updates, and removes toolchains. Agents don't run in admin mode.

## Alternatives considered

- **One image with every toolchain.** The image grows and rebuilds slow down, and every project gets the same version.
- **One image per language.** Multi-language repos need combined images, every base change means rebuilding and `msb load`ing each one, and versions are still fixed per image.
- **A writable data directory in every session.** No manual steps, but any session could change toolchains that other projects run.
- **The project's devcontainer or Nix definition.** devcontainers need a Docker-compatible engine and Nix is a large dependency.
- **Mounting the host's toolchains.** Ties the sandbox to the host and exposes host directories the guest doesn't need.

## Consequences

- One image covers every language mise supports. Sessions start without downloads and can't tamper with toolchains other projects use.
- Each new pinned version fails until the user installs it in admin mode.
- Projects need a mise configuration; `.nvmrc` and `.python-version` count only if mise is set to read them.
- We depend on mise's download sources and checks, and old versions pile up until removed.
- Revisit if manual installs become a burden, or if agents often need toolchains the project doesn't pin.
