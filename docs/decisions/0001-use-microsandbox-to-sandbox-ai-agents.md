# 0001. Use microsandbox to sandbox AI CLI agents

- Status: accepted
- Date: 2026-11-14

## Context

We want to run AI CLI agents, such as Claude Code and Codex, inside a sandbox. The sandbox must meet three requirements:

- The agent can reach the internet for research.
- The agent can make API calls that need secrets.
- The agent cannot read those secrets.

The only way to meet the third requirement is to keep the real secret outside the sandbox. The agent sees a placeholder value, and a proxy on the host swaps in the real value when a request goes to an allowed host. Secrets in environment variables or mounted files don't meet it, because the agent can read them.

## Decision

We will use [microsandbox](https://github.com/superradcompany/microsandbox) (`msb`) to run the agents. Secrets are passed with `--secret`, so the guest only sees placeholders. Each secret is only substituted for the hosts on its own allowlist. Other outbound network access is open.

We chose it because:

- it needs the least setup of the options we compared;
- it is open source (Apache-2.0);
- it runs locally and doesn't depend on a vendor.

## Alternatives considered

- **Docker Sandboxes (`sbx`).** It is built to run Claude Code and Codex, and keeps the agents' own login tokens on the host. Its support for hiding custom API secrets is experimental and limited to headers. It also ties us to Docker's product, and fleet-wide policy is a paid add-on.
- **Claude Code's built-in sandbox.** It can mask credentials, but only for Bash commands. It doesn't cover file reads, web fetches, or MCP servers, and it doesn't cover Codex.
- **A container or VM with our own credential-injecting proxy.** It meets the requirements, but we would have to build and maintain the proxy.
- **Cloud sandboxes (Deno, Cloudflare, E2B).** Some inject credentials at egress. They expect us to drive the agent through their SDK rather than run the stock CLIs, and they tie us to a vendor.

## Consequences

- microsandbox is beta software and warns of breaking changes. Upgrades may break our setup, so pin the version.
- It has no ready-made setup for Claude Code or Codex. We install the agents ourselves and handle their own logins, preferably with API keys passed through `--secret`.
- Substitution covers request headers by default. APIs that sign requests with the raw key, such as AWS SigV4, can't use masked secrets.
- Hiding a secret doesn't limit what it can do. The agent can still use the credential against allowed hosts. Use narrowly scoped, revocable tokens, and keep the allowed hosts for each secret narrow.
- Open web access means injected instructions in a web page could still send workspace data out. This decision doesn't address that risk.
- Revisit if microsandbox stalls or regresses, or if Docker Sandboxes' custom secrets become stable and we accept the vendor dependency.
