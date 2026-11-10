## Personal Herdr workflow defaults

These defaults apply to this user account. Do not copy them into shared project instructions or require teammates to use Herdr.

After `/ce-work` completes an implementation and its required local checks, run `/herdr-code-review` without asking for another review request. Run it before publication, merge, or deployment when the calling workflow permits those actions. Use fresh Claude, Codex, Grok, Muse, and Gemini reviewers when available. Use Antigravity (`agy`) for Gemini. Give every reviewer the same complete change and requirements. The lead verifies findings and decides which fixes are required.

Keep CE's required checks. For a workflow that must review before publication, use CE's supported `mode:return-to-caller` and let the caller own the Herdr review and remaining delivery steps. Do not edit the stock CE skills. Do not treat this review as merge or deployment permission.

Honor an explicit request to skip cross-model review. Do not start another panel if the exact source state already has a completed Herdr review. Reviewers must not start panels. Accepted review fixes get focused verification. A material new change can require another full review. Record the final reviewed source state, coverage, and unresolved findings.

When the user requests research, ask once whether to use `/herdr-research` for independent work by multiple models or research inline with one agent. Ask before launching research workers. Do not ask again if the user already chose, invoked `/herdr-research`, or explicitly requested multiple models. Do not treat quoted text, a status question, or a mention of prior research as a new research request. Herdr workers receive the same full question. The lead compares evidence and makes a decision. It must not split the question among workers or average conflicting answers.

Before selecting a workflow, check the installed Herdr connection. With the new core, read `hc --skill`, check `HC_TERMINAL_ID`, and inspect `hc get`, `hc ls`, and `hc machine ls`. Use `herdr-app ls` when the desktop app is available. With the legacy daemon, use `herdr status` and `herdr session list --json`. Verify the caller and machine. Missing environment variables do not prove that Herdr is unavailable. Never guess from the focused tab or restart a daemon to recover context.

Use the shared launch reference in `herdr-research` for fresh visible terminals and permission handling. Launch Codex with `--no-daemon` under the new core. Preserve current agents and work. Do not install missing CLIs, change accounts, or silently substitute models. Report unavailable providers. If Herdr cannot run the review, report that the review is incomplete before shipping. If research cannot use Herdr, offer inline research.
