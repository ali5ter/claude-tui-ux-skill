# TUI Pattern Library

This file is a curated catalog of terminal UI design patterns and exemplar tools that the `tui-ux-tester`
agent draws on when it evaluates a TUI — used to name what a stronger version of a given pattern looks like
elsewhere, not as a checklist to fill in mechanically (see `agents/tui-ux-tester.md`).

**This file is intentionally living and append-only.** It grows over time via the skill's "learning mode"
(triggered by asking the skill to "research new TUI patterns" or "update the pattern library" — see
`SKILL.md`), which searches for newly popular tools and patterns and appends them below with a short
rationale. New entries added by learning mode should be dated and attributed to the source that surfaced
them (e.g. `<!-- added 2026-08-03, via terminaltrove.com trending -->`), and existing entries should only be
removed once they're confirmed obsolete, not merely unfashionable.

## Exemplar TUIs

Each entry below names the framework a tool is built with, two to four specific, named patterns it
demonstrates, and why those patterns hold up under real use — not just praise. When an evaluation cites one
of these tools, prefer citing the specific pattern name (e.g. "context-sensitive footer" or "Miller columns")
over the tool name alone.

### btop

Built with C++ and a custom terminal-rendering layer (no TUI framework; `btop` predates most of the modern
Rust/Go ecosystem and hand-rolls its own ANSI output).

- **Semantic, threshold-based color** — the CPU/memory graphs shift from green through amber to red as load
  increases, so color encodes severity rather than decorating the UI. This works because the mapping is
  consistent across every graph in the app: a user learns "red is bad" once and it holds everywhere, instead
  of having to relearn per-widget conventions.
- **Mouse-optional, not mouse-required** — every clickable element (menu, sort column, process) is also
  reachable by a single keystroke, and the hotkey is shown inline on the widget itself (e.g. the sort column
  header shows the key that cycles it). This matters because it lets power users stay on the keyboard while
  never punishing someone who reaches for the mouse out of habit — neither input method is a second-class
  citizen.
- **Full in-app help reachable from a single, memorable key** — `h` or `F1` opens a help screen listing every
  binding, and `q`/`Ctrl+C` reliably quits from any screen, including the help screen itself. The value here
  is discoverability without needing external docs: a first-time user can learn the entire keymap without
  leaving the terminal.
- **Live layout presets** — `p` cycles between preset panel arrangements without restarting the app or losing
  current data. This demonstrates that a dashboard's information density doesn't have to be a fixed, one-size
  choice — the same underlying data can be re-flowed for a quick glance vs. a deep investigation.

### lazygit

Built with Go and `gocui` (a lower-level terminal UI library, pre-dating Bubble Tea's popularity).

- **Numbered direct-jump panels** — pressing `1`-`5` jumps straight to a specific panel (status, files,
  branches, commits, stash) instead of requiring repeated `Tab` presses. This works because it turns
  navigation from an O(n) sequential operation into an O(1) direct one for the panels a user visits most,
  without removing `Tab`/`Shift+Tab` as the discoverable fallback for anyone who hasn't memorized the numbers.
- **`Esc` with one consistent meaning across every context** — closing a sub-panel, canceling a confirmation
  prompt, and clearing an active filter are all bound to `Esc`. A single key doing "step back" everywhere
  means a user never has to stop and think which dismiss key applies in the current context — the muscle
  memory transfers unchanged.
- **Screen-mode cycling (`+`) instead of fixed pane sizes** — normal, half-screen, and fullscreen modes let a
  user expand the pane they're focused on (e.g. a large diff) without a separate resize gesture or a
  permanently cramped default layout. This is the escape hatch that keeps a multi-pane layout usable when one
  pane's content genuinely needs more room than the others.

### k9s

Built with Go and `tview` (a widget toolkit on top of `tcell`).

- **`?` opens a help overlay scoped to the current view** — the bindings shown are the ones active on the
  resource type currently selected (pods vs. deployments vs. services each have different valid actions), not
  a single flat list of every binding in the whole app. This avoids the common failure mode of a help screen
  that's technically complete but practically useless because it doesn't tell the user what's actually
  reachable right now.
- **`:` command mode with user-defined aliases** — typing `:pp` can be configured to jump straight to pods,
  collapsing a multi-step navigation into a single short command. The pattern generalizes: a TUI that exposes
  a lightweight command-palette-style shortcut on top of its navigation tree lets expert users compress
  repeated multi-key sequences into muscle memory of their own choosing.
- **Context-sensitive footer that mirrors the active resource type** — port-forwarding (`Shift+F`) only
  appears as an available action when a pod, service, or deployment is selected, because it's meaningless
  elsewhere. This is the "don't show actions that don't apply" discipline that keeps a dense information
  screen from becoming a wall of irrelevant hints.

### yazi

Built with Rust and a custom terminal renderer (predates widespread Ratatui adoption in file managers).

- **Asynchronous, non-blocking preview rendering** — image, video-thumbnail, and syntax-highlighted code
  previews are generated off the main thread and a `preview_delay` setting throttles how eagerly they're sent
  to the terminal while a user scrolls quickly through a directory. This is the async-I/O pattern in concrete
  form: the file list stays instantly responsive to arrow-key input even while a heavyweight preview (a large
  image, a video frame extracted via `ffmpeg`) is still being computed in the background.
- **In-terminal image preview via the terminal's own graphics protocol** — on terminals that support it (e.g.
  Kitty, iTerm2), yazi renders actual images and PDFs inline rather than falling back to an ASCII
  approximation. This is a concrete instance of graceful protocol-capability detection: the app checks what
  the host terminal can do and upgrades the experience opportunistically instead of assuming a fixed
  lowest-common-denominator rendering path.
- **Multi-column (Miller-style) browsing** — see the dedicated Miller-columns entry below; yazi is one of the
  actively maintained implementations of this layout alongside `ranger` and `nnn`.

### lazygit-style Git browsers: `tig`

Built with C and a hand-rolled `ncurses` interface.

- **Multiple purpose-built views instead of one generic screen** — `tig` has distinct main/log, diff, tree,
  blame, and status views, each laid out for what that specific task needs (blame aligns commit metadata per
  line; diff highlights hunks), rather than trying to force every Git operation into one shared table layout.
  The lesson generalizes: a TUI covering several genuinely different workflows should give each one a
  dedicated view rather than overloading a single screen with mode-switches that change what the same columns
  mean.
- **Reuses vi-style navigation instead of inventing new bindings** — `j`/`k` scroll, `/` searches, and `g`/`G`
  jump to top/bottom, matching the muscle memory a huge fraction of terminal users already have from `less`,
  `vim`, and similar pagers. This is the "borrow, don't invent" principle: adopting an existing, widely known
  keymap costs the user nothing to learn if they already know it, and costs little if they don't (it's
  documented everywhere).
- **Doubles as a pager for other Git commands** — `tig` can render the output of `git log`, `git blame`, or a
  diff piped into it, so its interactive view is available even when a user didn't launch `tig` directly. This
  is a concrete precedent for criterion 11 (non-interactive interop): the same rendering engine that powers
  the full TUI is also usable as a drop-in replacement for a plain pager, not a walled-off mode.

### Miller-column file browsers: `ranger`, `nnn`, `yazi`

Built with Python (`ranger`), C (`nnn`), and Rust (`yazi`) respectively — different languages, same layout
idea (see the "Miller columns" entry under Layout paradigms below for the underlying concept).

- **Three-pane parent/current/preview split** — the left column shows the parent directory, the middle column
  the current directory, and the right column previews whatever is selected in the middle column. This works
  because it keeps three levels of hierarchical context visible simultaneously — where you came from, where
  you are, and what's next — without a breadcrumb bar or a stack the user has to mentally reconstruct.
- **`nnn`'s plugin system for niche previews** — rather than bundling every possible preview handler (disk
  usage, media metadata, mount management) into the core binary, `nnn` exposes over a hundred optional plugins
  that a user opts into. This is the "small core, opt-in extension" pattern: it keeps the default experience
  fast and uncluttered while still supporting power-user workflows for those who want them.
- **Instant search-as-you-type filtering with regex support** — typing immediately narrows the visible file
  list rather than requiring a separate "enter filter mode" keystroke first. The value is removing friction
  from the single most common file-manager action (finding a file by name) — every keystroke does useful work
  instead of the first one just arming a mode.

### ncdu

Built with C and `ncurses`.

- **Single-purpose depth-first drill-down with live deletion** — a user scans a directory tree sorted by size,
  descends into the largest offender, and can delete a file or directory directly from the list with a
  confirmation prompt, without leaving the tool. This demonstrates that a narrowly scoped TUI (one task: find
  and reclaim disk space) can skip the complexity of multi-pane layouts entirely and still be highly usable,
  because the entire interaction model maps to one linear task.
- **Progress feedback during the (potentially slow) initial scan** — a directory-size scan over a large
  filesystem can take real time, and `ncdu` shows a live count of files scanned so far rather than a frozen
  screen. This is the baseline expectation set by criterion 5 (feedback/state communication) made concrete: any
  operation with unpredictable duration needs a visible "still working, here's how far" signal, not silence.

### `ripgrep` + `fzf` composability

`ripgrep` (Rust) is a search engine, not a TUI by itself; `fzf` (Go) is a fuzzy-finder that can run standalone
or be embedded as a picker inside another program's keybindings.

- **A TUI component that composes via stdin/stdout, not a monolith** — `fzf` reads candidates from stdin
  (which can be `rg`'s streamed output) and writes the selection to stdout, so it works equally well as a
  standalone fuzzy-finder, a shell `Ctrl+R`/`Ctrl+T` widget, or an embedded picker inside a larger TUI's own
  keybindings (many Bubble Tea and Neovim plugins shell out to `fzf` this way). The lesson for full-screen TUI
  authors: a genuinely reusable interactive component should be usable as a subprocess with a plain text
  protocol, not only as a hardcoded feature bolted into one specific application.
- **Live-updating result list keyed to keystroke latency, not full-corpus completion** — `fzf` re-ranks visible
  matches on every keystroke against a large candidate list without waiting for the full search to finish.
  This is the same async-responsiveness discipline described under criterion 8 (performance): input never
  waits on a background computation to complete before the UI acknowledges it.

### gh-dash

Built with Go, Bubble Tea, Lip Gloss for styling, and Glamour for rendering PR/issue markdown bodies inline.

- **User-defined sections driven by saved search filters** — `prSections`/`issuesSections` in a YAML config
  each pair a title with a GitHub search query, so the dashboard's structure is entirely user-authored rather
  than a fixed set of tabs the maintainers chose. This generalizes the "widget dashboard" layout paradigm (see
  below) with a concrete customization mechanism: the panels are configuration, not code, so the same binary
  serves very different workflows (a maintainer triaging everything vs. a contributor watching two repos)
  without a fork.
- **Full keybinding reference behind `?`, layered by scope** — bindings are grouped as universal, PR-specific,
  issue-specific, and notification-specific, and the `?` overlay reflects only what's relevant to the pane in
  focus. This is the same context-sensitive-help discipline as k9s, applied to a dashboard where each section
  can have genuinely different available actions (merge only makes sense on a PR row, not an issue row).
- **Vim-style navigation as the default, not an opt-in mode** — `h`/`j`/`k`/`l` move between and within
  sections out of the box. Defaulting to a convention a large fraction of the target audience (developers who
  already live in a terminal) already knows lowers the learning curve for the majority without needing a
  "vim mode" toggle most users would never find.

### Ratatui showcase apps: `gitui`, `bottom`, `bandwhich`, `joshuto`

Built with Rust and Ratatui (a widget-and-layout library, not a full application framework — see the Charm
ecosystem section for the analogous Go stack).

- **Constraint-based layout instead of hardcoded coordinates** — Ratatui apps define panel sizes as
  percentages, fixed lengths, or `Min`/`Max` constraints resolved at render time, so `gitui`'s three-pane
  status/diff/commit view and `bottom`'s stacked CPU/memory/process widgets both reflow automatically when the
  terminal is resized. This is the concrete mechanism behind criterion 3's "resize gracefully" bar: layout
  described declaratively in terms of proportions survives a resize event without the author having to
  special-case every possible terminal size.
- **`gitui`'s blocking-operation warning instead of a silent freeze** — long Git operations (a large diff, a
  slow remote fetch) show a status message rather than leaving the UI looking hung. Naming the operation in
  progress, even without a percentage, is a lower-cost version of the progress-indicator bar in criterion 5 —
  it's the difference between "the app is doing something" and "the app might be dead."
- **`bottom`'s crossterm/termion dual backend** — supporting two different low-level terminal backends lets the
  same binary run correctly across a wider range of terminal emulators and platforms than committing to a
  single backend would. This is a concrete instance of the terminal-compatibility discipline evaluated in
  criterion 9: breadth of tested terminals is a deliberate engineering choice, not an accident.

### Textual-based apps: `posting`, `dolphie`, `frogmouth`

Built with Python and Textual, a framework that itself borrows web-development conventions (CSS-like styling,
a reactive/async runtime) for terminal apps.

- **`posting`'s Git-friendly local collections** — HTTP requests are stored as plain YAML files rather than in
  an opaque database, so a team can review a request definition in a normal code-review diff the same way they
  would review any other config change. This is a direct, TUI-native answer to criterion 11: the data a TUI
  manages should be inspectable and versionable outside the TUI, not locked inside it.
- **`posting`'s fuzzy command palette (`Ctrl+P`)** — every action reachable through the UI is also reachable by
  typing its name, which is the terminal analog of VS Code's command palette. This matters for discoverability
  at scale: once an app has more actions than fit in a single footer hint strip, a searchable command list
  becomes the fallback that keeps every feature reachable without memorizing a growing keymap.
- **`dolphie`'s live sparkline metrics inside a dense operational dashboard** — queries-per-second and
  replication lag are rendered as compact inline sparklines next to the numeric value they summarize, so a
  database operator gets both the exact figure and its recent trend in the same glance. This is a concrete
  "widget dashboard" instance (see Layout paradigms) purpose-built for an ops audience that needs trend and
  magnitude simultaneously, not one or the other.
- **`frogmouth`'s adaptive light/dark rendering for Markdown** — code blocks and headings re-theme to match
  whichever of Textual's light or dark palettes is active, so a document rendered in a light terminal theme
  doesn't end up with illegible dark-on-dark syntax highlighting. This is the adaptive-theming discipline named
  again under Color & theming conventions below, demonstrated in a content-rendering context rather than a
  dashboard.

### AI-agent TUIs: streaming and thinking-indicator patterns

A newer, fast-growing category — coding-agent and chat TUIs (Claude Code's own terminal UI, `opencode`, `aider`,
Ollama's terminal chat mode) that are neither a classic dashboard nor a file browser, but a single scrolling
conversation pane plus an input box. Frameworks vary (Bubble Tea, Ink, custom renderers); the patterns below
are about the interaction model these tools share, not one specific implementation.

- **Token-by-token streaming instead of a single blocking response** — output appears incrementally as it's
  generated rather than the UI freezing until the full response is ready. This is criterion 8's async-work
  discipline applied to a workload where "done" can take tens of seconds: streaming gives continuous evidence
  the system is alive and making progress, which a spinner alone can't convey once the wait stretches past a
  few seconds.
- **A distinct "thinking" state, visually separated from final output** — many of these tools render an
  intermediate reasoning/tool-call phase (a dimmed or differently colored block, an animated ellipsis, a
  collapsible section) before the final answer, so a user can tell "the model is still working through the
  problem" apart from "the model has answered." This is a state-communication pattern beyond a generic
  spinner: it tells the user *what kind* of work is happening, not just that some work is happening.
- **Interruptible generation via a single, always-live key** — pressing `Esc` or `Ctrl+C` mid-stream stops
  generation immediately rather than requiring the user to wait for the current response to finish. This
  matters because a long-running generative process is exactly the situation where a user is most likely to
  want to bail out early (a wrong direction is obvious well before the response completes), so the escape hatch
  has to be available throughout, not just between turns.

## Charm ecosystem

The Charm (Charmbracelet) stack is the dominant Go TUI toolkit and the one both local reference projects
(`wwlog`, `unspool`) are built on. It's a set of composable libraries rather than one framework, so a project
typically pulls in only the pieces it needs.

### Bubble Tea

**What it's for:** the core interaction/runtime layer — an implementation of The Elm Architecture (model,
update, view) for the terminal, handling the event loop, keypresses, resize events, and screen redraws.

**Notable convention it encourages:** a strict unidirectional `Update(msg) → (Model, Cmd)` cycle, where all
state changes flow through one function and side effects (network calls, timers) are expressed as `Cmd` values
rather than performed inline. This convention is why well-built Bubble Tea apps tend to score well on
criterion 8 (performance/responsiveness) almost by construction — a blocking network call literally cannot
happen inside `Update` without the author working against the framework's grain, so the "did the author
accidentally block the render loop" failure mode is structurally discouraged rather than merely avoided by
discipline.

### Lip Gloss

**What it's for:** declarative, CSS-like style definitions for terminal text and layout — colors, padding,
borders, margins, and alignment, composed as reusable style objects rather than inline ANSI escape sequences.

**Notable convention it encourages:** defining a small palette of named, reusable style values once (e.g. a
`titleStyle`, an `errorStyle`, a `mutedStyle`) and applying them everywhere that semantic meaning appears,
rather than hand-writing color codes at each call site. This is the direct enabling mechanism behind the
semantic-color pattern named in the btop and k9s entries above — a codebase that centralizes its styles in one
place can also centralize a `NO_COLOR`/low-color fallback in that same place, instead of patching dozens of
scattered call sites.

### Bubbles

**What it's for:** a library of pre-built, reusable interactive components (`list`, `viewport`, `textinput`,
`table`, `spinner`, `progress`, `help`, `paginator`) meant to be embedded inside a Bubble Tea `Model` rather
than rebuilt from scratch per project.

**Notable convention it encourages:** the `help` component specifically expects the app to define its
keybindings as a typed `key.Binding` map with both a short (footer-hint) and full (overlay) representation, so
a context-sensitive footer and a full `?` help screen can be generated from the *same* binding definitions
instead of two separately maintained lists that can drift out of sync. This is a structural fix for exactly
the failure this skill flags most often in real projects (see the `unspool` help-overlay finding cited in
`agents/tui-ux-tester.md`) — `bubbles/help` is present as a dependency in many projects specifically because
it makes the correct behavior the path of least resistance, yet it's still frequently left unused.

### Huh

**What it's for:** interactive multi-field forms and prompts (text input, select, multi-select, confirm),
usable standalone or embedded inside a larger Bubble Tea application.

**Notable convention it encourages:** a first-class accessible mode (`form.WithAccessible(true)`) that swaps
the full TUI rendering for a linear, prompt-by-prompt fallback designed for screen readers, exposed as one
explicit toggle rather than a parallel codepath a developer has to build and maintain themselves. This is a
concrete, adoptable answer to criterion 9's accessibility gap that most terminal frameworks leave entirely
unaddressed — terminals generally have no screen-reader API of their own, so an app-level linear-fallback mode
is one of the few practical mitigations available.

### Glamour

**What it's for:** rendering Markdown to styled ANSI terminal output from a JSON stylesheet, used both
standalone (it powers `glow`, Charm's terminal Markdown reader) and embedded inside other TUIs to render
long-form text (release notes, PR bodies, help docs) without hand-formatting.

**Notable convention it encourages:** automatic light/dark background detection that swaps the active
stylesheet so rendered code blocks and headings stay legible regardless of the user's terminal theme. This is
the same "don't assume the terminal background" discipline named under Color & theming below, but applied
specifically to prose content rather than UI chrome — a detail that's easy to overlook because Markdown
rendering often gets bolted on late in a project.

### VHS

**What it's for:** scripted terminal-session recording — a `.tape` file describes keystrokes, timing, and
output settings as a small DSL, and `vhs` replays it in a headless virtual terminal to produce a GIF, MP4,
WebM, or raw frames. See the Recording & testing tooling section below for usage details.

**Notable convention it encourages:** committing the `.tape` source alongside the rendered demo asset (as
`wwlog` does with `examples/wwlog_demo.tape`) rather than committing only the output GIF. A tape file is a
reproducible script, not a one-off screen capture — re-running it against a new build regenerates an
up-to-date demo automatically, so the README's demo never silently drifts out of sync with the app's actual
current behavior the way a hand-recorded GIF inevitably does.

### gum

**What it's for:** a standalone CLI (not a Go library) that adds interactive components — `gum choose`,
`gum confirm`, `gum input`, `gum spin`, `gum filter` — to plain shell scripts, without the script author writing
any Bubble Tea code at all.

**Notable convention it encourages:** every `gum` subcommand reads its data from stdin/arguments and writes its
result to stdout (a chosen option, a confirmed exit code, a spinner-wrapped command's own output), so it
composes with ordinary shell pipelines exactly like `ripgrep`/`fzf` do. This is the same composability lesson
as the `fzf` entry above, but demonstrated from the opposite direction: it shows that "interactive terminal
component" and "well-behaved Unix pipeline citizen" are not in tension — a component can be both at once.

## Layout paradigms

Most well-designed TUIs commit to one of a small number of layout strategies deliberately, rather than mixing
approaches ad hoc across views (this is the structural check behind criterion 3).

### Persistent multi-panel

Multiple panes are visible simultaneously and stay on screen as the user moves focus between them (Tab/numbers
cycle which pane is active, but none of them disappear). **Used by:** `lazygit` (status/files/branches/commits
panes), `k9s` (resource list plus detail/logs panes). This paradigm works when a user needs to correlate
information across panes at once — e.g. seeing which file is staged while also seeing its diff — without
losing either view to navigate to the other.

### Miller columns

Cascading columns show successive levels of a hierarchy side by side; selecting an item in one column reveals
its contents in the next column over, so several levels of depth stay visible simultaneously instead of
replacing the screen on each descent. **Used by:** `ranger`, `nnn`, `yazi` (parent/current/preview three-pane
split). This paradigm works specifically for tree-shaped data (a filesystem) where "where did I come from" is
as useful to keep visible as "where am I now."

### Drill-down stack

The full screen is replaced when the user descends into an item (`Enter`) and restored when they back out
(`Esc`), so only one level of the hierarchy is visible at a time but the full width is available to it.
**Used by:** `k9s` (namespace → resource list → resource detail), most single-pane mobile-inspired TUIs. This
paradigm trades the cross-pane visibility of Miller columns for maximum width per screen — it suits data that's
dense enough to need the full terminal width at each level (a resource's full YAML manifest, for instance)
rather than data that benefits from parent/child correlation.

### Header + scrollable list

A fixed header/status area stays pinned at the top (or bottom) while a single scrollable list occupies the
remaining space — the simplest paradigm, and the right default when there's genuinely one primary view.
**Used by:** `ncdu` (path breadcrumb header, size-sorted file list below), `wwlog`'s Log tab (date/points
summary header, scrollable per-day entries below). This paradigm works precisely because it resists
unnecessary complexity: a tool with one core task doesn't need multi-pane real estate it will never fill.

### Widget dashboard

Independent, simultaneously-updating widgets (graphs, gauges, sparklines, tables) tile the screen, each
summarizing a different data stream at a glance rather than one drilling into another. **Used by:** `btop`
(CPU/memory/network/process widgets), `dolphie` (QPS sparkline, replication-lag gauge, process table). This is
the terminal analog of a web operations dashboard (in the spirit of tools like `ntopng`'s web UI, which uses
the same at-a-glance-widget philosophy) — it works for monitoring use cases where the user's job is to notice
*which* metric changed, not to navigate a hierarchy.

## Keybinding conventions

A near-universal vocabulary has emerged across well-regarded TUIs. Deviating from it without a strong reason
is itself a usability cost (criterion 2), because it breaks muscle memory a user is bringing in from every
other tool they use.

| Key | Near-universal meaning | Tools that establish this convention |
|---|---|---|
| `?` | Open full keybinding help/reference overlay | `k9s`, `gh-dash`, `bottom`, most Bubble Tea apps via `bubbles/help` |
| `q` | Quit the application (or the current view if nested) | `btop`, `k9s`, `lazygit`, `ncdu`, `wwlog` |
| `Ctrl+C` | Emergency quit, works even if a custom keymap is active | Nearly universal — must never be rebound |
| `Esc` | Step back: close a panel, cancel a prompt, clear an active filter | `lazygit`, `k9s`, `btop` (opens main menu when nothing else to back out of) |
| `Tab` / `Shift+Tab` | Cycle focus forward/backward between panes or tabs | `lazygit`, `wwlog` |
| `/` | Enter a filter or search mode scoped to the current view | `k9s`, `btop`, `ranger`, `wwlog` |
| `:` | Enter a command-mode prompt for typed commands/navigation | `k9s`, `tig` (via `:` for internal commands) |
| `j` / `k` | Move down/up one item (vi-style, alternative to arrow keys) | `k9s`, `tig`, `ranger`, `gh-dash`, `lazygit` |
| `g` / `G` | Jump to top / bottom of the current list (vi-style) | `tig`, `ranger`, most vi-convention TUIs |
| `Enter` | Select, confirm, or descend into the highlighted item | Nearly universal across drill-down-stack and Miller-column tools |
| `1`-`9` | Jump directly to a numbered panel/section | `lazygit`, `btop` (limited use) |
| `Ctrl+P` | Open a fuzzy command palette | `posting`, other Textual apps, editors this convention originated in |

## Color & theming conventions

### Semantic color mapping

Color should encode a fixed meaning (status, severity, category) applied consistently everywhere it appears,
not be used decoratively or inconsistently between views. btop's green→amber→red load gradient and k9s's
namespace-colored resource types are both instances of the same underlying discipline: once a user learns what
a color means in one place, it must mean the same thing everywhere else in the app, or the color becomes noise
rather than information.

### `NO_COLOR`

An informal, widely adopted convention (documented at no-color.org, not a formal standard body spec): if the
`NO_COLOR` environment variable is set to any non-empty value, a compliant program suppresses all ANSI color
output regardless of what value it holds. It's checked independently of whether output is going to a TTY — a
program should honor it even when it would otherwise have colorized interactive output — and an explicit,
more specific user preference (a `--color` flag, an in-app theme setting) should still take precedence over it
when both are present. `git`, `ripgrep`, `bat`, and the GitHub CLI all support it; a TUI's non-interactive
escape hatch (criterion 11) should respect it too.

### Adaptive light/dark rendering

An app that detects or lets the user declare whether the terminal background is light or dark, and swaps its
palette accordingly, avoids the single most common color bug in terminal software: a palette tuned for a dark
background (light text, saturated accent colors) becomes nearly illegible on a light background, and vice
versa. Textual's built-in light/dark theme system (used by `frogmouth`, `posting`, `dolphie`) generates CSS
variables from a small set of base colors and lets the whole app re-theme at runtime from one setting, rather
than requiring every widget to be re-styled by hand.

### Truecolor fallback

A TUI that uses 24-bit truecolor for its primary palette needs a documented, tested degradation path for
256-color and 16-color terminals — not just "it happens to render something." Lip Gloss and similar styling
layers can express a color as a set of equivalent values per color-depth tier, so the same style definition
degrades predictably instead of rendering nearest-neighbor-approximated colors that may clash or become
illegible. This is directly what criterion 4's "low-color terminals degrade cleanly" bar is checking for.

### Monochrome-safe design

Graphs, gauges, and status indicators should remain interpretable with color removed entirely — via
labels, symbols, position, or shape — not only via hue. btop's graphs retain their shape and numeric labels
even under `NO_COLOR`; a sparkline that only differentiates "good" from "bad" by color, with no accompanying
number or symbol, fails a colorblind user and a `NO_COLOR` user identically. Designing for monochrome first and
adding color as reinforcement, rather than the reverse, tends to produce interfaces that survive both
situations without a special-cased fallback design.

## Recording & testing tooling

These are the concrete tools this skill's evaluation workflow (`SKILL.md` Step 2) reaches for to produce or
consume visual evidence of a TUI actually running.

### VHS (`.tape` recordings)

**What it is:** a Charm tool that renders a `.tape` script — a small DSL of commands like `Type`, `Sleep`,
`Enter`, `Wait`, `Output`, and `Require` — into a GIF, MP4, WebM, or raw frames, by replaying it in a headless
virtual terminal. **When to reach for it:** the target TUI already has a `.tape` file in the repo (common in
the Charm/Bubble Tea ecosystem, as with `wwlog`'s `examples/wwlog_demo.tape`), or you need a reproducible,
scriptable recording that can be regenerated against a fresh build rather than a one-off manual capture.
**One-line usage:**

```bash
vhs demo.tape
```

### asciinema

**What it is:** a terminal-session recorder that captures a session as a `.cast` file — asciicast v2 is a
newline-delimited JSON format: the first line is a header object (`version`, `width`, `height`, and optional
metadata like `env`), and every following line is a `[time, code, data]` event array, where `code` is `"o"`
for output, `"i"` for input, `"r"` for a resize, or `"m"` for a marker. **When to reach for it:** the app can't
be driven by a scripted `.tape` (it needs genuinely interactive input the DSL can't express), or you want a
recording that's directly readable as text — because it's just JSON lines, a `.cast` file can be parsed for
ANSI color usage, screen-clear frequency, and box-drawing characters without ever rendering it, which is
exactly how this skill's synthesizer agent falls back to reading a `.cast` file as text when no rendered frames
exist (see `agents/tui-ux-tester.md`'s "Reading the recording" section). **One-line usage:**

```bash
asciinema rec demo.cast
```

### tmux capture-pane

**What it is:** tmux's built-in ability to dump the current (or scrollback) contents of a pane to stdout as
plain text, with `-p` printing to stdout instead of a buffer. **When to reach for it:** headless, scriptable
structural probing — driving a TUI inside a detached tmux session and snapshotting its screen at each step to
check what a specific keypress, resize, or `NO_COLOR`/`TERM=dumb` condition actually produces, without needing
any recording tooling installed at all. This is what `scripts/tmux-probe.sh` in this skill is built on, and
it's deliberately the cheapest, most dependency-free evidence-gathering method available — it works even when
neither VHS nor asciinema is installed. **One-line usage:**

```bash
tmux capture-pane -t mysession -p
```

### ffmpeg / agg (frame and GIF extraction)

**What they are:** `ffmpeg` extracts still frames from a video file at a given rate; `agg` (the "asciinema gif
generator") renders a `.cast` file directly to an animated GIF using the `gifski` encoder, without going
through `ffmpeg` at all (a `.cast` file has no video frames to extract — it's timed text and ANSI codes, so
`agg` re-renders it in a virtual terminal rather than converting existing frame data). **When to reach for
each:** use `ffmpeg` when you already have a video/GIF (from VHS, or a user-supplied recording) and need
individual PNG frames for visual review; use `agg` when you have a `.cast` file from asciinema and need a
shareable GIF, or when you want a themed, font-configurable render of that session. **One-line usage:**

```bash
ffmpeg -i demo.mp4 -vf "fps=1" frames/frame_%03d.png
agg demo.cast demo.gif
```

## How this library grows

This file has no fixed end state — it's meant to accumulate. When the skill's learning mode runs (triggered by
a request like "research new TUI patterns" or "update the pattern library," per `SKILL.md`), it searches
sources like terminaltrove.com, the Charm and Textualize blogs, r/commandline, and GitHub's `topic:tui`
trending list, and appends new tool subsections or pattern entries here with a dated attribution comment and a
concrete "why it works" rationale — never a bare tool name with no explanation. Existing entries are only
removed once learning mode has confirmed they're genuinely obsolete (the tool is unmaintained and superseded,
or the pattern has been supplanted by something demonstrably better), never simply because something newer
exists alongside them.
