# Agent engineering skills: Matthew's bootstrap

A public starter for friends who want to build software with coding agents. Start with the [step-by-step runbook](docs/guides/build-with-agents.md). You can attach that Markdown file to a local coding agent without reading it first. The agent must explain each stage and ask for your decisions.

This repository contains reusable skills and support scripts. It excludes private research, credentials, machine settings, conversations, and the original repository's Git history. It is a curated snapshot, not an automatic mirror.

Anyone can read or clone this public repo. You cannot push to it without a separate access grant. Fork it if you want your own changes. A pull request proposes a change; only an authorized maintainer can merge it.

## Install

Ask your setup agent to inspect the installer and your existing skills first. Use your own accounts and directories. Do not install from a search advertisement or an unrelated package with the same name.

```bash
git clone https://github.com/matthewliu/agent-engineering-skills-mat-bootstrap.git
cd agent-engineering-skills-mat-bootstrap
bash scripts/install.sh --dry-run
bash scripts/install.sh
```

The installer manages Claude Code, Codex-compatible, and Cursor skill locations. It does not authenticate models, install upstream skill packs, or modify global instruction files automatically. Read the output and check each intended tool can discover the skills. Preserve existing unmanaged skills.

For optional personal defaults that run Herdr review after CE work and ask once about multi-model research:

```bash
python3 scripts/install-personal-herdr.py --check
python3 scripts/install-personal-herdr.py
```

This changes the current account's global `AGENTS.md` and `CLAUDE.md`, with backups. It does not enable Herdr for teammates. The public starter uses guarded worker permissions. Choose unattended mode only after you understand its authority. Instructions are not an enforced sandbox.

## Included skills

- `herdr-research`: fresh models research the same question; the lead verifies and synthesizes.
- `herdr-code-review`: fresh models review the same completed change; the lead verifies findings.
- `feature-research`: cited research for a decision.
- `research-synthesis`: compare existing reports and defend a recommendation.
- `product-spec`: clarify product requirements before planning.
- `architecture-review`: examine design boundaries, migrations, and failure modes.
- `security-audit`: review security findings and report coverage limits.
- `engineering-preferences`: plain English, readable PRs, scope, tests, and approval boundaries.

## Install these from their own sources

- [Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin)
- [Impeccable](https://github.com/pbakaus/impeccable)
- [Diagram Design](https://github.com/cathrynlavery/diagram-design)
- [Cloudflare security audit](https://github.com/cloudflare/security-audit-skill)
- [Herdr](https://herdr.dev/)

Follow the runbook for browser extensions, authentication, optional Tailscale and VPS setup, and deployment. Resolve the two `security-audit` skill names before installing both. Do not overwrite an existing skill silently.

## Verify changes

```bash
bash scripts/validate.sh
bash scripts/test-install.sh
python3 scripts/test-personal-herdr.py
```

Validation needs Python 3 and shellcheck. There is no compiled application build. Before the first public release, gitleaks found no credential matches in the selected files. Semgrep reported no findings but could not fully parse part of `scripts/install.sh`; shellcheck and the installer behavior tests passed. The source copy has no imported Git history. This was a focused publication check, not a full security audit. These checks do not prove a skill or dependency safe. Read `AGENTS.md` before editing. `CLAUDE.md` points to that canonical file.

## Updates and license

Save local changes before updating. Compare new releases rather than overwriting your custom rules. Install and authenticate separately on every host that runs agents. Model usage, hosting, and other services can cost money.

The original contents in this repository use the [MIT License](LICENSE). Linked tools keep their own licenses and terms. This repository does not grant access to anyone's paid accounts or private systems.
