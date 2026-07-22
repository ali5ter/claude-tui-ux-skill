# TUI UX Tester

A Claude Code plugin that provides expert UX evaluation for terminal user interfaces (TUIs) — full-screen,
interactive terminal apps built with frameworks like Bubble Tea, Textual, Ratatui, or raw curses/tcell. Install
via the Claude Code plugin system (`/plugin install tui-ux-tester@ali5ter`).

Sibling project: [`cli-ux-tester`](https://github.com/ali5ter/claude-cli-ux-skill) evaluates one-shot CLIs. This
plugin is the full-screen, interactive counterpart — where the CLI tool scores `--help` text and exit codes,
this one scores what actually gets rendered on screen.

## Why this is different from CLI evaluation

A TUI's usability lives in its rendered screen — layout, color, spacing, motion — not in captured stdout. You
cannot evaluate a TUI by running `--help` and reading text. This plugin's defining step is producing or
obtaining a real recording of the TUI running before scoring it, using whatever tooling is available:

1. **An existing recording in the repo** — many TUI projects already ship a demo GIF/cast (e.g. via a VHS
   `.tape` file); reuse and re-run it against the current build.
2. **A fresh VHS recording** — the Charm ecosystem's own scripted terminal recorder, standard for Bubble Tea
   projects, produces a reproducible MP4/GIF from a declarative script.
3. **A fresh asciinema recording** — drives the TUI inside a `tmux` session while `asciinema` records it,
   works with any framework, produces a plain-text-analyzable `.cast` file (asciicast v2).
4. **A user-provided video, GIF, or `.cast` file** — if automated recording isn't possible (auth-gated flows,
   no recording tooling installed), the skill asks for one instead of guessing.
5. **A live `tmux capture-pane` probe** — runs regardless, as a fast structural check (crashes, resize
   behavior, focus state, `NO_COLOR`/`TERM=dumb` handling) alongside whichever recording method applies.

If none of the above produce visual evidence, the evaluation proceeds from source code alone and says so
explicitly — layout and color findings are marked reduced-confidence rather than guessed.

## Features

- 11-criteria UX framework tailored to full-screen terminal apps (8 core + 3 extended), 1–5 scoring per
  dimension, with rubrics grounded in real findings from published Bubble Tea projects
- A living `pattern-library.md` cataloging concrete patterns from well-regarded TUIs (btop, lazygit, k9s, yazi,
  Textual apps, the Charm ecosystem) and terminal recording/testing tooling — extended over time via a
  **learning mode** the skill runs on request ("research new TUI patterns")
- Active testing: drives the real TUI via `tmux`, captures its actual rendered output, and reads screenshots
  directly rather than inferring appearance from source
- Persistent memory across evaluations for cross-project pattern tracking
- Comprehensive output artifacts: evaluation report, remediation plan, metrics, and captured evidence

## Repository structure

```text
agents/
  tui-ux-tester.md                 # Agent — synthesizes evidence into a scored 11-criteria report
skills/
  tui-ux-tester/
    SKILL.md                       # Skill — detects the TUI, gathers visual evidence, spawns agents
    pattern-library.md             # Living catalog of exemplar TUIs and design patterns
    testing-checklist.md           # Comprehensive per-criterion testing checklist
    test-scenarios.md              # Concrete TUI test scenarios with tmux drive scripts
    scripts/
      record-vhs.sh                # Record a walkthrough with VHS, extract frames
      record-asciinema.sh          # Record a walkthrough with tmux + asciinema, extract frames
      tmux-probe.sh                # Headless interaction probe (no recording dependency)
.claude-plugin/
  plugin.json                      # Plugin manifest
README.md
LICENSE
```

## Install

Inside Claude Code, run:

```text
/plugin marketplace add ali5ter/claude-plugins
/plugin install tui-ux-tester@ali5ter
```

## Usage

After installation, ask Claude to evaluate any TUI in your session:

```text
Review this TUI for UX issues
Evaluate the keybinding scheme in this terminal app
Check the layout and color design of this tool
Research new TUI patterns and update the pattern library
```

The skill detects which TUI to evaluate from the current directory or your message, gathers visual evidence
(recording an interaction walkthrough if it can, asking for one if it can't), then runs the evaluation.

### What gets evaluated

**Core criteria (1–8):**

1. **Discovery & First-Run Onboarding** — does the first screen orient a new user?
2. **Navigation & Keybinding Design** — is there one consistent, predictable scheme?
3. **Layout & Information Architecture** — is the screen structured deliberately, and does it survive resize?
4. **Visual Design, Color & Theming** — is color semantic, and does the app degrade without it?
5. **Feedback, State & Progress Communication** — are operations, errors, and empty states legible?
6. **In-App Help & Discoverability** — is there a `?`/`F1` overlay covering every binding?
7. **Consistency & Predictability** — do views share one interaction model; does config actually take effect?
8. **Performance & Responsiveness** — is input never blocked by background work?

**Extended criteria (9–11):**

1. **Accessibility & Terminal Compatibility** — does it work over SSH/tmux and at small sizes?
2. **Error Handling, Recovery & Data Safety** — are destructive actions guarded, and claimed-reversible ones
   actually reversible?
3. **Non-Interactive / Pipeline Interop** — is there a scriptable escape hatch for users who can't use the TUI?

### Output artifacts

All results go into a timestamped directory in the evaluated project:

```text
TUI_UX_EVALUATION_<YYYYMMDD_HHMMSS>/
├── EVALUATION.md          # Full report with scores and evidence
├── REMEDIATION_PLAN.md    # Prioritized action items with effort estimates
├── metrics.json           # Machine-readable scores for tracking over time
└── evidence/              # Captured frames and interaction-probe transcript, for traceability
```

Clean up with: `rm -rf TUI_UX_EVALUATION_*/`

### Scope

**In scope (UX/DX):**

- Rendered visual behavior: layout, color, motion, responsiveness — verified against real recordings/frames
- Keyboard interaction: keybinding consistency, focus movement, help discoverability
- Accessibility: terminal/SSH compatibility, color-independence, small-terminal survival
- The relationship between the TUI and any non-interactive/pipeline mode it ships alongside

**Out of scope (code quality):**

- Internal rendering-engine or state-management architecture
- Language/framework-specific style unrelated to what the user experiences
- Business logic correctness (data accuracy, API contracts) unless it manifests as a UX failure

## How it works

The plugin provides two components:

- **Skill** (`tui-ux-tester`) — detects the target TUI, gathers visual evidence (existing recording → fresh VHS
  recording → fresh asciinema recording → user-provided file → source-only fallback, always paired with a
  `tmux capture-pane` interaction probe), asks clarifying questions if needed, spawns an Explore agent and an
  interaction-probe agent in parallel, then passes all collected evidence to the synthesizer agent. It also runs
  a **learning mode** on request, using web research to extend `pattern-library.md` with newly notable TUI tools
  and patterns.
- **Agent** (`tui-ux-tester:tui-ux-tester`) — receives pre-collected evidence (recordings, frames, codebase map,
  interaction probe) and synthesizes it into a scored 11-criteria evaluation, `Read`-ing screenshots directly
  rather than inferring appearance from code, producing all output artifacts.

The skill handles recording and parallel evaluation directly because the platform does not support sub-agents
spawning further sub-agents. The agent runs in `acceptEdits` permission mode to auto-approve artifact writes,
and uses persistent `user`-scoped memory to accumulate cross-evaluation patterns over time.

### Recording tooling

None of these are hard requirements — the skill degrades gracefully through the priority order above — but
having them installed produces meaningfully better evidence:

| Tool | Purpose | Install |
|---|---|---|
| [`tmux`](https://github.com/tmux/tmux) | Headless interaction probing (always used) | `brew install tmux` |
| [`vhs`](https://github.com/charmbracelet/vhs) | Scripted recordings via `.tape` files (Charm ecosystem) | `brew install vhs` |
| [`asciinema`](https://asciinema.org) | Text-analyzable `.cast` recordings, any framework | `brew install asciinema` |
| [`ffmpeg`](https://ffmpeg.org) | Extract still frames from video/GIF for visual review | `brew install ffmpeg` |
| [`agg`](https://github.com/asciinema/agg) | Render `.cast` files to GIF for frame extraction | `brew install agg` |

## Safety and quality notes

- The interaction-probe and recording scripts drive the TUI in a **detached `tmux` session** — the current
  terminal is never hijacked.
- Scripted walkthroughs skip any flow requiring real credentials or network access the evaluator doesn't have;
  the report says plainly which screens were never observed.
- All generated files use a timestamped directory for easy cleanup.
- The synthesizer agent uses `permissionMode: acceptEdits` — file writes are auto-approved, but `Bash`
  commands still prompt for permission.

## License

MIT License, Copyright (c) 2026 Alister Lewis-Bowen.
