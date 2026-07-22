#!/usr/bin/env bash

# @file record-asciinema.sh
# @brief Records a TUI walkthrough by driving it inside a detached tmux session while
#        asciinema captures the session as an asciicast v2 `.cast` file. Use this when VHS
#        isn't applicable (non-Charm TUIs, or no `.tape` convention) — asciinema works with
#        any full-screen terminal app and produces a plain-text, directly-readable recording
#        (asciicast v2 is newline-delimited JSON) even without further conversion.
# @usage ./record-asciinema.sh "<tui-command>" [output-dir]
# @example ./record-asciinema.sh "textual run myapp.py" TUI_UX_EVALUATION_20260722_120000/evidence
#
# Edit the "walkthrough" section below to match the target TUI's actual keybindings before
# running — the defaults are a generic guess (Tab to cycle focus, ? for help, q to quit).
#
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>
#
# @dependencies
#   tmux       https://github.com/tmux/tmux
#   asciinema  https://asciinema.org
#   agg        https://github.com/asciinema/agg (optional, for a GIF preview)
#   ffmpeg     https://ffmpeg.org (optional, for frame extraction from the GIF preview)
#
# @exit_codes
#   0  Success
#   1  tmux or asciinema not installed
#   2  Missing required argument

set -euo pipefail

readonly SESSION="tuiux-rec-$$"
readonly CMD="${1:?Usage: record-asciinema.sh \"<tui-command>\" [output-dir]}"
readonly OUT_DIR="${2:-tui-ux-evidence}"
readonly CAST="$OUT_DIR/session.cast"

type tmux &> /dev/null || { echo "tmux is not installed." >&2; exit 1; }
type asciinema &> /dev/null || { echo "asciinema is not installed. https://asciinema.org" >&2; exit 1; }

mkdir -p "$OUT_DIR"
tmux kill-session -t "$SESSION" 2> /dev/null || true
tmux new-session -d -s "$SESSION" -x 100 -y 30 "$CMD"

echo "Recording $CMD (via tmux session $SESSION) to $CAST"
# A calling shell with TERM=dumb (or unset) makes `tmux attach` fail with
# "terminal does not support clear" inside asciinema's own pty — force a real term type.
TERM=xterm-256color asciinema rec --quiet --overwrite --command "tmux attach -t $SESSION" "$CAST" &
readonly REC_PID=$!

sleep 1.5

# --- Walkthrough: adapt these to the target TUI's real keybindings ----------------------
tmux send-keys -t "$SESSION" "?"; sleep 1.2      # help overlay, if bound
tmux send-keys -t "$SESSION" Escape; sleep 0.5
tmux send-keys -t "$SESSION" Tab; sleep 0.8       # cycle focus/panes/tabs
tmux send-keys -t "$SESSION" Down; sleep 0.4
tmux send-keys -t "$SESSION" Down; sleep 0.4
tmux send-keys -t "$SESSION" Down; sleep 0.8
tmux send-keys -t "$SESSION" Tab; sleep 0.8
tmux send-keys -t "$SESSION" "q"; sleep 1
# ------------------------------------------------------------------------------------------

if tmux has-session -t "$SESSION" 2> /dev/null; then
  tmux send-keys -t "$SESSION" C-c
  sleep 0.5
  tmux kill-session -t "$SESSION" 2> /dev/null || true
fi

wait "$REC_PID" 2> /dev/null || true

echo "Recorded: $CAST (asciicast v2 — readable directly as newline-delimited JSON)"

if type agg &> /dev/null; then
  echo "Rendering GIF preview: $OUT_DIR/demo.gif"
  agg "$CAST" "$OUT_DIR/demo.gif"

  if type ffmpeg &> /dev/null; then
    mkdir -p "$OUT_DIR/frames"
    echo "Extracting frames (1 per second) to $OUT_DIR/frames"
    ffmpeg -y -loglevel error -i "$OUT_DIR/demo.gif" -vf "fps=1" "$OUT_DIR/frames/frame_%03d.png"
  fi
else
  echo "agg not installed — skipping GIF/frame conversion. Read $CAST directly as text evidence."
fi

echo "== Recording complete =="
