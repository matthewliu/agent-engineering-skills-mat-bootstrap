# Research synthesis report

Always include the executive summary. Use the deeper sections that carry findings or gaps. Do not add empty sections. Expand tables only when they make the evidence or trade-offs easier to compare. Use only action bullets that apply. Do not invent a pending decision or verification.

Keep decisions, models, diagrams, evidence, and handoff details in this one report. Do not create companion output documents.

```markdown
# Research synthesis: <Feature name> - <Authoring model label>

> Artifact: research-synthesis
> Date: <date> | Model: <label; exact model ID when available; mark user-provided labels>
> Decision: <question> | Constraints: <confirmed constraints>

## Executive summary

<Objective and the outcome the synthesis should support.>
<Key problems and the confirmed constraints.>
<The supported choice, conditional choice, rejection, or reason to withhold a winner.>
<The deciding evidence and trade-off. Separate pending user decisions.>

- <Recommended action and its purpose.>
- <Next decision or verification needed before proceeding.>

## Product decisions and requirements

| Important question | Final answer or requirement | Authority and source | Remaining qualification |
|--------------------|-----------------------------|----------------------|-------------------------|
| <question recorded in inputs> | <answer> | <confirmed, reported, proposed, or open; source> | <...> |

<Explain material clarifications and their reasons. Do not invent an interview.>

## Inputs and scope

| Input | Path | Role | Author | Report date | Scope and limitations |
|-------|------|------|--------|-------------|-----------------------|
| I1 | <path> | original research | <declared model or unknown> | <date or unknown> | <...> |

<Record local SHA-256 digests. List duplicate paths, prior syntheses used as context,
excluded candidates, unreadable documents, and gaps in discovery.>
<Use repo-relative paths. Label outside inputs without personal machine paths.>

## Claims and evidence

| Claim | Statement | Reports | Result | Verification and source | Limits |
|-------|-----------|---------|--------|-------------------------|--------|
| C1 | <qualified claim> | <I-IDs> | <supported, contradicted, or unverified> | <source link, date, version or commit and file:line> | <...> |

<Explain source dependence and any separate inferences. Do not count reports
that cite the same source as independent evidence.>

## Data flows and integrations

<Prefer a Mermaid flowchart for relevant service, storage, and external API flows.
Label exchanged data and relevant access boundaries. Distinguish current behavior,
proposals, and unknown links. Cite the evidence behind the flow.>

## Data models

| Entity | Important fields and identifiers | Relationships | Owner and access | Sensitivity | Evidence or disagreement |
|--------|----------------------------------|---------------|------------------|-------------|--------------------------|
| <entity> | <known fields> | <known links> | <...> | <...> | <citation or gap> |

## Approaches and trade-offs

| Criterion | Approach A | Approach B |
|-----------|------------|------------|
| <Relevant criterion> | <finding and C-ID> | <finding and C-ID> |

<For each serious approach: strongest supported case, benefits, costs, failure
conditions, and why it is selected, rejected, or viable under a stated condition.>
<Cover effort, risk, impact, and maintenance. Include the current approach or
doing nothing when relevant. Do not invent numeric weights or estimates.>

## Disagreements and dissent

<For each material disagreement: claims, source evidence, cause, resolution or
remaining uncertainty, and consequence for the decision. Preserve useful dissent.>

## Confidence and gaps

<Explain confidence from verification quality, source dependence, project fit,
and unresolved claims. State what was inaccessible or not tested.>
<Identify the missing evidence or user decision that could change the judgment.>

## Handoff

<The synthesis path and original report paths for product-spec or planning.>
<Pending product decisions and specific follow-up research, if needed.>
```
