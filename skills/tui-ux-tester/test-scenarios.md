# TUI UX Test Scenarios

Concrete testing scenarios for evaluating terminal user interface (TUI) usability — full-screen, interactive
terminal apps (Bubble Tea, Textual, Ratatui, blessed, raw curses/tcell), as opposed to one-shot CLIs. Each
scenario drives the target TUI inside a detached `tmux` session and inspects state with `tmux capture-pane`,
mirroring the skill's live interaction probe. Substitute the real command, keybindings, and session name for the
placeholders shown (`tuiapp`, `tui-probe`).

## Scenario 1: First Launch & Onboarding

**Context**: A user runs the TUI for the very first time — no config, no cached credentials, no prior state.

**Test Flow**:

```bash
# Fresh launch, no config/state present
mv ~/.config/tuiapp ~/.config/tuiapp.bak 2>/dev/null
tmux new-session -d -s tui-probe -x 100 -y 30 'tuiapp'
sleep 1
tmux capture-pane -t tui-probe -p

# Also probe the missing-credential / missing-setup path if auth is required
tmux send-keys -t tui-probe q
tmux kill-session -t tui-probe
```

**Evaluate**:

- Does the first screen orient a new user (what is this, what can I do, where do I start)?
- Is there a visible hint of the primary/next action, not just raw data?
- If auth or setup is required, is that communicated in-app rather than a silent hang or crash?
- Do tabs/views list what's available even before any real data exists?

**Good Example (real-world)**: the TUI never opens straight onto a data grid. It runs a credential check
(with a spinner), then shows a pre-filled 7-day date-range form before the main view. A user is never
staring at an unexplained blank screen:

```text
┌─ myapp ──────────────────────────────────────────────────┐
│                                                            │
│   Checking credentials...  ⠋                              │
│                                                            │
└────────────────────────────────────────────────────────────┘
        ↓ (credential check resolves)
┌─ myapp ──────────────────────────────────────────────────┐
│ Date range                                                │
│   Start  2026-04-15   (7 days ago)                        │
│   End    2026-04-22   (today)                             │
│                                                            │
│   [ Load ]                       press enter to continue  │
└────────────────────────────────────────────────────────────┘
```

**Bad Example**:

```text
┌────────────────────────────────────────────────────────────┐
│ 2026-04-15  Breakfast: 3 items  12 pts                   │
│ 2026-04-16  Breakfast: 2 items   9 pts                   │
│ 2026-04-17  (no data)                                     │
│                                                            │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

No title, no framing, no indication of what range is loaded or how to change it — the user must guess.

## Scenario 2: Navigating Between Panes & Tabs

**Context**: A multi-view TUI with tabs and/or split panes (list + detail, sidebar + content).

**Test Flow**:

```bash
tmux new-session -d -s tui-probe -x 100 -y 30 'tuiapp'
sleep 1
tmux capture-pane -t tui-probe -p                 # initial focus

tmux send-keys -t tui-probe Tab
tmux capture-pane -t tui-probe -p                 # focus moved to next pane/tab?

tmux send-keys -t tui-probe 'j'                   # or Down
tmux capture-pane -t tui-probe -p                 # selection moved within pane?

tmux send-keys -t tui-probe Enter
tmux capture-pane -t tui-probe -p                 # drilled into detail view?

tmux send-keys -t tui-probe Escape
tmux capture-pane -t tui-probe -p                 # returned to prior level?
tmux kill-session -t tui-probe
```

**Evaluate**:

- Is there ONE consistent scheme (arrows, vim-style `hjkl`/`gg`/`G`, or both) applied identically in every view?
- Does `Tab`/`Shift+Tab` (or an equivalent) move focus between panes/tabs predictably, with a visible focus
  indicator (border highlight, inverse row, etc.)?
- Is `Esc` reserved for "back/cancel" only, never repurposed for something else in a different view?
- Are case-sensitive chords (`Shift+letter`) avoided when every other binding is a bare lowercase letter?

**Bad Example (real-world)**: `A` (audio-only) and `S` (stop) require Shift while every other action
is a bare lowercase letter — the only place the scheme breaks from single-key-no-modifier, inviting mis-presses.

**Good Example**: lazygit's multi-pane "views" — every pane uses the same navigation keys, `Tab`/`]`/`[` cycle
focus, and the focused pane is always visually distinct (colored border), so the current context is never
ambiguous:

```text
┌ Files ─────┐┌ Branches ──┐┌ Commits ─────────────────────┐
│ M main.go  ││> main      ││ a1b2c3 fix: resize handling  │
│   utils.go ││  feature/x ││ d4e5f6 feat: help overlay    │
└────────────┘└────────────┘└───────────────────────────────┘
┌ Status (focused, highlighted border) ─────────────────────┐
│ On branch main. 1 file changed.                            │
└──────────────────────────────────────────────────────────────┘
```

## Scenario 3: In-App Help Overlay (`?` / `F1`)

**Context**: A user forgets a keybinding, or wants to know what's available beyond the current footer hints.

**Test Flow**:

```bash
tmux new-session -d -s tui-probe -x 100 -y 30 'tuiapp'
sleep 1
tmux capture-pane -t tui-probe -p                 # note the footer hint strip

tmux send-keys -t tui-probe '?'
sleep 0.3
tmux capture-pane -t tui-probe -p                 # did an overlay appear?

# If '?' did nothing, also try the F1 convention before concluding help is absent
tmux send-keys -t tui-probe F1
sleep 0.3
tmux capture-pane -t tui-probe -p

tmux send-keys -t tui-probe Escape
tmux kill-session -t tui-probe
```

**Evaluate**:

- Does the footer/header hint strip show keys relevant to the *current* view, updating per view/mode?
- Does `?` or `F1` open a full keybinding reference (the near-universal convention)?
- Does the overlay cover every binding, including ones never shown in the current footer subset?
- Does `Esc` (or the same key) close the overlay cleanly, returning focus to where it was?

**Bad Example (real-world)**: no `?` help overlay exists at all. The footer shows only
a context-specific subset per tab/state — bindings like `A` (audio-only) never appear in the Queue/Playlist
footer even though they may still apply, and there is nowhere in-app to see the full key surface. A help-overlay
component is already an imported dependency and goes unused.

**Good Example**: k9s binds `?` to a header/overlay hotkey reference and keeps a context-sensitive footer at all
times — a user is never more than one keypress from the full list:

```text
┌────────────────────────────────────────────────────────────┐
│ KEY BINDINGS                                          [Esc] │
│                                                              │
│  General                    Navigation                      │
│    ?       Toggle this help   Tab      Next pane             │
│    q       Quit                gg/G    Top/bottom            │
│    /       Filter               j/k    Down/up                │
│                                                              │
│  Actions                                                     │
│    m       Mute channel        u      Unmute channel        │
│    d       Delete              y      Confirm                │
└────────────────────────────────────────────────────────────┘
```

## Scenario 4: Destructive Action Confirmation & Reversibility

**Context**: A user triggers a destructive or state-changing action (delete, mute, remove, overwrite).

**Test Flow**:

```bash
tmux new-session -d -s tui-probe -x 100 -y 30 'tuiapp'
sleep 1
tmux send-keys -t tui-probe 'j'                   # select a target row
tmux send-keys -t tui-probe 'm'                   # trigger the destructive/state-changing key
sleep 0.3
tmux capture-pane -t tui-probe -p                 # confirmation prompt? or applied silently?

tmux send-keys -t tui-probe 'y'                   # confirm (if prompted)
tmux capture-pane -t tui-probe -p                 # applied — now look for a reverse path

# Try to find the documented reverse action
tmux send-keys -t tui-probe '?'
tmux capture-pane -t tui-probe -p                 # is an "unmute"/"undo" binding listed anywhere?
tmux kill-session -t tui-probe
```

**Evaluate**:

- Does the destructive action require confirmation, and is the confirmation specific (names the exact target,
  not a generic "are you sure?")?
- If the app's own docs/PRD describe the action as reversible, does a working reverse path actually exist and
  is it reachable in-app — not just present in the codebase?
- Does cancelling the confirmation (`Esc`/`n`) leave state completely unchanged?

**Bad Example (real-world)**: an unmute operation exists in the underlying store but nothing
in the TUI or CLI calls it — no key, no command. The mute action only ever adds to the mute list. The
product's own docs state explicitly that "every auto-hide is reversible... never asserts certainty," yet a
single mis-press of `m` permanently drops a channel until someone hand-edits the on-disk state file. This is a
promised-but-missing reverse path, not merely an absent confirmation.

**Good Example**:

```text
┌────────────────────────────────────────────────────────────┐
│ Mute "Kurzgesagt"?                                          │
│                                                              │
│ This hides future uploads from this channel in all views.   │
│ Undo any time from Channels → Muted (press u).               │
│                                                              │
│           [ y ] Confirm        [ Esc ] Cancel                │
└────────────────────────────────────────────────────────────┘
```

## Scenario 5: Config Options Actually Taking Effect

**Context**: The TUI documents config options (theme, view mode, thumbnails, etc.) in its README/config file —
verify each one changes observable behavior rather than silently no-opping.

**Test Flow**:

```bash
# Set every documented option to a non-default value
cat > ~/.config/tuiapp/config.toml <<'EOF'
theme = "warm-dark"
view_mode = "grid"
thumbnails = true
EOF

tmux new-session -d -s tui-probe -x 100 -y 30 'tuiapp'
sleep 1
tmux capture-pane -t tui-probe -p                 # does rendering actually reflect the config?
tmux kill-session -t tui-probe

# Cross-check against source: is the option ever read?
grep -rn "view_mode\|thumbnails\|warm-dark" src/
```

**Evaluate**:

- Does every documented config option produce a visible, testable change in behavior?
- Are there any settings a user can set that silently do nothing (worse than not offering the feature — it
  looks configured and isn't)?
- Are defaults sensible, documented, and confirmed overridable by the probe above?

**Bad Example (real-world)**: `theme`, `thumbnails`, `view_mode`, and `dearrow` are all defined with
defaults and documented in the README's config block, but the TUI never reads any of them. Setting
`theme = "warm-dark"` or `view_mode = "grid"` changes nothing, silently.

**Good Example (real-world)**: a config `[targets]`/settings block is read directly by the relevant view —
setting a target visibly moves the on-screen reference line the bars are drawn against, so the option's
effect is immediately checkable in the same session that set it.

## Scenario 6: Resize to a Small Terminal and Recovery

**Context**: The terminal pane is resized down to something much smaller than a typical 80x24, then restored.

**Test Flow**:

```bash
tmux new-session -d -s tui-probe -x 100 -y 30 'tuiapp'
sleep 1
tmux capture-pane -t tui-probe -p                 # baseline at 100x30

tmux resize-window -t tui-probe -x 40 -y 10
sleep 0.5
tmux capture-pane -t tui-probe -p                 # survives 40x10?

tmux resize-window -t tui-probe -x 80 -y 24
sleep 0.5
tmux capture-pane -t tui-probe -p                 # cleanly re-flows back to full layout?
tmux kill-session -t tui-probe
```

**Evaluate**:

- Does the app re-flow content (drop a pane, collapse to a single column, truncate labels) rather than crash or
  render corrupted/overlapping text at 40x10?
- Is there a documented minimum size, communicated in-app ("resize to at least 80x24") rather than a silent
  garble?
- Does the layout fully recover — no leftover redraw artifacts, no panes stuck at the old size — once resized
  back up?
- Does resizing ever crash the process (check the tmux pane is still alive, not silently killed)?

**Good Example**:

```text
┌ tuiapp (40x10) ──────────────────┐
│ ⚠ Terminal too small              │
│ Resize to at least 80x24           │
│ for the full layout.               │
│                                    │
│ Showing: selected item only        │
│ > Kurzgesagt — new upload           │
└────────────────────────────────────┘
```

**Bad Example**:

```text
┌ tuiapp (40x10) ──────────────────┐
│ Kurzgeschaft — new─┐          │
│                                    │
│  Sidebar│Content│Prev│iew          │
│└──────Kur│zgesagt───┘              │
└────────────────────────────────────┘
```

Panes overlap, text is clipped mid-word, and box-drawing characters from two different layouts collide — a
telltale sign the app assumes a fixed minimum size instead of computing layout from actual dimensions.

## Scenario 7: NO_COLOR / Monochrome Fallback

**Context**: A user in a color-restricted terminal, over SSH to a `TERM=dumb` remote, or with `NO_COLOR` set.

**Test Flow**:

```bash
tmux new-session -d -s tui-probe -x 100 -y 30 -e NO_COLOR=1 'tuiapp'
sleep 1
tmux capture-pane -t tui-probe -p -e              # -e keeps escape sequences visible for inspection
tmux kill-session -t tui-probe

tmux new-session -d -s tui-probe -x 100 -y 30 -e TERM=dumb 'tuiapp'
sleep 1
tmux capture-pane -t tui-probe -p
tmux kill-session -t tui-probe
```

**Evaluate**:

- Does `NO_COLOR=1` output contain zero SGR color escape sequences (`grep -c $'\x1b\[3[0-9]m'` on the raw
  capture should be 0)?
- Is status/severity/category still distinguishable via labels or symbols, not color alone?
- Does `TERM=dumb` degrade to a readable, non-corrupted output rather than raw escape codes leaking through?
- Are bars/sparklines/graphs still legible with color stripped (ASCII fill characters, not just color blocks)?

**Good Example**: btop pairs every semantic color with a label or symbol, so the monochrome render loses only
emphasis, not information — a CPU core marked red/hot is also numerically labeled, never color-only:

```text
CPU  [||||||||||||||||||    ] 78%   (colored: green<50% amber<80% red>=80%)
MEM  [||||||||              ] 41%
NET  ↓ 2.1 MB/s  ↑ 340 KB/s          (arrows carry direction, not just color)
```

**Bad Example**:

```text
●  api-server
●  db-server
●  cache
```

Three status dots with no color and no label — in `NO_COLOR` mode this line is meaningless; the user cannot
tell which service is up, degraded, or down.

## Scenario 8: Empty-State View

**Context**: A view or tab has zero items — first run, an empty search/filter result, or an empty archive.

**Test Flow**:

```bash
tmux new-session -d -s tui-probe -x 100 -y 30 'tuiapp'
sleep 1
tmux send-keys -t tui-probe '/'                   # open filter
tmux send-keys -t tui-probe 'zzz-no-match-zzz'
sleep 0.3
tmux capture-pane -t tui-probe -p                 # zero-result state
tmux send-keys -t tui-probe Escape

tmux send-keys -t tui-probe Tab                   # switch to a tab with no data yet
tmux capture-pane -t tui-probe -p
tmux kill-session -t tui-probe
```

**Evaluate**:

- Is the empty state visually distinct from a loading state and from an error state (not all three rendering
  as "blank pane")?
- Does it explain *why* it's empty (no matches for this filter, nothing archived yet) rather than just being
  blank?
- Does it suggest the next action (clear the filter, run the fetch/archive command) rather than leaving the
  user to guess?

**Good Example**:

```text
┌ Log — filter: "zzz-no-match-zzz" ─────────────────────────┐
│                                                              │
│   No entries match this filter.                             │
│                                                              │
│   Press / to change the filter, or Esc to clear it.          │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**Bad Example**:

```text
┌ Log — filter: "zzz-no-match-zzz" ─────────────────────────┐
│                                                              │
│                                                              │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

Indistinguishable from a stalled load or a crash mid-render.

## Scenario 9: Error Mid-Operation with Optimistic-UI Rollback

**Context**: An action updates the UI immediately (optimistic update) while the underlying operation is still
in flight, and that operation then fails.

**Test Flow**:

```bash
# Simulate a backend failure (block the network, or point at an invalid endpoint)
tmux new-session -d -s tui-probe -x 100 -y 30 -e TUIAPP_API=http://127.0.0.1:1 'tuiapp'
sleep 1
tmux send-keys -t tui-probe 'j'                   # select an item
tmux send-keys -t tui-probe 'd'                   # trigger removal
sleep 0.1
tmux capture-pane -t tui-probe -p                 # captured immediately — row gone already?

sleep 2                                            # let the doomed request fail
tmux capture-pane -t tui-probe -p                 # row restored, or error shown, or still silently gone?
tmux kill-session -t tui-probe
```

**Evaluate**:

- Does the row/item reappear (rollback) if the operation fails, or is it marked inline as "failed" rather than
  vanishing permanently from the UI while still existing server-side?
- Is the failure surfaced where the action happened, not just in a log the user won't see?
- Is there a retry path from the failed state, without requiring a full reload?

**Bad Example (real-world)**: the Queue/playlist-item removal paths apply the UI change immediately and
only surface an error string on failure — the row is never restored. A failed delete leaves the user believing
something is gone from YouTube when it isn't, discoverable only on the next reload.

**Good Example**:

```text
t=0.0s  ┌ Queue ─────────────────────────────────┐
        │   Track A                                │
        │ ✗ Track B          (removing...)         │
        └────────────────────────────────────────────┘

t=2.1s  ┌ Queue ─────────────────────────────────┐
        │   Track A                                │
        │ ⚠ Track B          removal failed — r    │
        │                        to retry           │
        └────────────────────────────────────────────┘
```

## Scenario 10: Quitting (`q` and `Ctrl+C`)

**Context**: A user wants to exit — from the main view, from inside a filter/text-input field, and from a
stuck/slow state.

**Test Flow**:

```bash
tmux new-session -d -s tui-probe -x 100 -y 30 'tuiapp'
sleep 1
tmux send-keys -t tui-probe 'q'
sleep 0.3
tmux has-session -t tui-probe 2>/dev/null && echo "STILL RUNNING after q" || echo "exited cleanly"

# q must NOT quit while typing into a filter/text field
tmux new-session -d -s tui-probe -x 100 -y 30 'tuiapp'
sleep 1
tmux send-keys -t tui-probe '/'
tmux send-keys -t tui-probe 'q'
sleep 0.3
tmux capture-pane -t tui-probe -p                 # 'q' should appear in the filter text, app still running
tmux send-keys -t tui-probe Escape

# Ctrl+C must always work as an emergency exit
tmux send-keys -t tui-probe C-c
sleep 0.3
tmux has-session -t tui-probe 2>/dev/null && echo "STILL RUNNING after Ctrl+C" || echo "exited cleanly"
tmux kill-session -t tui-probe 2>/dev/null
```

**Evaluate**:

- Does `q` quit from the main/idle view, but type literally (not quit) while a text-input field has focus?
- Does `Ctrl+C` always exit, even under a custom keymap or mid-operation?
- Does the terminal return to a clean state on exit — alt-screen released, cursor visible, no leftover escape
  sequences in the scrollback (`tmux capture-pane -p -e` should show no stray SGR codes after exit)?
- If the app intercepts the first `Ctrl+C` for graceful shutdown, does a second one force an immediate exit
  rather than hanging?

**Good Example**: `q` and `Ctrl+C` both quit from the idle view, and typing `/` first moves focus into the
filter box, where `q` is treated as ordinary input.

**Bad Example**:

```text
┌ Filter: q ─────────────────────────────────────────────────┐
```

...followed by the shell prompt. The user typed `q` as the first letter of a search term and the whole app
quit, discarding whatever else they'd typed and losing their place in the view.

## Scenario 11: Long-Running Async Operation with Progress Indication

**Context**: An operation that takes more than ~2 seconds (fetching data, archiving, indexing).

**Test Flow**:

```bash
tmux new-session -d -s tui-probe -x 100 -y 30 'tuiapp'
sleep 1
tmux send-keys -t tui-probe 'r'                   # trigger a refresh/fetch/archive action
sleep 0.2
tmux capture-pane -t tui-probe -p                 # is a spinner/progress bar visible already?

# Confirm the UI thread isn't blocked: send a keypress mid-operation
tmux send-keys -t tui-probe 'j'
sleep 0.2
tmux capture-pane -t tui-probe -p                 # did selection move, or is input queued/dropped?

sleep 3
tmux capture-pane -t tui-probe -p                 # final summary shown on completion?
tmux kill-session -t tui-probe
```

**Evaluate**:

- Does the operation show a spinner or progress bar with a description ("Fetching 2026-04-15..."), not a
  frozen screen?
- For counted work, is a running count shown (`fetched 43 / 90`), not just an indeterminate spinner?
- Does a keypress sent mid-operation still register (proves the fetch runs off the render/input thread)?
- Does completion show a summary distinguishing new/updated/unchanged, not just "done"?

**Good Example (real-world)**: a long sync/`--archive`-style operation reports incremental progress and a
categorized summary:

```text
Archiving 90 days (2026-03-03 → 2026-05-31)
  fetched 90 / 90...
Archive complete.
  New       85 days
  Updated    5 days
  Stored    95 days total (2026-02-26 → 2026-05-31)
```

When part of the API window is unreachable, the tool degrades instead of hanging or failing outright, and says
so inline: `note: API unavailable for 3 day(s) — showing archived data where available`.

**Bad Example**:

```text
┌ tuiapp ────────────────────────────────────────────────────┐
│                                                              │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

Nothing on screen changes for the full duration of the fetch; the `j` keypress sent mid-operation is silently
dropped because the UI thread is blocked on the network call.

## Scenario 12: Reading a `.cast` Recording as Text Evidence

**Context**: No screenshots or a video/GIF exist for this TUI — only an asciinema `.cast` recording (or none of
the above, requiring a fresh one). Evaluate the rendering from the raw recording as text, without rendering it.

**Test Flow**:

```bash
# asciicast v2/v3 is newline-delimited JSON: header line, then [time, "o"/"i", data] events
head -1 demo.cast                                  # header: version, width, height, term

# Count full-screen redraws (how "flickery" is the app?)
grep -o '\\u001b\[2J\|\\u001b\[H' demo.cast | wc -l

# Determine color depth actually used: 256-color vs truecolor vs none
grep -c '\\u001b\[38;5;' demo.cast                  # 256-color
grep -c '\\u001b\[38;2;' demo.cast                  # truecolor

# Extract just the terminal output payloads, in order, for a readable transcript
jq -r 'select(type=="array" and .[1]=="o") | .[2]' demo.cast | less -R

# Infer layout structure from box-drawing character usage
grep -o '[─│┌┐└┘├┤]' demo.cast | sort | uniq -c
```

**Evaluate**:

- Can screen-clear/redraw frequency be determined from `\u001b[2J`/`\u001b[H` sequence counts (frequent
  full-screen repaints vs. targeted, cheap updates)?
- Can color depth be determined from `38;5;` (256-color) vs. `38;2;` (truecolor) sequence presence, without
  ever rendering a pixel?
- Can layout structure (panes, borders, tables) be inferred from box-drawing character density and position?
- Is the resulting confidence level stated plainly in the report — this is a legitimate substitute for
  pixel-rendered frames, not a fallback of last resort, but it is still lower-confidence for pure visual/spacing
  judgments than an actual screenshot?

**Good Example**: a distilled transcript excerpt cited directly as evidence, exactly as it would appear in a
report finding:

```text
demo.cast, event at t=2.41s:
  "\u001b[2J\u001b[H\u001b[38;5;208mKurzgesagt\u001b[0m — 3 new uploads\r\n
   ┌─ Feed ─────────────────┐┌─ Preview ──────────┐\r\n..."
```

This one event alone establishes: a full-screen redraw happened at 2.41s, the app uses 256-color (not
truecolor), and the layout is a two-pane split with box-drawing borders — all without ever decoding a frame.

## Scenario 13: Non-Interactive / Pipeline Escape Hatch

**Context**: A user (or a script, or a screen-reader user who cannot use the full-screen TUI at all) needs the
same data the TUI shows, without driving the TUI interactively.

**Test Flow**:

```bash
# Does the app detect a non-TTY context and fall back instead of hanging or emitting garbage escapes?
tuiapp | cat
echo "exit: $?"

# Does a documented flag produce the same data model the TUI renders?
tuiapp --json | jq '.'
tuiapp --export markdown --output /tmp/export.md && cat /tmp/export.md

# Cross-check: does the non-interactive value match what the TUI showed for the same query?
tuiapp --start 2026-04-20 --end 2026-04-26 --json | jq '.[0].Points.DailyUsed'
```

**Evaluate**:

- Does the app auto-detect a piped/non-TTY stdout and fall back to plain output rather than hanging waiting for
  a keypress or emitting raw ANSI escape codes into the pipe?
- Does a documented `--json`/`--report`/`--export`/`--no-tty` flag exist for scripting, CI, or users who cannot
  use the full-screen UI?
- Does the non-interactive output's data model match what the TUI itself displays for the same query — not a
  stale or reduced view?
- Is the non-interactive mode documented as a first-class interface (its own README section with examples), not
  a buried afterthought?

**Good Example (real-world)**: `--json`, `--report`, `--export`, and `--offline` all mirror the TUI's
own data exactly, so the TUI is never the *only* way to reach the underlying information:

```bash
$ myapp --start 2026-04-20 --end 2026-04-26 --json \
  | jq '.[] | {date: .Date, used: .Points.DailyUsed, target: .Points.DailyTarget}'
{"date":"2026-04-20","used":24,"target":26}
{"date":"2026-04-21","used":27,"target":26}
```

`--no-tty` forces pipeline mode even when a real terminal is attached, and `--offline` makes every one of these
flags work with zero network calls, serving from the local archive.

**Bad Example**:

```bash
$ tuiapp | cat
^[[2J^[[H^[[38;5;208mKurzgesagt^[[0m^[[?1049h...
```

Raw escape sequences flood the pipe because the app never checked whether stdout is a TTY before entering
full-screen mode — this also means a screen-reader user has no way to reach the data at all.

## Testing Template

Use this template to log the outcome of each scenario:

```markdown
## Scenario: [Name]

**Driven via**: [tmux probe / recording / .cast transcript]

**Observed Behavior**:
[what the capture-pane output actually showed]

**Expected Behavior**:
[what should have happened]

**Rating**: ___/5

**Issues**:

- [specific issue 1, with an exact transcript excerpt or file:line]
- [specific issue 2]

**Recommendations**:

- [specific improvement 1]
- [specific improvement 2]
```

## Summary

After testing all relevant scenarios:

1. **Most Common Issues**: [patterns observed across scenarios]
2. **Best Aspects**: [what works well, cite the specific scenario]
3. **Priority Fixes**: [top 3 improvements needed, ranked by impact]
4. **Overall Usability**: ___/5
