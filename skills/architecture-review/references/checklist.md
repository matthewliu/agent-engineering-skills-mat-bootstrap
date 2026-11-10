# Architecture lenses

Use these while reviewing. A lens that does not apply should be skipped, not forced into a finding.

## Module boundaries

- Responsibilities are blended, or there is no interface a caller can name.
- A layer reaches past its neighbor (UI reading tables, domain logic living only in a controller).
- A public interface exposes storage details or helper types callers should not see.
- Missing boundary: two rates of change are trapped in one module.

## Data model and state

- Ids, uniqueness, and cascades are implicit.
- Two writers can update the same row with no rule for conflicts.
- Derived data is stored and can drift from its source.
- A crash in the middle of a multi-step write leaves state you cannot explain.
- In-memory state is treated as durable.

## Coupling

- Import cycles, including cycles through a barrel file.
- High-level code depends on a concrete low-level client instead of a small interface you already need.
- Hidden dependencies: globals, env reads deep in a library, or a path assumed from the caller's machine.
- One config change requires edits in many packages.

## Failure, scale, migration

- No behavior defined when a dependency times out.
- Retries can duplicate a write that is not idempotent.
- A single process or lock is on the path of every request, with no stated limit.
- A migration rewrites a large table in one transaction, or has no rollback.
- Rollback would drop writes that happened after the release.

## Observability and operations

- The new path has no log, metric, or trace you could alert on.
- Logs include payloads that may contain secrets or PII.
- The design assumes an environment that is not written down.
- Components that could ship separately must be deployed together, and the plan does not say why.

## Do not flag

- A single-file script that does not need a service boundary.
- Helper functions with one caller.
- An interface extracted for one implementation that has one caller.
- Config file layout, Docker image size, or CI structure. Those are not architecture.
- Style, naming, and test mechanics, unless they hide a boundary problem.
