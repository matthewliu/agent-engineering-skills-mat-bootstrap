# Product spec format

Path: `<repo-root>/docs/work/<slug>/specs/<slug>-product-spec.md`

This is the one output of product-spec. It starts as a requirements-only document. A later `/ce-plan <spec path>` call enriches it in place. Pass the path explicitly. Do not create a second plan or change CE configuration to discover it.

- Reuse the feature folder in the target checkout or worktree.
- Update the current interview's spec. Preserve earlier runs unless an update was requested.
- For a new run, use the smallest unused `-run2`, `-run3`, or later suffix. Create the file without replacing an existing file.
- Use only action bullets that apply. Do not invent a pending decision or verification.

```markdown
---
title: <Feature Name> - Product spec
type: feat
date: <YYYY-MM-DD>
topic: <slug>
artifact_contract: ce-unified-plan/v1
product_contract_source: product-spec
execution: code
---

# <Feature Name> - Product spec

## Executive summary

<Objective and the user outcome.>
<Key problems and confirmed constraints.>
<Recommended product path and its basis. Mark open decisions.>

- <Approved scope or product action and its purpose.>
- <Next decision or verification needed before proceeding.>

## Goal Capsule

- Objective: <the user-visible outcome, independent of implementation>
- Product authority: <pending approval, or approving user and date; what is out of active scope>
- Open blockers: <or none>

## Product Contract

### Summary

### Product Context

<Product vision, existing constraints, and facts relevant to this feature. Cite
PRODUCT.md or STRATEGY.md when present. Do not copy the full product vision here.
Keep existing product facts separate from new feature decisions. Do not update
product vision documents unless the user explicitly requested that work.>

### Problem Frame

### Requirements

**<Concern group>**
- R1. <intent> (P0)
**Look and feel**
- R7. <surface, context of use, taste, styles to avoid, build path> (P1)

### Actors / Key Flows      (A1., F1.; include when material)

### Acceptance Examples

- AE1. **Covers R1, R3.** Given ... when ... then ...

### Success Criteria

### Scope Boundaries   (out of scope, deferred P2 and deluxe items)

### Key Decisions      (resolved ambiguities, marked session-settled)

<Record important interview decisions here. Put unresolved answers in Outstanding Questions.>

| Important question | Final answer | Requirements affected | Reason and confirmation |
|--------------------|--------------|-----------------------|-------------------------|
| <question> | <confirmed answer> | <R-IDs> | <material clarification and authority> |

### Options and Trade-offs

<Matrix for real alternatives: relevant criteria, effort, risk, impact, maintenance,
confirmed choice, and its reason. Omit when no material alternatives were compared.>

### Data Flows and Integrations

<Prefer a Mermaid flowchart for relevant user and data flows. Show known internal
services, external APIs, storage, direction, exchanged data, and access boundaries.
Use existing architecture as context. Distinguish it from confirmed requirements.
Include proposed system design only for a technical feature or an explicitly
confirmed requirement. Keep other design choices for planning.>

### Data Models

<Logical entities, important fields and identifiers, relationships, ownership, access,
and sensitivity. Cite known models. Record unknowns. Do not invent physical schemas.>

### Dependencies / Assumptions   (constraints, data classes, key custody)

### Outstanding Questions

### Sources / Research (reference URLs, research report)

```

CE rules for this file:

- Repo-relative paths only.
- No status field.
- No implementation details unless the feature is itself technical.
- No "Next steps" section.
- The executive summary restates the Product Contract and Goal Capsule. Resolve conflicts in those detailed sections before updating the summary. Do not create a second decision list.
- The executive summary is required. Its action bullets describe confirmed product direction or open decisions. They do not replace engineering planning or authorize implementation.
- Record material interview decisions and source citations. Diagrams and data models must stay within known facts and confirmed requirements. Existing system facts do not commit the feature to that architecture. Mark proposed or unknown details explicitly.
- Requirement ids are stable (`R1`, `R2`). Acceptance examples cite the ids they cover.
- Priorities are P0, P1, or P2 on the requirement, matching the table the user confirmed.
- Look and feel lives here, not in `PRODUCT.md`.
- Outstanding questions are real open items only. Do not invent any.
