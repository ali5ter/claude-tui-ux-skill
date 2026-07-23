---
name: tui-ux-tester
description: Expert UX evaluator for terminal user interfaces (TUIs) — full-screen interactive terminal apps built with frameworks like Bubble Tea, Textual, or Ratatui. Use when reviewing TUI usability, keybindings, layout, color/theming, or terminal app onboarding; when evaluating a recording (asciinema cast, video, or GIF) of a TUI; or when asked to research new TUI patterns or update the TUI pattern library.
version: 1.1.2
allowed-tools: Read, Write, Bash, WebSearch, AskUserQuestion, Agent
---

# TUI UX Tester

This skill evaluates the usability of terminal user interfaces — full-screen, interactive terminal apps (as
opposed to one-shot CLIs). It identifies the target TUI, gathers visual evidence of it actually running, asks
clarifying questions if needed, runs evaluation agents in parallel, then passes the collected results to a
synthesizer agent to produce a scored report and artifacts.

**Why visual evidence matters:** a TUI's usability lives in its rendered screen — layout, color, spacing,
motion — not in `--help` text. Unlike a CLI, you cannot evaluate a TUI by reading captured stdout alone. This
skill's defining step is producing or obtaining a real recording of the TUI running before scoring it.

**Architecture:** the skill spawns all evaluation sub-agents directly (an Explore agent and an interaction-probe
agent, in parallel) — sub-agents cannot spawn further sub-agents. The `tui-ux-tester:tui-ux-tester` agent acts as
a synthesizer: it receives pre-collected evidence (recording/frames, codebase map, interaction probe results) and
produces the scored report.

## Step 1: Detect the target TUI

**From the user's message:** if a specific command or repo is named (e.g., "review my-tool's TUI"), use that.

**From the current directory:**

```bash
# Go: Bubble Tea / tcell / termbox entry points
grep -l "bubbletea\|tcell\|termbox\|gocui" go.mod 2>/dev/null
ls main.go cmd/ 2>/dev/null

# Python: Textual / urwid / curses
grep -l "textual\|urwid\|py_cui\|npyscreen" pyproject.toml requirements.txt setup.py 2>/dev/null

# Rust: Ratatui / cursive
grep -l "ratatui\|tui-rs\|cursive" Cargo.toml 2>/dev/null

# Node: blessed / ink / neo-blessed
grep -l "blessed\|\"ink\"\|neo-blessed" package.json 2>/dev/null

# README often documents the binary name and any existing demo asset
head -60 README.md 2>/dev/null
```

Note the entry point (binary name, `go run .`, `python -m pkg`, etc.) and whether the app requires
authentication/network access to reach its main screen — this affects Step 2.

## Step 2: Gather visual evidence

Do this before spawning evaluation agents. Priority order — stop at the first that succeeds:

**a. Existing recording in the repo.** Glob for `**/*.tape` (VHS scripts), `**/*.cast` (asciinema), and
`examples/**/*demo*.{gif,mp4,webm}` or similar. Many TUI READMEs already ship one (e.g., a VHS-generated demo
GIF). If found:

- A `.tape` file is best: re-run it (`vhs the.tape -o /tmp/tui-ux-evidence/demo.mp4`) to get a fresh, reproducible
  recording against the current build.
- A `.gif`/`.mp4`/`.webm` with no tape source is still usable directly.
- A `.cast` file is directly readable as text (asciicast v2/v3 is newline-delimited JSON) — no extraction needed.

**b. Record a fresh session** if VHS or (tmux + asciinema) is available (`which vhs`, `which tmux asciinema`):

- Prefer VHS if the project already has a `.tape` file or the `examples/` convention (VHS is standard in the
  Charm/Bubble Tea ecosystem) — see `scripts/record-vhs.sh`.
- Otherwise drive the TUI inside a detached tmux session while asciinema records it — see
  `scripts/record-asciinema.sh`. This also works for non-Charm TUIs (Textual, Ratatui, blessed, raw curses).
- Script a walkthrough covering: first launch, each major view/tab, one destructive or confirmation action if
  present, the help overlay (`?` or `F1`) if present, and quit. Skip any step requiring real credentials or
  network calls the evaluator doesn't have — use `--offline`, `--demo`, or mock/fixture data if the project
  provides it; note in the report if a flow couldn't be exercised.
- Convert the result to still frames for visual review: `ffmpeg -i demo.mp4 -vf "fps=1" frames/frame_%03d.png`
  (or `agg demo.cast demo.gif` first, then extract frames from the GIF).

**c. No recording tooling available**, or the app cannot be driven headlessly (needs a real TTY interaction the
skill can't script, e.g. OAuth device flow): ask the user with `AskUserQuestion`:

```text
Question: "I can't produce a recording of this TUI automatically. How should I evaluate its visuals?"
Options:
  - I'll provide a video or GIF (share a file path)
  - I'll provide an asciinema .cast file (share a file path)
  - Record a short asciinema session yourself now, then tell me when it's saved
  - Skip visual evidence — evaluate from source code and a live tmux capture-pane walkthrough only
```

If the user provides a path, use it directly (extract frames from video/GIF with ffmpeg; read `.cast` files as
text). If they choose to skip, proceed but flag every criterion touching color/layout/motion as **reduced
confidence** in the final report — say so plainly, don't fake certainty.

**d. Always also do a plain-text probe**, regardless of whether a/b/c produced footage: use
`scripts/tmux-probe.sh` to drive the TUI in a detached tmux session and `tmux capture-pane` snapshots at each
step (no recording dependency required, just tmux). This is fast, cheap, and catches structural issues
(crashes, resize behavior, focus state) a single linear recording can miss.

Collect the artifact paths (recording, frame PNGs or `.cast` path, tmux-probe transcript) — pass all of them to
the synthesizer in Step 5.

## Step 3: Ask clarifying questions if still needed

Skip if the target and entry point were already resolved in Step 1.

```text
Question: "Which TUI should I evaluate?"
Options:
  - [Each detected entry point]
  - A different installed command (provide the name)
  - A different path (provide the path)
```

## Step 4: Run evaluation agents in parallel

Locate reference files first (Glob): `pattern-library.md`, `testing-checklist.md`, `test-scenarios.md`.

**Explore agent** — codebase mapping:

```text
subagent_type: Explore
prompt: "Map the {tui_command} TUI codebase in {working_dir}. Find: the framework in use (Bubble Tea, Textual,
Ratatui, blessed, raw curses/tcell, etc.), all views/tabs/screens and how focus moves between them, the full
keybinding map and where it's defined, color/theme definitions (including NO_COLOR / adaptive light-dark /
truecolor-fallback handling if any), help text or help overlay implementation, loading/progress/error state
handling, confirmation prompts for destructive actions, resize handling, and any non-interactive/pipeline mode
(--json, --no-tty, etc.) that coexists with the TUI. Return a structured summary with file:line references."
```

**Interaction probe agent** — live behavior testing:

```text
subagent_type: general-purpose
prompt: "Drive {tui_command} (from {working_dir}) inside a detached tmux session using
scripts/tmux-probe.sh as a template, and capture-pane snapshots at each step. Test: help key (? or F1) if
present, quitting (q and Ctrl+C), an invalid/empty-state view if reachable, resizing the tmux pane to 80x24 and
to something very small (e.g. 40x10) and capturing what happens, and NO_COLOR=1 / TERM=dumb behavior if
practical. Capture exact pane output at each step. Note: what works, what breaks, what's illegible or clipped."
```

Wait for both agents (and Step 2's recording work) to complete before proceeding.

## Step 5: Launch synthesizer agent

Launch `tui-ux-tester:tui-ux-tester`. Pass:

- The working directory and the TUI entry point (command, `go run .`, etc.)
- Any user focus areas from their message
- Visual evidence: recording path, extracted frame PNG paths (or a note that none exist and why)
- Explore agent's full output
- Interaction probe agent's full output
- Paths to `pattern-library.md`, `testing-checklist.md`, `test-scenarios.md`

## Step 6: Report results

```text
✅ Evaluation complete!
📁 Results saved to: {timestamped_directory}
📊 Overall score: {overall_score}/5
🔍 Top issues: {brief_summary}

Clean up with: rm -rf TUI_UX_EVALUATION_*/
```

## Learning: two mechanisms, not one

**This skill learns automatically, on every evaluation, with no separate request needed.** The synthesizer
agent's Step 5 checks whether the TUI it just evaluated demonstrated a genuinely new, generalizable pattern
and — if so — appends it to `pattern-library.md` directly as part of the normal evaluation, dated and
attributed to that evaluation. This is the default "continue to learn" behavior; you don't have to ask for it.

**Learning mode is a second, separate mechanism** for a job per-evaluation growth can't do: proactively
scanning *external* sources for tools this skill has never evaluated and therefore could never learn from
organically. It's opt-in, not automatic, because it's a different kind of operation — it does live web
research (time, external requests, source-quality judgment) rather than reusing evidence already gathered for
a user's actual task, so it runs when explicitly asked for rather than as a side effect of every review.

If the user asks the skill to "research new TUI patterns," "update the pattern library," or similar — instead
of the evaluation flow above, read `pattern-library.md`, use `WebSearch`/`Read` to find recent releases,
articles, or newly popular TUIs (check terminaltrove.com, the Charm and Textualize blogs, r/commandline, and
GitHub trending for `topic:tui`), and append well-attributed new patterns or tools to `pattern-library.md` with
a short rationale for each addition. Do not remove existing entries without checking they're actually obsolete.

## Error handling

- **TUI not found**: ask the user to confirm the command name or path.
- **Requires auth/network the evaluator lacks**: note it, evaluate what's reachable (splash screen, help,
  static source), and say plainly which screens were never observed.
- **No recording tooling installed and the user has none to share**: proceed with source analysis and the
  tmux-probe transcript only; mark visual/color/layout criteria as reduced-confidence in the report.
- **App crashes when driven headlessly (no real TTY)**: note the crash as a finding itself (TUIs should degrade,
  not crash, when run under tmux/CI) rather than treating it as a blocker.
