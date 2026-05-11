# Xantham sandbox

Throwaway Docker environment for auditing the Xantham install wizard before letting it touch your real host.

The wizard runs hundreds of tool calls during install (file writes, shell commands, hook installs, plugin pulls). The safety gate only activates partway through. If you want cryptographic-level confidence that the install is clean before you run it on your laptop, do the first pass inside this sandbox.

## When to use this

Use the sandbox if any of the following apply:

- This is your first time installing Xantham and you want to read what the wizard actually writes before it writes it.
- You audited the blueprint files and want to confirm the wizard's behaviour matches what the Markdown says it does.
- You work in a regulated environment and need a documented trial run in an isolated environment.
- You are reviewing this project for a third party (security audit, due diligence, employer policy).
- You just prefer "try it in a VM first" as your default posture for unfamiliar agentic systems. That is a healthy default.

If you have read the blueprint, audited the install command, and trust the maintainer, you can install directly on the host. The sandbox is an option, not a requirement.

## What is in the image

Minimal Debian Bookworm with only the wizard's runtime prereqs:

- Node 18 LTS, pinned to `18.19.1-1nodesource1`
- Git, jq, sqlite3, unzip, build-essential
- Bun, pinned to `v1.3.13`
- Claude Code, pinned to `@anthropic-ai/claude-code@2.1.138`
- `tini` for clean PID 1 signal handling

No GUI, no editor, no SSH server, no preinstalled credentials, no host network beyond standard outbound egress, no host filesystem mounts unless you add them yourself.

Base image is pinned by digest (not just tag) so a future rebuild of `debian:bookworm-slim` cannot silently swap in different bytes. The three runtime binaries above are version-pinned for the same reason: a user auditing the container today and installing tomorrow gets identical bytes.

## How to bump these

Review quarterly (Jan / Apr / Jul / Oct) or sooner if upstream ships a security advisory you need.

The pins live as `ARG` directives at the top of `docker/Dockerfile.xantham-sandbox`:

```dockerfile
ARG NODE_VERSION=18.19.1-1nodesource1
ARG BUN_VERSION=bun-v1.3.13
ARG CLAUDE_CODE_VERSION=2.1.138
```

To bump:

1. **Audit the upstream release notes** for the target version. For Claude Code, read `https://github.com/anthropics/claude-code/releases`. For Bun, `https://github.com/oven-sh/bun/releases`. For NodeSource, `https://github.com/nodesource/distributions/releases`.
2. **Find the exact version string** each upstream expects:
   - NodeSource: `apt-cache madison nodejs` inside the running container shows available versions. Format is `<semver>-1nodesource1`.
   - Bun: tag names on GitHub releases (e.g. `bun-v1.3.13`). The installer takes this as its positional arg.
   - Claude Code: `npm view @anthropic-ai/claude-code versions --json` lists all published versions.
3. **Edit the three `ARG` lines** in the Dockerfile.
4. **Rebuild** with `docker build -f docker/Dockerfile.xantham-sandbox -t xantham-sandbox docker/` and confirm `claude --version`, `bun --version`, `node --version` inside the container all show the bumped versions.
5. **Commit** with a message that says what bumped to what and why.

Override at build time without editing the file:

```bash
docker build \
  --build-arg CLAUDE_CODE_VERSION=2.2.0 \
  -f docker/Dockerfile.xantham-sandbox \
  -t xantham-sandbox docker/
```

This is useful for trying a candidate version before promoting it into the committed pin.

## Build

From the repo root:

```bash
docker build -f docker/Dockerfile.xantham-sandbox -t xantham-sandbox docker/
```

First build pulls Node + Claude Code + Bun. Roughly 5 minutes on a normal connection, depending on Anthropic's CDN.

## Run

```bash
docker run --rm -it xantham-sandbox
```

`--rm` cleans up the container the moment you exit. Nothing persists across runs. That is on purpose.

Inside the container shell:

```bash
claude --dangerously-skip-permissions
```

Then paste the install prompt from the main `README.md`. The wizard will write its files inside `/workspace`, which lives only for the lifetime of the container.

## What gets persisted

By default, nothing. When the container exits, the filesystem is discarded.

If you want to keep the wizard output (so you can compare it against what would land on your host), mount a host directory:

```bash
mkdir -p ~/Documents/xantham-sandbox-output
docker run --rm -it \
  -v "$HOME/Documents/xantham-sandbox-output:/workspace" \
  xantham-sandbox
```

Read the files in `~/Documents/xantham-sandbox-output` after the wizard finishes, compare them to what the blueprint claims they will be, and only then graduate to a host install.

## What this does NOT protect against

Be honest about the limits:

- **A compromised base image.** This Dockerfile pins by digest, but a compromised registry could still serve a poisoned image for a new digest. Verify the digest against the published one in the maintainer's commit history before trusting it.
- **A compromised Claude Code binary.** The sandbox installs Claude Code from npm. If that package were compromised between two installs, you would inherit the compromise. The verify-blueprint flow only checks the Xantham files, not the entire toolchain.
- **A compromised host Docker daemon.** Container isolation is not a security boundary against a privileged host attacker. If your host is already compromised, the sandbox does not save you.
- **Network egress.** The container can still reach the public internet. If you are concerned about the install phoning home (it should not, but proving a negative is hard), drop network with `--network=none` AFTER you have pulled the blueprint files inside, or run inside an air-gapped network namespace.

## Graduating from sandbox to host install

After the sandbox install finishes:

1. Walk through `SETUP-CHECKLIST.md` inside the sandbox to confirm what the wizard reports as installed.
2. Inspect `/workspace/.claude/hooks/` and `/workspace/scripts/` to see the generated safety gate body and the scripts the wizard wrote.
3. If everything matches what the blueprint claims, exit the sandbox.
4. On your host, follow the normal install instructions from the main README. For the strongest audit posture, pin the install URLs to the commit SHA you just audited by swapping `/main/` for `/<sha>/` in the raw.githubusercontent.com URLs inside the install command. `bash scripts/verify-blueprint.sh <sha>` confirms the bytes match before you install.

The sandbox is for trust-building. The host install is the one you actually use.
