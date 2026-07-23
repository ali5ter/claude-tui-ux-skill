# TUI UX Testing Checklist

Use this checklist to ensure comprehensive testing of terminal user interfaces (TUIs) — full-screen,
interactive terminal apps (Bubble Tea, Textual, Ratatui, blessed, raw curses/tcell), as opposed to one-shot
CLIs. Criteria 1-8 are core; 9-11 are extended. Work through every section; note the evidence source (recording,
extracted frames, `.cast`-as-text, or source-only) for anything touching layout, color, or motion.

## Pre-Testing Setup

- [ ] Identify the TUI framework in use (Bubble Tea, Textual, Ratatui, blessed, raw curses/tcell, or other)
- [ ] Identify the entry point (binary name, `go run .`, `python -m pkg`, `cargo run`, etc.)
- [ ] Confirm whether the app requires auth/network to reach its main screen (affects which flows are reachable)
- [ ] Check for recording tooling: `which vhs`, `which tmux asciinema`, `which ffmpeg agg`
- [ ] Check for an existing recording in the repo: `**/*.tape`, `**/*.cast`, `examples/**/*demo*.{gif,mp4,webm}`
- [ ] Determine the minimum terminal size to test against (default: 80x24; note if the app documents a
      different minimum)
- [ ] Identify target user personas (beginner, intermediate, power user / vim-style navigator)
- [ ] Confirm whether a non-interactive/pipeline mode exists (`--json`, `--report`, `--no-tty`) before testing it

## Guideline foundations

- [ ] Findings are cross-referenced to the named canons where they apply — clig.dev, Nielsen's 10 heuristics,
      the Charm design philosophy, WCAG2ICT/NO_COLOR (see `agents/tui-ux-tester.md` "Guideline foundations" and
      `pattern-library.md` "Authoritative guideline sources")

## 1. Discovery & First-Run Onboarding

### First Screen

- [ ] The first screen orients a new user (what this is, what's here, where to start)
- [ ] A primary/next action is visibly hinted, not just raw data
- [ ] The app doesn't open directly onto data with zero framing
- [ ] First-screen render is fast — no unexplained multi-second blank wait before anything appears

### Setup & Auth Handling

- [ ] Missing credentials/config are surfaced in-app, not a silent hang
- [ ] Missing credentials/config are surfaced in-app, not a crash
- [ ] An in-app fix path exists for missing setup (prompt, wizard, or documented next step)
- [ ] Loading/checking states (e.g. a credential check) show a spinner, not a frozen screen

### Empty States

- [ ] Views/tabs list what's available even when empty (no unexplained blank panes)
- [ ] Empty states explain why they're empty and what would populate them
- [ ] Empty states suggest the action that fills them (e.g. "press `a` to add")

### Language & Progressive Disclosure

- [ ] The app speaks the user's language — familiar terms and mental models, not internal jargon or
      implementation names (Nielsen #2, match between system and the real world)
- [ ] Complexity is revealed progressively — a simple default path for newcomers, advanced capability
      discoverable rather than forced up front

## 2. Navigation & Keybinding Design

### Keybinding Scheme

- [ ] One consistent scheme (arrows, vim-style `hjkl`/`gg`/`G`, or both) is applied across every view
- [ ] The same key does the same category of thing in every view it appears in
- [ ] Case-sensitive chords (`Shift+letter`) are avoided unless there's genuinely no other option
- [ ] No Shift-chord sits as the lone exception among otherwise bare single-key bindings (real-world failure:
      a lone `Shift`+letter action against an otherwise all-lowercase scheme, easy to mis-press)

### Focus & Tab Movement

- [ ] `Tab`/`Shift+Tab` (or a documented equivalent) move focus between panes/tabs predictably
- [ ] The currently focused pane/element is visually distinct
- [ ] Focus order is logical (matches reading order or visual layout)

### Reserved & System Keys

- [ ] `Esc` is reserved for back/cancel and never repurposed for something else
- [ ] `q` (or a documented equivalent) is reserved for quit
- [ ] `Ctrl+C` always exits, even if a custom keymap is in effect
- [ ] `Ctrl+Z` and `Ctrl+D` are left alone rather than overridden by the app
- [ ] A second `Ctrl+C` (or equivalent) force-exits if the first one is caught for cleanup

### Discoverable/Custom Navigation

- [ ] Vim-style navigation (`hjkl`, `gg`, `G`, `/`) is offered as an option, not forced on non-vim users
- [ ] Key bindings are customizable, or the default set is documented as fixed
- [ ] Mouse clicks (if supported) navigate to the same places as their keyboard equivalents

### Power-User Accelerators

- [ ] Expert accelerators exist without blocking newcomers (Nielsen #7) — e.g. a command palette (`Ctrl+P`),
      direct-jump numbered panels, or customizable keybindings, layered on top of discoverable defaults
- [ ] Accelerators are additive: the discoverable path still works for someone who hasn't learned them

## 3. Layout & Information Architecture

### Reviewing the Rendered Output

- [ ] Actual screenshots/extracted frame PNGs were reviewed directly for this criterion (not inferred from
      source code alone)
- [ ] If no frames exist, the `.cast` file was read as text and box-drawing characters (`─│┌┐└┘├┤`) and
      `\u001b[2J`/`\u001b[H` clear/redraw sequences were used to reconstruct layout structure
- [ ] If neither frames nor a `.cast` exist, this criterion is explicitly flagged as reduced-confidence,
      source-only evidence

### Layout Paradigm

- [ ] The layout matches one deliberate paradigm — persistent multi-panel dashboard, Miller columns,
      drill-down stack (`Enter` descends / `Esc` ascends), or header + scrollable list
- [ ] The chosen paradigm is applied consistently across every view, not mixed ad hoc
- [ ] Borders/spacing/alignment group related content and visually separate unrelated content
- [ ] Information density is appropriate — enough on screen to be useful without becoming a wall of text

### Resize Behavior

- [ ] The app re-flows cleanly when the terminal is resized down to ~80x24
- [ ] The app does not crash or corrupt its own display on resize
- [ ] The app defines and documents a minimum supported size
- [ ] Below the minimum size, the app degrades gracefully (truncates/scrolls) rather than clipping silently

### Sizing Model

- [ ] Layout is constraint-based (percentages/fractions/min-max), not hardcoded absolute positions
- [ ] Panes are resizable or toggleable, if the app's complexity warrants it

### Spatial Memory & Minimalism

- [ ] Panels keep stable positions across views and sessions so users build spatial memory (Nielsen #4; Charm)
- [ ] No decorative borders or box-drawing that add visual noise without information (Nielsen #8; Charm favors
      whitespace over borders to separate content)

## 4. Visual Design, Color & Theming

### Reviewing the Rendered Output for Color

- [ ] Actual screenshots/extracted frame PNGs were reviewed directly for this criterion (not inferred from
      source code alone)
- [ ] If no frames exist, the `.cast` file was read as text and `\u001b[38;5;`/`\u001b[38;2;` sequences were
      inspected to determine 256-color vs. truecolor usage
- [ ] If neither frames nor a `.cast` exist, this criterion is explicitly flagged as reduced-confidence,
      source-only evidence

### Color Semantics

- [ ] Color is used semantically (status, severity, category), not decoratively
- [ ] The semantic mapping is consistent across every view (e.g. red always means the same category of thing)
- [ ] Graphs/sparklines/bars are legible in monochrome as well as in color

### Low-Color & No-Color Fallback

- [ ] `NO_COLOR` is respected — no ANSI color codes emitted when set
- [ ] `TERM=dumb` produces a legible fallback, not garbled escape sequences
- [ ] The app degrades gracefully on terminals without truecolor/256-color support
- [ ] The app remains fully usable with color removed entirely (relies on layout/labels/symbols too)

### Theming

- [ ] The app adapts to light vs. dark terminal backgrounds, or offers an explicit theme choice
- [ ] Theme selection (if any) persists across sessions
- [ ] Text remains legible against both light and dark backgrounds in the frames reviewed

### Visual Hierarchy & Accessible Color

- [ ] Deliberate visual hierarchy, not uniform weight — secondary content dimmed, primary near-white/bold, a
      primary accent reserved for 1-2 elements, bold and borders used sparingly (Charm craft rules)
- [ ] The 16-color golden rule holds — usable in a 16-color terminal; truecolor enhances but is not the only
      thing creating the hierarchy
- [ ] Color choices are colorblind-safe — never red-vs-green as the only distinction
- [ ] Meaning carried by color or an ASCII/Unicode symbol also has a text equivalent (WCAG non-text content)

## 5. Feedback, State & Progress Communication

### Progress Indicators

- [ ] Operations under ~2 seconds show no indicator (feels instant)
- [ ] Operations over ~2 seconds show a spinner or progress bar with a description
- [ ] Progress indicators animate smoothly rather than appearing frozen
- [ ] What's happening is described in text (e.g. "Fetching…", "Archiving 90 days…"), not a bare spinner

### State Distinctness

- [ ] Loading, empty, error, and success states are each visually distinct, not just plain-text differences
- [ ] Transient confirmations (e.g. "saved") are visually distinguished from persistent state
- [ ] A status/notification area exists and is consistently placed

### Optimistic UI & Rollback

- [ ] Optimistic UI updates (action appears to succeed immediately) roll back visibly on failure
- [ ] No optimistic update leaves a stale/incorrect state silently on failure (real-world failure: a list
      removal that never restores the row when the underlying delete fails)
- [ ] Failed operations surface a specific error, not just a generic status string

### Fallback & Degraded-Mode Notices

- [ ] If the app falls back to cached/offline data, that fallback is surfaced in the status area, not silent
- [ ] Partial failures (e.g. some data unavailable) are communicated per-item, not as a single opaque error

## 6. In-App Help & Discoverability

### Context-Sensitive Hints

- [ ] A footer/header hint strip shows keys relevant to the *current* view, not a static global list
- [ ] Hints update when focus or view changes
- [ ] Every binding shown in a hint actually works as described

### Full Help Overlay

- [ ] A full keybinding reference is reachable via `?` or `F1` (the near-universal convention)
- [ ] The overlay covers every binding, including ones not shown in the current footer
- [ ] The overlay is reachable from every view, not just the initial screen
- [ ] The overlay can be dismissed with the same key that opened it, or `Esc`

### Discoverability Gaps

- [ ] No binding exists that is undiscoverable anywhere in-app (real-world failure: a TUI that ships
      `bubbles/help` as a dependency but never wires a `?` overlay, leaving some bindings undiscoverable)
- [ ] Destructive or advanced actions are not hidden entirely from any help surface

### External Docs Parity

- [ ] A README, demo GIF, or recording exists for evaluation before installing
- [ ] The README's keybindings table (if any) matches actual in-app behavior exactly (real-world practice:
      a README key-bindings table kept in exact sync with in-app behavior)
- [ ] Demo assets (VHS `.tape`, `.gif`) are current with the build under test, not stale

## 7. Consistency & Predictability

### Cross-View Interaction Model

- [ ] All views/tabs share the same interaction model (same key = same category of action everywhere)
- [ ] Tab/view switching uses one consistent mechanism throughout
- [ ] Sort/filter mechanisms (if present in multiple views) behave identically wherever they recur

### Widget Consistency

- [ ] Lists, forms, and dialogs are styled identically wherever they recur
- [ ] Confirmation dialogs share one visual pattern across all destructive actions
- [ ] Selection/highlight styling is consistent across every list/table in the app

### Config Wiring

- [ ] Every documented config option actually takes effect — no dead/no-op settings (real-world failure:
      config keys that are documented and have defaults but are never read by the TUI, so setting them
      silently no-ops)
- [ ] Config file location follows a standard convention (XDG Base Directory or documented equivalent)
- [ ] Config precedence (flags > env > project > user > default, or whatever order the app defines) is
      documented

### Defaults

- [ ] Default behavior without any config/flags is sensible and predictable
- [ ] Defaults are documented
- [ ] Defaults are overridable

## 8. Performance & Responsiveness

### Startup Time

- [ ] First screen renders quickly — no multi-second blank wait before anything appears
- [ ] Heavy initialization (auth checks, large data loads) happens after or alongside the first paint, not
      before it

### Input Latency

- [ ] Keypresses register with no perceptible lag, even during background work
- [ ] Keypresses are never dropped or queued up during a slow operation
- [ ] Held-key repeat (e.g. holding an arrow key to scroll) stays responsive

### Async Operations

- [ ] Expensive work (network, disk, large renders) runs asynchronously, never blocking the UI thread
- [ ] The UI remains interactive (can navigate, can cancel) while an async operation is in flight
- [ ] Long operations can be cancelled without corrupting app state

### Redraw & Scale

- [ ] Scrolling/redraw stays smooth as data volume grows
- [ ] No full-screen flicker or full repaint on every keystroke
- [ ] View switching feels close to instant once data is loaded

## 9. Accessibility & Terminal Compatibility

### tmux & SSH Compatibility

- [ ] The app runs correctly inside `tmux` (via `tmux capture-pane` probe or direct session) without visual
      corruption
- [ ] The app runs correctly over SSH without escape-sequence corruption
- [ ] The app runs correctly inside `screen`, if that's a supported target

### Resize Testing via tmux Probe

- [ ] `tmux` pane resized to 80x24 was captured and reviewed — layout re-flows without clipping or crashing
- [ ] `tmux` pane resized to a very small size (e.g. 40x10) was captured and reviewed — the app degrades
      gracefully rather than corrupting output
- [ ] The app recovers cleanly when resized back to a normal size after being shrunk

### Environment Variable Handling

- [ ] `NO_COLOR=1` was tested directly — colors are fully suppressed
- [ ] `TERM=dumb` was tested directly — the app either degrades gracefully or exits with a clear message,
      rather than emitting raw/garbled escape codes
- [ ] Behavior under `NO_COLOR`/`TERM=dumb` was captured via the tmux probe, not assumed from source

### Non-Color-Dependent Information

- [ ] Critical information is conveyed by more than color alone (labels/symbols alongside color)
- [ ] The app is fully keyboard-driven — no feature requires the mouse
- [ ] Mouse interactions, if present, are optional enhancements only

### Escape Hatch

- [ ] A non-interactive/pipeline mode exists for users who can't or don't want to use the full-screen UI
      (screen-reader users have no terminal accessibility API to rely on otherwise — see criterion 11)

### Screen-Reader Reality & Contrast

- [ ] The redraw model was considered: a redraw-heavy 2D-grid TUI (Bubble Tea, Ink, etc.) spams screen readers
      with full-screen repaints — is a linear/plain fallback offered (Huh accessible mode, or the criterion 11
      non-interactive mode) rather than assuming "it's text, so it's accessible" (the "text-mode lie")?
- [ ] Foreground/background pairings meet WCAG contrast (≈4.5:1 text, ≈3:1 glyphs/borders) on each terminal
      theme the app claims to support

## 10. Error Handling, Recovery & Data Safety

### Destructive Action Confirmation

- [ ] Destructive actions (delete, mute/unmute-if-irreversible, overwrite) require explicit confirmation
- [ ] Confirmation prompts state specifically what will happen, not a generic "are you sure?"
- [ ] A confirmation can be cancelled without side effects

### Reversibility

- [ ] Every action described (in-app or in docs) as reversible has a working, reachable reverse path
      (real-world failure: a reversible-by-design action whose reverse path is never wired to any key or
      command, despite docs promising it)
- [ ] Irreversible actions are labeled as such before confirmation

### Crash & State Recovery

- [ ] A failed network/disk operation does not crash the app
- [ ] A failed operation does not corrupt the app's own state file/store
- [ ] The app recovers to a usable state after an error without requiring a restart

### Error Message Quality

- [ ] In-app error messages are specific, not a bare "error" or raw stack trace
- [ ] Error messages are actionable — they suggest what to do next
- [ ] Errors are visually distinct from normal status messages (see criterion 5)

### Error Prevention

- [ ] Input is validated at entry — a bad value is rejected before submission, not after (Nielsen #5)
- [ ] Inapplicable actions are disabled/hidden in the current context rather than offered and then failing
- [ ] Defaults are sensible and safe, so the common path doesn't require actively steering around a mistake

## 11. Non-Interactive / Pipeline Interop

### Non-TTY Detection

- [ ] The app detects a non-TTY context (piped stdout, no controlling terminal, `CI=true`) automatically
- [ ] In a non-TTY context, the app falls back to plain output or exits cleanly, rather than hanging
- [ ] In a non-TTY context, the app never emits raw/garbled escape codes into the pipe
- [ ] A `--no-tty` (or equivalent) flag exists to force pipeline mode even inside a real terminal

### Non-Interactive Mode & Data Parity

- [ ] A non-TUI mode exists for scripting/CI (`--json`, `--report`, `--export`, or equivalent)
- [ ] `--json`/`--export` output reflects the same underlying data model as the TUI (not a stale or
      different view) — verify with a side-by-side comparison of a TUI screen and the corresponding export
      (real-world practice: `--json`/`--report`/`--export` output that mirrors the TUI's data exactly)
- [ ] Every major data view reachable in the TUI has a corresponding non-interactive export path, not just one

### Scripting Ergonomics

- [ ] Machine-readable output is well-formed and parseable (valid JSON, consistent schema across runs)
- [ ] Exit codes are meaningful in non-interactive mode (0 success, non-zero failure)
- [ ] Non-interactive mode is documented as a first-class interface, with example commands, not an
      undocumented side effect

## Testing Notes

### Observations

[Space for notes during testing]

### Issues Found

[List specific issues with severity]

### Recommendations

[Specific improvements to suggest]

## Rating Summary

Rate each core criterion 1-5:

- Discovery & First-Run Onboarding: ___/5
- Navigation & Keybinding Design: ___/5
- Layout & Information Architecture: ___/5
- Visual Design, Color & Theming: ___/5
- Feedback, State & Progress Communication: ___/5
- In-App Help & Discoverability: ___/5
- Consistency & Predictability: ___/5
- Performance & Responsiveness: ___/5

**Core 8-Criteria Score: ___/5** (average of above)

### Extended Criteria

- Accessibility & Terminal Compatibility: ___/5
- Error Handling, Recovery & Data Safety: ___/5
- Non-Interactive / Pipeline Interop: ___/5

**Overall UX Score: ___/5** (average of all 11)

## Next Steps

Based on findings:

1. [Priority 1 action item]
2. [Priority 2 action item]
3. [Priority 3 action item]
