#!/usr/bin/env bash

# @file record-vhs.sh
# @brief Records a TUI walkthrough with VHS (the Charm ecosystem's scripted terminal recorder)
#        and extracts still frames for visual review. Prefer this when the project already has
#        a `.tape` file (common in Bubble Tea projects — VHS is Charm's own tool) or when a
#        reproducible, declarative recording is wanted. If no `.tape` is given, a generic
#        navigation walkthrough is generated and used.
# @usage ./record-vhs.sh "<tui-command>" [output-dir] [existing.tape]
# @example ./record-vhs.sh "./wwlog --offline" TUI_UX_EVALUATION_20260722_120000/evidence
# @example ./record-vhs.sh "./wwlog --offline" ./evidence examples/wwlog_demo.tape
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>
#
# @dependencies
#   vhs     https://github.com/charmbracelet/vhs
#   ffmpeg  https://ffmpeg.org (for frame extraction; optional — skipped if absent)
#
# @exit_codes
#   0  Success
#   1  vhs not installed
#   2  Missing required argument
#   3  vhs run failed

set -euo pipefail

readonly CMD="${1:?Usage: record-vhs.sh \"<tui-command>\" [output-dir] [existing.tape]}"
readonly OUT_DIR="${2:-tui-ux-evidence}"
readonly TAPE_IN="${3:-}"

type vhs &> /dev/null || {
  echo "vhs is not installed. Refer to https://github.com/charmbracelet/vhs for installation instructions." >&2
  exit 1
}

mkdir -p "$OUT_DIR"
readonly TAPE="$OUT_DIR/session.tape"
readonly VIDEO="$OUT_DIR/demo.mp4"
readonly FRAMES_DIR="$OUT_DIR/frames"

if [[ -n "$TAPE_IN" && -f "$TAPE_IN" ]]; then
  echo "Reusing existing tape: $TAPE_IN"
  # Re-point Output at our video path so frame extraction always finds it in the same place.
  sed -E "s#^Output .*#Output ${VIDEO}#" "$TAPE_IN" > "$TAPE"
else
  echo "No tape provided — generating a generic navigation walkthrough."
  cat > "$TAPE" << TAPE_EOF
Output ${VIDEO}

Set FontSize 14
Set Width 1200
Set Height 700
Set Padding 10
Set Shell bash

Type "${CMD}"
Enter
Sleep 2s

# Discover the help overlay, if any
Type "?"
Sleep 1s
Escape
Sleep 500ms

# Cycle focus/tabs, browse a list
Tab
Sleep 800ms
Down
Sleep 300ms
Down
Sleep 300ms
Down
Sleep 800ms
Tab
Sleep 800ms

# Quit
Type "q"
Sleep 1s
TAPE_EOF
fi

echo "Running: vhs $TAPE"
vhs "$TAPE" || {
  echo "vhs run failed — the tape's assumed keybindings may not match this TUI. Adapt $TAPE and re-run." >&2
  exit 3
}

if type ffmpeg &> /dev/null; then
  mkdir -p "$FRAMES_DIR"
  echo "Extracting frames (1 per second) to $FRAMES_DIR"
  ffmpeg -y -loglevel error -i "$VIDEO" -vf "fps=1" "$FRAMES_DIR/frame_%03d.png"
  echo "Frames ready: $FRAMES_DIR/frame_*.png"
else
  echo "ffmpeg not installed — skipping frame extraction. Read $VIDEO directly if your tooling supports it."
fi

echo "== Recording complete: $VIDEO =="
