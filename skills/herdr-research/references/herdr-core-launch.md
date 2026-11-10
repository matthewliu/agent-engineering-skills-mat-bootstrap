# Launch with the new Herdr core

This path applies to `hc`, not the legacy `herdr` daemon. Commands were checked against core 0.1.19 and desktop 0.1.14 on 2026-11-10. Read installed help before use. This check did not launch a model panel.

## Verify the caller and machine

Read `hc --skill` and `hc run --help`. Inspect `HC_TERMINAL_ID` without dumping the environment. Use `hc get <caller>`, `hc ls`, and `hc machine ls`. When the desktop is available, read `herdr-app --skill` and `herdr-app ls`. Match the caller's process and terminal metadata. A shared checkout or the focused tab is not enough. Ask if the caller remains ambiguous. Do not invent environment variables or restart services.

Record the caller address, process identity, machine, and `herdr.space` label. A remote address has the form `machine/t7`. Use the full returned address for later commands. Never fall back to Local after a remote error. A headless lead can create core terminals without a desktop. If visible placement cannot be verified, report that limit.

## Name the lead

Form `<feature-slug>-<actual-model-slug>-lead`. Find its exact tab through `herdr-app ls` and the verified caller terminal. For a tab with only that agent, use `herdr-app do tab.rename --id <tab-id> --name <full-label>`. Keep a shared tab's label. Use `hc label <caller-address> task=<full-label> role=lead` to record the role without replacing its process. Core 0.1.19 does not expose a terminal rename command. Do not invent one. If the UI is unavailable, retain the role label and report the naming limit.

## Prepare fresh workers

Read the provider arguments, repo trust, and Gemini selection sections in [the shared reference](herdr-launch.md). Those task and permission limits still apply. Recheck the provider help on the selected host. Use Antigravity `agy`, not the separate `gemini` CLI, for the default Gemini worker. Codex must use `--no-daemon`. Do not change existing agents or enable unreviewed repo hooks.

Use one interactive core terminal per worker. Do not use print-only provider modes. Keep workers after the lead ends with `--outlive-parent`. Set the exact checkout and a unique name. Core names allow 1-32 characters from `a-z`, `0-9`, `-`, and `_`. Record the full display label separately when it needs shortening.

When the verified workspace exists in the open desktop, pass `--label herdr.space=<space-id>`. Omit `herdr.tab` so the app creates a separate tab. Without the space label a core worker can remain hidden. Check placement with `herdr-app ls`. Do not use the focused space as a fallback.

The examples below include bypass flags. Use them only after the current owner explicitly opts into unattended mode. For guarded launches, omit those bypass flags and keep `--no-daemon` for Codex. Example argument shape, with placeholders:

```text
hc run --bg --outlive-parent --cwd <checkout> --name <unique-name> --label herdr.space=<verified-space-id> codex --no-daemon --dangerously-bypass-approvals-and-sandbox --search
hc run --bg --outlive-parent --on <verified-machine> --cwd <remote-checkout> --name <unique-name> --label herdr.space=<verified-remote-space-id> claude --dangerously-skip-permissions
```

Use argument arrays through the tool API. Quote each argument if a shell is necessary. Do not insert the research prompt into shell code. Do not create a new SSH connection, workspace, or machine profile without authority. A core on a VPS does not require a desktop there.

Create the team before sending the shared brief. After each launch, record the returned address, creation time, launch arguments, working directory, and foreground identity from `hc get`. Read the exact worker screen with `hc read --lines 0 <address>`. A successful launch reply alone does not prove readiness.

Handle the assigned checkout's trust prompt and the authorized unattended startup confirmation as described in the shared reference. Use `hc keys <address> <keys...>` only after matching the actual prompt to that worker. Do not use a global Yes loop, approve hooks, or bypass an unrelated permission decision. Stop after two unsuccessful responses and diagnose. Authentication or managed-policy blocks remain blocks.

## Send and collect

After the CLI is ready, use `hc send <address> <common-brief>`. Recheck `hc get` against the launch record before every later input. Stop if the terminal finished, changed program, or became a recovery shell. Do not send a model prompt to a shell. Inspect state after ambiguous delivery instead of blindly resending.

Send the same complete brief to every ready worker. Each worker writes its own durable report and does not launch more agents. Ask it to return its actual model identity, report path, digest, and limits. Where permitted, it can notify the verified lead with `hc send <lead-address> <short-result>`.

Use bounded `hc wait --timeout 45 <address>` calls while other workers run. Use `hc get` and bounded `hc read` for blockers. Do not infer completion from an idle screen or a notification. Read and verify each saved report under the parent skill's rules.

Preserve the user's existing focus. Creating visible worker tabs can affect focus; restore the previously verified terminal through `herdr-app do agent.focus --terminal <address>` when supported. Keep worker terminals and reports for follow-up. Do not use core cleanup advice to close them automatically during this workflow.
