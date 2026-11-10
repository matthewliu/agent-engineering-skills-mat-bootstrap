# Agent engineering bootstrap skills

This is a public starter library of reusable agent skills and a beginner runbook. It is not an application or a copy of a personal machine configuration.

## Commands

- Build: none. The skills are Markdown and the helpers are Python and shell scripts.
- Validate and lint: `bash scripts/validate.sh`.
- Installer tests: `bash scripts/test-install.sh`.
- Personal instruction tests: `python3 scripts/test-personal-herdr.py`.

## Directories

- `skills/`: one `SKILL.md` per skill, with optional references.
- `scripts/`: installation and validation helpers.
- `rules/`: generated engineering preferences.
- `docs/guides/`: the beginner setup and development runbook.

## Maintenance

Use plain English and ASD-STE100-style short sentences. Run `/ce-noslop` in edit mode on documentation before delivery. Keep exact commands and facts.

Work on a branch and open a PR. Do not merge or deploy without the owner's approval. Never commit credentials, personal transcripts, or local state.

`skills/engineering-preferences/SKILL.md` is canonical. Do not hand-edit the generated rule. `scripts/install.sh` regenerates it.

Keep personal identities and permission grants out of the shared defaults. Guarded permissions are the public starter default because a new recipient has not authorized bypass mode.

Install third-party packs from their own sources. Do not copy Compound Engineering, Impeccable, Diagram Design, or Cloudflare's skill into this library.
