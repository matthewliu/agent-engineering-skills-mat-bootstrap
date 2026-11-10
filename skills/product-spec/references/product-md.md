# Product vision and feature scope

`PRODUCT.md` holds the broader product vision. Read it as context. Do not create, replace, or update it during product-spec or its build handoff by default. Apply the same boundary to `STRATEGY.md`.

The user can override this boundary for a specific run. An explicit request to edit or scrub the product vision authorizes those changes within the requested scope. A review-only request remains read-only. Approval of a feature spec alone does not authorize product-vision changes. Do not ask again when that authorization is already clear.

Each product-spec invocation produces one feature spec under `docs/work/<slug>/specs/`. Keep that feature's requirements, decisions, models, diagrams, and citations in the spec. Include only the product context needed to understand the feature. Cite existing vision documents instead of copying them in full.

If the feature conflicts with the product vision, record the conflict as an open decision. Ask the user to resolve it. Do not change the vision to fit the feature without authorization.

If a downstream workflow requires a missing `PRODUCT.md`, report that dependency. Creating the broader product vision is separate work unless the user explicitly included it. Do not generate it automatically from the feature spec.
