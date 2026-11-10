# Feature research report

Always include the executive summary. Include the deeper sections that carry findings or gaps. Keep the report proportional to the decision. Use only action bullets that apply. Do not invent a pending decision or verification.

Keep decisions, models, diagrams, evidence, and handoff details in this one report. Do not create companion output documents.

```markdown
# Research: <Feature name> - <Authoring model label>

> <date> · Model: <model label; exact model ID when available; mark user-provided labels> · Depth: <Quick|Standard|Deep> · Constraints: <...>

## Executive summary

<Objective and the outcome the research should support.>
<Key problems and the constraints that affect the decision.>
<Recommended path and the evidence that decides it. State conditions or a missing decision.>

- <Recommended action and its purpose.>
- <Next decision or verification needed before proceeding.>

## Interview decisions and requirements

| Important question | Final answer or requirement | Status and source | Reason for the decision |
|--------------------|-----------------------------|-------------------|-------------------------|
| <question> | <final answer> | <user-confirmed, proposed, or open; source> | <reason or material clarification> |

## Research questions

1. **<question>**: <answer> (Confidence: High|Medium|Low)

## Internal codebase findings

### Existing patterns

### Integration points

### Constraints

| File | Relevance |
|------|-----------|

## Data flows and integrations

<Prefer a Mermaid flowchart for relevant service, storage, and external API flows.
Label arrows with the data exchanged. Distinguish current and proposed behavior.
Name relevant access boundaries and cite evidence. Mark unknown links.>

## Data models

| Entity | Important fields and identifiers | Relationships | Owner and access | Sensitivity | Evidence or open question |
|--------|----------------------------------|---------------|------------------|-------------|---------------------------|
| <entity> | <known fields> | <known links> | <...> | <...> | <citation or gap> |

## External research

### Sources

- [<title>](<url>), <published/updated date>: <key finding>
- <url>: "Could not access: <reason>"

### Key findings

### Comparisons

| Criterion | Option A | Option B | Option C |
|-----------|----------|----------|----------|

## Options and trade-offs

### Option 1: <name> (Recommended)

- Effort / Risk / Impact / Maintenance: ...
- Constraint fit: <how it meets the stated constraints>
- Why recommended: ...

### Option 2: <name>

### Option 3: Do nothing (when that is the right call)

## Confidence

- High: 2+ independent primary sources agree, dated within 12 months.
- Medium: one primary source, or older or indirect evidence.
- Low: secondary or social sources only, or inferred.
<List the claims the recommendation rests on, each with its level and basis.>

## Dated findings

<Claims older than about 12 months, deprecated or renamed APIs, prices or limits likely to change, sources contradicted by newer ones, and anything stale in the user's own code or docs.>

## Open questions

- [ ] <question>: what would resolve it
<Include access failures, conflicting sources you could not settle, and anything the lanes did not cover.>

## Follow-up detail

<Expand only the actions that need detail beyond the executive summary.>
```
