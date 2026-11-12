---
name: herdr-code-review
description: "When the user wants fresh models to review the same completed implementation in visible Herdr terminals: coordinate independent reviews, verify findings, and report or hand accepted fixes back to the implementer."
---

# Herdr code review

Keep the current agent as lead. Start fresh reviewer conversations in separate Herdr terminals after an implementation is ready for review. Give every reviewer the same code, requirements, and review question. Collect their independent findings before comparing them.

This skill replaces `cloud-agent-pr-review`. It keeps that workflow's review criteria and evidence checks. It uses visible Herdr workers and supports a local implementation before a PR exists. Read [references/review-method.md](references/review-method.md) for the common inputs, criteria, severity rules, and fix checks. Do not start a second review panel.

Use [the Herdr launch reference](../herdr-research/references/herdr-launch.md) for connection recovery, fresh terminals, explicit targets, permissions, submission, and failure handling. It also applies to review workers. Name the lead's own tab `<feature-slug>-<model-slug>-lead` when the tab contains only the lead. Name each reviewer tab `<feature-slug>-<model-slug>-review`. Use the actual model when known; otherwise use the CLI name and update the tab after confirmation. Read back the visible names before sending the review brief. Do not launch a research task through `herdr-research`.

## Automatic review after CE work

When personal global instructions require this review after `/ce-work`, the completed implementation is the review target. Start the review without asking for another instruction. Honor an explicit skip. Reuse a completed review only for the exact reviewed source state. Never start a panel from inside a reviewer. Verify accepted fixes before delivery. Use another full pass only when the changed scope or risk requires it.

This skill does not enable the default for every user. Keep that choice in personal global instructions.

## Invocation and scope

```text
/herdr-code-review <feature-slug>
Repo: <target checkout>
Target: <PR, branch diff, or current uncommitted implementation>
Requirements: <spec, plan, or original task>
Models: Claude, Codex, Grok, Muse, Gemini
```

Use the implementation context already available. Ask only when the review target, expected behavior, or authority to change code remains unclear. A standalone review request authorizes reviews and report writes. It does not authorize fixes, commits, PR changes, or publication. An existing implementation workflow can retain its already granted fix authority. State which case applies.

Running this skill after standalone `/ce-work` is supported. Keep CE's own review and run this additional review before merge. Expect more model calls and elapsed time. CE can already use cross-model reviewers, so record actual model coverage instead of assuming every Herdr worker adds a new family. Any later fixes need fresh source-state checks and relevant validation.

This skill does not satisfy a separate CE review gate by name alone. Standalone `/ce-work` requires its own review receipt or an authorized skip under its rules. An explicitly chosen outer workflow can use `/ce-work mode:return-to-caller` for implementation, then own this Herdr review and delivery. That mode is optional. Do not silently skip CE gates or change CE configuration to avoid a second review.

Default to fresh Claude, Codex, Grok, Muse, and Gemini workers when available. Use Antigravity CLI (`agy`) with `gemini-4-argon-high` for the Gemini worker. Verify that exact model with `agy models` on the worker host. Do not infer Argon access from the presence of the separate `gemini` CLI. Honor a requested roster. Record unavailable models without silent substitution. A fresh same-family worker is a separate review context, not cross-family evidence. Do not count the implementing agent's self-review as an independent review.

Do not reuse implementation agents as independent reviewers. They can explain intent or apply fixes after the independent pass. The lead can be the implementing agent, but it must identify that role. Every accepted finding needs code evidence regardless of which model raised it.

## 1. Prepare one review brief

Resolve the target repo and feature slug. Read its instructions. Use the shared review method to collect the original task, confirmed requirements, relevant design or plan, diff, changed files, and test results. Keep necessary surrounding code available. Less conversation history must not mean missing requirements or code context.

A PR target does not authorize checking out its branch into a dirty working tree. Review through an existing matching checkout, an isolated worktree, or authorized read tools. For a local diff, stay in the checkout that holds it. Include staged, unstaged, and relevant untracked implementation files. Do not stash or reset work to obtain a clean tree.

Record the reviewed base, head, and exact diff. Identify relevant uncommitted file bytes by SHA-256. Keep this source state fixed during the independent pass. Exclude only this run's generated report files from later source-state comparisons. Do not exclude an entire docs folder when documentation is part of the change.

Remove secrets and unrelated private data before submitting context to a model. Keep test results labelled as supplied evidence. Failed tests, skipped tests, and tests not run are different facts. Do not send the author's proposed verdict, self-review, or other reviewers' findings in the first-pass brief. Include factual design constraints and accepted decisions that the reviewers need.

Use [references/reviewer-prompt.md](references/reviewer-prompt.md). Every worker gets the same complete review question, requirements, source state, and scope. Only its identity and output fields differ. No worker is assigned only security, tests, or another slice of the code.

Give every worker the review criteria from [references/review-method.md](references/review-method.md). Do not invoke `/ce-code-review` separately in every worker. That skill can dispatch its own panel and would multiply this review team. A project-required CE review remains a separate check; report whether it ran.

## 2. Launch fresh, independent reviewers

Check the Herdr connection and actual installed models through the shared launch reference. Create one new terminal tab per reviewer. Preserve existing work, agents, and focus. Record each machine, session, tab, pane, terminal identity, CLI, and actual runtime model.

Use guarded provider permissions by default. Use the shared launch reference's unattended arguments only after the current owner explicitly chooses that mode. The lead can accept trust for the assigned checkout and handle already authorized tool prompts. Unattended modes can permit writes beyond the report; the reviewer's implementation-read-only assignment still applies.

Prepare the full team, then send the common brief to all ready workers. Do not wait for one full review before starting the next. Never reuse an implementer's live conversation with a request to forget its history.

Reviewers can read the authorized code and write their assigned reports. They must not edit implementation, install software, change services, run repo hooks, or control other agents. They must not execute candidate code or test commands by default. If validation needs code execution, give a test proposal to the lead. The lead runs it only within existing authorization and repo trust.

Reviewers do not read each other's current reports or the lead's findings before submitting. Shared filesystem access is not strict isolation. Record any accidental exposure and do not count the exposed result as independent corroboration. Do not demand a finding quota. A clean review is valid.

Resolve a material clarification once and send it to every reviewer in the same words. Source changes during review invalidate affected findings and the shared source-state claim. Keep the old results as a named review round. Give all included reviewers the changed code before declaring the new state reviewed.

## 3. Save and verify the independent reviews

Each worker saves a reviewed Markdown report at:

`<output-root>/docs/work/<feature-slug>/reviews/<feature-slug>-code-review-<actual-model-slug>.md`

Use actual model identity and slug rules from `feature-research`. Resolve the worker's output root before launch. Its report identifies the exact reviewed source state, scope, findings, and review limits. Each finding names severity, file and line, trigger, consequence, evidence, and a proposed fix or check. Keep uncertain risks separate from confirmed defects. State when there are no actionable findings.

Run `/ce-noslop` in edit mode before accepting or delivering a report. Apply its edits and recheck the code references and claims. Stop delivery if it is unavailable. Preserve earlier reports with the next unused run suffix. Use exclusive creation. Never replace an earlier report or follow a final-file symlink.

The worker returns its actual model identity, path, SHA-256 digest, review status, and coverage gaps. The lead verifies the durable real path, filename, bytes, source state, and contents. It reads the saved report. A terminal summary or temporary draft is not a completed review. Follow the research skill's durable storage boundaries. If workers used separate output worktrees, collect byte-identical originals into the agreed report worktree with exclusive writes and checked digests.

## 4. Judge findings and hand off fixes

After the independent reports are complete, apply the shared review method's evidence checks and finding triage. Combine duplicate findings while preserving which reviewers raised them. Accept, reject with a reason, or mark each material finding unresolved. Verify file references, attack prerequisites, and claimed consequences yourself. A majority vote does not establish a bug. One verified finding can block the change.

Distinguish a required correction from a preferred rewrite. Check regressions and missed acceptance criteria against confirmed requirements. Do not approve an implementation because the author explains why it seems correct. Do not reject it merely because a reviewer prefers another design.

Give a verdict for the exact reviewed state: ready for the next project gate, needs fixes, or incomplete review. Name any missing test, model, access, or evidence that limits that verdict. Passing this review does not prove safety or authorize merge or deployment.

When fixes are authorized, send accepted findings to the implementing agent with evidence and acceptance checks. If the lead is the implementer, it can apply those authorized fixes after triage. If another implementing agent is unavailable, tell the user before assigning implementation to a replacement. Keep reviewers read-only. Do not ask reviewers to compete on fixes during their independent pass.

After fixes, record the new source state. Check the corrected behavior and the relevant regression risk. Ask the same reviewers for a clearly labelled follow-up when useful. A material new change can require a new full independent pass. Do not reuse the old verdict for new code or describe informed follow-ups as blind first-pass reviews.

Apply PR handoff steps only within the user's granted authority. Do not post forge comments or change a PR body from a standalone report-only review. Never merge.

## 5. Deliver one lead report

Save the consolidated report at:

`<output-root>/docs/work/<feature-slug>/reviews/<feature-slug>-code-review.md`

Use the same durable storage, exclusive creation, run suffix, prose review, and read-back checks as the worker reports. Start with an executive summary: reviewed change, verdict, key problems, recommended action, and action bullets. Include the reviewed revision or diff identity, worker coverage, accepted and rejected findings, unresolved risks, test evidence, and any fix verification. Link the independent originals. Keep the implementing lead's role explicit.

Deliver the verdict, material findings, test and coverage limits, report paths, and any authorized fixes made. Leave terminals, reports, worktrees, and branches available. A failed reviewer is a coverage gap, not a clean review. Do not install software or publish, commit, merge, or deploy as a side effect of this skill.
