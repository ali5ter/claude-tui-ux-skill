#!/usr/bin/env bash

# @file tmux-probe.sh
# @brief Drives a TUI inside a detached tmux session and captures pane snapshots at each
#        interaction checkpoint. No recording dependency beyond tmux itself — use this even
#        when VHS/asciinema aren't installed, and always run it alongside a real recording as
#        a fast, cheap structural probe (crashes, resize behavior, focus state).
# @usage ./tmux-probe.sh "<tui-command>" [output-dir]
# @example ./tmux-probe.sh "./wwlog --offline" TUI_UX_EVALUATION_20260722_120000/evidence/probe
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>
#
# @dependencies
#   tmux  https://github.com/tmux/tmux
#
# @exit_codes
#   0  Success
#   1  tmux not installed
#   2  Missing required argument

set -euo pipefail

readonly SESSION="tuiux-probe-$$"
readonly CMD="${1:?Usage: tmux-probe.sh \"<tui-command>\" [output-dir]}"
readonly OUT_DIR="${2:-tui-ux-probe}"

# @description Print a checkpoint label and snapshot the current pane content, both plain
#   (parseable) and with ANSI escapes preserved (color/attribute evidence).
# @param $1 Numeric prefix for the snapshot filename (e.g. "01")
# @param $2 Short label for the checkpoint (e.g. "launch", "help-overlay")
# @side_effects Writes "$OUT_DIR/<prefix>_<label>.txt" and "..._ansi.txt"
snapshot() {
  local prefix="$1" label="$2"
  tmux capture-pane -t "$SESSION" -p > "$OUT_DIR/${prefix}_${label}.txt"
  tmux capture-pane -t "$SESSION" -e -p > "$OUT_DIR/${prefix}_${label}_ansi.txt"
  echo "  captured: ${prefix}_${label}"
}

# @description Send keys to the probed session and settle briefly before the next snapshot.
# @param $@ Keys/strings passed straight through to `tmux send-keys`
send() {
  tmux send-keys -t "$SESSION" "$@"
  sleep 0.4
}

type tmux &> /dev/null || {
  echo "tmux is not installed. Install it, or fall back to source-only evaluation." >&2
  exit 1
}

mkdir -p "$OUT_DIR"
tmux kill-session -t "$SESSION" 2> /dev/null || true

echo "== TUI interaction probe: $CMD =="

# --- Checkpoint 1: launch at a common size (80x24) --------------------------------------
tmux new-session -d -s "$SESSION" -x 80 -y 24 "$CMD"
sleep 1.2
snapshot 01 launch

# --- Checkpoint 2: help overlay, if bound to ? or F1 -------------------------------------
send "?"
snapshot 02 help-question-mark
send Escape
send F1
snapshot 03 help-f1
send Escape

# --- Checkpoint 3: primary navigation (Tab cycles focus/panes/tabs in most TUIs) ---------
send Tab
snapshot 04 tab-focus-1
send Tab
snapshot 05 tab-focus-2
send Down
send Down
snapshot 06 list-navigation

# --- Checkpoint 4: resize down to a small terminal (common failure point) ---------------
tmux resize-window -t "$SESSION" -x 40 -y 10 2> /dev/null || true
sleep 0.5
snapshot 07 resized-40x10
tmux resize-window -t "$SESSION" -x 80 -y 24 2> /dev/null || true
sleep 0.3
snapshot 08 resized-back-80x24

# --- Checkpoint 5: quit paths (both must work without hanging) --------------------------
send "q"
sleep 0.5
if tmux has-session -t "$SESSION" 2> /dev/null; then
  snapshot 09 after-q-still-running
  tmux send-keys -t "$SESSION" C-c
  sleep 0.5
fi
tmux kill-session -t "$SESSION" 2> /dev/null || true

# --- Checkpoint 6: NO_COLOR / TERM=dumb behavior, in a fresh session ---------------------
tmux new-session -d -s "${SESSION}-nocolor" -x 80 -y 24 -e NO_COLOR=1 -e TERM=dumb "$CMD"
sleep 1.2
tmux capture-pane -t "${SESSION}-nocolor" -p > "$OUT_DIR/10_no_color_term_dumb.txt"
tmux capture-pane -t "${SESSION}-nocolor" -e -p > "$OUT_DIR/10_no_color_term_dumb_ansi.txt"
echo "  captured: 10_no_color_term_dumb"
tmux send-keys -t "${SESSION}-nocolor" "q" 2> /dev/null || true
sleep 0.3
tmux kill-session -t "${SESSION}-nocolor" 2> /dev/null || true

echo "== Probe complete. Snapshots in: $OUT_DIR =="
