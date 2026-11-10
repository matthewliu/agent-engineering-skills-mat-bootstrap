---
name: architecture-review
description: "When reviewing a plan before /ce-work, or a large pull request, for module boundaries, data model, failure modes, migration, and simpler alternatives."
---

# Architecture review

Review a plan or a large change for shape. Do not nitpick style, and do not hunt individual vulnerabilities. Security belongs to the security-audit skill. Diff correctness belongs to `/ce-code-review`.

Use this skill before `/ce-work` on a large plan (new module, new data model, several systems). The herdr-code-review lead also runs this on a large structural change.

Read [references/checklist.md](references/checklist.md) when you need the longer lens list. The output below is the contract.

## What you are judging

- Module boundaries. Each module has one job and a small interface. UI does not talk to storage directly. A change in one module does not force edits across unrelated ones.
- Data model. Entities, ids, uniqueness, and who is allowed to write them are explicit.
- State ownership. One place owns each piece of state. You can say what survives a restart and what is derived.
- Coupling. Dependencies point toward stable interfaces. Call out cycles and shared global state.
- Failure modes and recovery. For each external dependency: what the user sees when it is down, what is retried, and what is left half-done.
- Scaling and limits. Expected volume, the hot path, and the first limit you will hit (connection pool, payload size, rate limit, queue depth).
- Migration and rollback. How existing data moves, how to stop halfway, and how to roll back without losing writes.
- Observability. How you would know the new path is broken in production (log, metric, or trace), without logging secrets.
- Simpler alternatives. A smaller design that meets the same P0 requirements. Include "do nothing" when that is honest.

## How to review

1. Read the supplied plan or diff, plus `PRODUCT.md`, the relevant `docs/work/<slug>/specs/` document or legacy CE plan, and any ADR that the change touches.
2. Name the modules and the data they own before you criticize them.
3. Flag a problem only when you can point at a file, a plan section, or a boundary. Speculative worry without a location goes under questions, not concerns.
4. Do not demand new services, interfaces, or repositories for a single-file change. Do not review markdown as if it were a running system, except when the markdown is the plan under review.
5. Prefer the simplest design that covers the confirmed P0s. Say when an abstraction is early.

## Artifact location

Save one reviewed report at `<repo-root>/docs/work/<slug>/reviews/<slug>-architecture-review.md`. Resolve the target checkout or worktree root from the reviewed plan, code, or PR. Reuse its feature folder. For a repository-wide review, use the named work scope, such as `repository-audit`. Do not use the skill library as the target.

Keep the verdict, concerns, sound areas, alternatives, and open questions in that report. Put only scratch files and raw tool output in a fresh private temporary directory. Do not deliver raw tool output or temporary paths.

Use a safe lowercase kebab-case slug. Resolve symlinks and keep the default output inside the target repo. Validate an explicit outside destination separately. It must not be temporary storage. Preserve earlier reports unless an update was requested. For a new run, use the smallest unused `-run2`, `-run3`, or later suffix. Create the file without replacing an existing one.

If the target or scope is unclear, resolve it before saving. If writing is forbidden, blocked, or unsuitable for the audience, report the blocker and ask for an explicit durable destination. Do not silently fall back to temporary storage. Keep secrets and unauthorized private details out of the report. Saving it does not authorize a commit or publication.

Run `/ce-noslop` in edit mode on the report before delivery. Apply the edits and check the facts against the review evidence. Stop if the skill is unavailable. Save the reviewed document, read it back, and deliver its actual path.

## Output

Rank concerns by impact. Impact means how badly the design fails if you ship it as written, not how elegant it is.

```markdown
## Verdict
<proceed | proceed with changes | rethink>

## Concerns
### 1. <title> (impact: high | medium | low)
- Where: <file:line or plan section>
- What goes wrong:
- Recommendation:

## Looks fine
- <area>: <why it is sound>

## Simpler alternative
<one paragraph, or "none that still meets the P0s">

## Open questions
- <question that blocks /ce-work, if any>
```

`proceed` means no high-impact concerns. `proceed with changes` means the author should apply the recommendations before `/ce-work` or before merge. `rethink` means a high-impact boundary, data model, or migration problem that makes the current shape the wrong thing to build.

"Looks fine" is required. Name at least the areas you actually checked and found sound. If you found nothing wrong, say so in the verdict and still list what you checked.

Keep recommendations concrete: merge these two modules, store this state in X, add a reversible migration step, drop this abstraction. Do not end with a generic "consider refactoring".
