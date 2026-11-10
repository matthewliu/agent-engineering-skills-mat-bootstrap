# Herdr launch and recovery

First select the installed daemon for the verified caller. For the new `hc` core, read [the core launch reference](herdr-core-launch.md) and use that path instead of the legacy commands below. The presence of the old `herdr` binary does not select it. Do not mix daemon identifiers or create workers on the old daemon for a new-core caller.

These examples were checked against Herdr CLI 0.9.5 on 2026-10-17. Check the installed help before use. Examples contain placeholders, not live targets. Never run bare `herdr` for discovery because it attaches the terminal UI.

## Verify the caller

Check inherited `HERDR_ENV`, `HERDR_PANE_ID`, `HERDR_TAB_ID`, `HERDR_WORKSPACE_ID`, and socket context without dumping the rest of the environment. Inspect these read-only commands:

```sh
herdr status
herdr session list --json
```

Use the installed Herdr UI status command when available. Read the live pane and agent metadata in the verified session. Match caller metadata or process identity to its terminal. A matching checkout path alone is insufficient when several agents share it. Do not use the focused pane to identify the caller. Never create fake environment markers.

If recovery cannot identify one caller, ask which session and pane belong to this conversation. Missing environment markers alone are not a reason to restart anything. Outside Herdr, report that this launch workflow is unavailable. Offer ordinary `feature-research`; do not replace visible multi-model workers with hidden same-model subagents.

Read `herdr --skill` for the installed control guidance. The user's explicit terminal layout, output destinations, and verified context recovery take precedence over generic defaults in that guidance. In particular, this workflow requests separate terminal tabs and durable report files from the first assignment.

## Select an explicit server

For a local named session, use the verified session on every command:

```text
herdr --session <session> <command>
```

A nonstandard socket needs the installed CLI's verified socket context as well. Do not let a session name silently redirect a socket-specific connection.

For an authorized saved remote machine, use its verified profile selector on every command:

```text
herdr --machine <saved-profile> <command>
```

Do not combine `--machine` with `--session`. Do not reuse local pane identifiers on a remote server. A failed remote call must not fall back to Local. Read remote state before retrying an uncertain mutation.

## Name the lead

Use the verified caller's pane, tab, and terminal identity. Recheck `agent get` and `tab get` before renaming. Do not rename the focused tab unless it is the verified caller's tab.

Form `<feature-slug>-<lead-model-slug>-lead` from the agreed feature and the lead's actual model identity. Use the `feature-research` model slug rules. If only the CLI name is known, use it for a provisional label. Record the unresolved model identity and update the label when the identity is known.

```text
herdr <verified-server-selector> tab rename <caller-tab-id> <feature-model-lead>
herdr <verified-server-selector> agent rename <caller-pane-id> <unique-lead-name>
```

Keep the full name in the visible tab label. Herdr 0.9.5 agent names must match `[a-z][a-z0-9_-]{0,31}` and be unique among live agents. For the agent name, replace disallowed characters with hyphens. Add a `lead-` prefix if needed to start with a letter. Shorten the feature or model part when needed. Keep the `-lead` suffix. Add a short collision suffix before `-lead` if needed. Record the full label and shortened name with the caller's identifiers.

If the tab contains other agents, keep its shared label and rename only the lead agent. Read back the changed label and name. Preserve focus and the current conversation. If naming is unsupported or fails, report the limit and continue when the research targets are verified. Never restart an agent or daemon to set a name.

## Create and start each worker

Inspect `herdr tab create --help`, `herdr agent start --help`, and the provider CLI's help. Use argument arrays when the host tool supports them. When a shell is required, quote each argument with proper shell quoting. Do not interpolate a prompt, path, model label, or source text into shell code.

```text
herdr <verified-server-selector> tab create --workspace <workspace-id> --cwd <checkout> --label <feature-worker-research> --no-focus
```

Read `.result.tab.tab_id` and `.result.root_pane.pane_id` from the returned JSON. Record the returned terminal identity from the pane metadata. Do not derive identifiers from sidebar order or a naming pattern.

Confirm that the new pane contains an interactive shell before launch:

```text
herdr <verified-server-selector> pane process-info --pane <new-pane-id>
herdr <verified-server-selector> agent start <unique-name> --kind <kind> --pane <new-pane-id> -- <verified-native-arguments>
```

Kinds commonly used here are `claude`, `codex`, `grok`, `muse`, and `agy`. Use Herdr kind `agy` for the Gemini Argon worker. Kind `gemini` launches a separate CLI and does not establish Argon access. Herdr agent names must be unique and fit its installed limit. In 0.9.5 they match `[a-z][a-z0-9_-]{0,31}`. Shorten names without losing the recorded target mapping. Display labels can keep the full feature name.

Pass model arguments only when verified by the installed CLI. An explicit requested model must not silently fall back to a default. Confirm the worker's actual runtime identity before naming its report. Prefer `codex --no-daemon` for a new Codex worker when supported. It keeps the worker's inherited Herdr context out of Codex's shared daemon. This does not authorize restarting the lead or an existing Codex daemon.

## Unattended permissions and repo trust

Use guarded permissions for new workers by default. This public library does not transfer its author's personal permission grants to a new owner. Use unattended mode only when the current owner explicitly chooses it after the lead explains its authority. Then the lead may accept the selected mode's startup confirmation for the assigned checkout. Apply this to research and review workers. Preserve that decision for the current task rather than asking again for the same grant.

Set each new pane's working directory to the exact assigned checkout. Resolve symlinks before matching a trust prompt. Trust only that checkout and any explicitly assigned worker worktree. Do not trust a home directory, filesystem root, or unrelated parent folder.

Repo trust, tool approval, and sandboxing are separate controls. The flags below apply to the child session. Some disable the provider's sandbox and permit commands outside the checkout. Folder trust and a read-only research assignment do not confine that authority. Keep the existing task limits in every brief. Do not describe prompt instructions as an OS security boundary.

### Provider arguments for explicit unattended opt-in

The following bypass arguments are not startup defaults. Keep native guarded permissions unless the current owner opted in. The table records when each provider was checked. Claude, Codex, Grok, and Muse arguments were checked on 2026-10-27. Gemini arguments were checked on 2026-11-04. Recheck the worker host's help before launch. Pass the arguments after `herdr agent start ... --`; they are provider arguments, not Herdr options.

| Worker | Native arguments | Checked CLI | Effect |
| --- | --- | --- | --- |
| Claude | `--dangerously-skip-permissions` | 2.1.312 | Bypasses tool permission checks. Folder trust or a startup confirmation can still need a response. |
| Codex | `--dangerously-bypass-approvals-and-sandbox --search` | 0.165.0 | Disables tool approvals and the provider sandbox; enables native web search. Also pass `--no-daemon` when supported. |
| Grok | `--always-approve` | 1.0.70 | Auto-approves tool calls. Deny rules and hooks still apply. Does not itself disable the sandbox. |
| Muse | `--yolo --workspace <absolute-checkout>` | 1.4.14 | Disables approvals and the provider shell sandbox, and trusts this workspace for this run. |
| Gemini through Antigravity | `--model gemini-4-argon-high --dangerously-skip-permissions` | Installed `agy --help` and `agy models`, checked 2026-11-04 | Selects Argon High and auto-approves tool permission requests. This does not establish sandbox confinement. |

Append verified model arguments without replacing these permission arguments. For unattended launches, do not substitute edit-only approval or a mode that can still ask the user for routine tool approval. If a version lacks the listed option, use an equivalent established by its installed help. If no supported equivalent exists, record the worker as blocked rather than silently launching it with manual approvals.

For example:

```text
herdr <verified-server-selector> agent start <unique-name> --kind claude --pane <new-pane-id> -- --dangerously-skip-permissions
herdr <verified-server-selector> agent start <unique-name> --kind codex --pane <new-pane-id> -- --no-daemon --dangerously-bypass-approvals-and-sandbox --search
herdr <verified-server-selector> agent start <unique-name> --kind grok --pane <new-pane-id> -- --always-approve
herdr <verified-server-selector> agent start <unique-name> --kind muse --pane <new-pane-id> -- --yolo --workspace <absolute-checkout>
herdr <verified-server-selector> agent start <unique-name> --kind agy --pane <new-pane-id> -- --model gemini-4-argon-high --dangerously-skip-permissions
```

### Gemini Argon selection and skill access

Before launch, run `agy --help` and `agy models` on the selected host. The default Gemini worker requires the exact model identifier `gemini-4-argon-high`. A model listing confirms that the service advertises the model. It does not confirm a successful model call. Confirm the model in the live worker before accepting its report. Record an authentication, quota, or model-access failure as a coverage gap. Do not replace Argon with Flash, Claude, or a configured default without the user's approval.

Launch one Gemini worker through `agy`. Do not also launch the separate `gemini` CLI as another default worker. Use `gemini` in the terminal's worker label, but record `agy` as its harness. Record the requested identifier, observed runtime identity, and any unresolved backend version separately. A paid account does not prove which model handled a turn.

Resolve the required skills on the worker host before sending its brief. If `agy` does not discover the installed skills, supply the exact readable skill paths and require the worker to read them. Do not assume it loads Claude's skill catalog. Do not copy credentials or change accounts to repair a launch.

### Complete startup without user clicks

A start timeout can mean that a startup dialog is open. It does not prove launch failure. Read the new pane before retrying. Keep the same process and terminal identity.

1. Inspect `agent get`, `pane get`, and bounded terminal output for the exact new worker. Check its machine, session, pane, terminal identity, CLI, and assigned checkout against the launch record.
2. If it asks to trust the assigned checkout, select the affirmative folder-trust option. If it asks to enter the unattended mode selected above, accept that confirmation. Read the actual options and send the required keys to that worker only.
3. Re-read the terminal after each response. Confirm the expected CLI is ready before sending the common brief. If the same prompt remains after two attempts, stop sending keys and diagnose the mismatch.
4. If an authorized source read, public research request, scratch write, or assigned report write still needs approval, read the exact request and approve it. Prefer a session-only grant when offered. Do not create a user-wide tool allow rule.
5. Record the executable version, exact launch arguments, verified checkout, startup responses, and effective mode when observable. Mark launch flags separately from runtime confirmation. Do not infer readiness from a successful key send.

Do not use a global Yes loop, send input to existing agents, or change user-wide permission defaults. A provider may save the normal folder-trust acknowledgment; do not hand-edit its config or add wildcard trust entries. Do not bypass managed policy, explicit deny rules, authentication, or account selection. Record those as specific blockers. Do not approve installs, hooks, extra integrations, unrelated file access, service changes, publication, or deployment merely because a permission dialog appears.

The lead owns authorized approval handling throughout the run. Do not leave a known folder-trust or authorized tool prompt waiting for the user while reporting the worker as running.

Provider references: [Claude permissions](https://code.claude.com/docs/en/permissions), [Codex approvals](https://learn.chatgpt.com/docs/agent-approvals-security), and [Grok permissions](https://docs.x.ai/build/features/permissions). Muse behavior here is from installed `muse --help`. The Gemini row was checked against installed help and model listings on 2026-11-04. These checks do not test a live research or review run. See [Antigravity model selection](https://antigravity.google/docs/models/) and [CLI model and permission options](https://antigravity.google/docs/cli/headless/).

## Submit and watch

Use `agent prompt` after Herdr reports the expected agent ready:

```text
herdr <verified-server-selector> agent prompt <new-agent-target> <common-prompt-with-worker-output-fields>
```

Submit work to all ready workers before waiting for completed reports. Keep waits bounded so the lead can report progress. Submission success is not proof of completion. A settled lifecycle state is not a saved report.

Use `agent get`, `pane get`, and a bounded `agent read` to investigate a blocked or stalled worker. Match the live kind and terminal identity against the recorded values before sending more input. If the occupant or server differs, stop using the old target.

Never blindly resend after `timeout`, `agent_prompt_stalled`, or a lost connection. Check whether the prompt was received and whether a report was saved. An exact authorized prompt may still need an interactive response; read the screen before sending keys. Do not approve a command merely because Herdr calls the agent idle.

If the lead loses context, recover its recorded targets with read-only commands. Do not restart the daemon or adopt another agent's pane. Preserve all terminals at handoff, including workers that failed or await a response.
