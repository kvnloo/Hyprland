#!/usr/bin/env bash
set -euo pipefail

label="${1:-cursor-run}"
duration="${2:-15}"
out="${LATENCY_RESULTS_DIR:-hypr-cursor-$(date +%Y%m%d-%H%M%S)-$label}"
mkdir -p "$out"

pid="$(pidof Hyprland | awk '{print $1}')"
if [[ -z "$pid" ]]; then
  echo "Hyprland process not found" >&2
  exit 1
fi

start_iso="$(date --iso-8601=seconds)"

{
  echo "captured_at=$start_iso"
  echo "label=$label"
  echo "duration_s=$duration"
  echo "pid=$pid"
  echo
  hyprctl version || true
  echo
  hyprctl monitors -j || true
  echo
  echo "cursor:no_hardware_cursors"
  hyprctl getoption cursor:no_hardware_cursors || true
  echo
  echo "cursor:use_cpu_buffer"
  hyprctl getoption cursor:use_cpu_buffer || true
  echo
  echo "misc:vrr"
  hyprctl getoption misc:vrr || true
  echo
  uname -a
  echo
  nvidia-smi || true
} > "$out/environment.txt" 2>&1

echo "capture $label for ${duration}s; perform the same mouse-motion pattern now"

perf stat -x, \
  -e task-clock,cycles,instructions,context-switches,cpu-migrations \
  -p "$pid" -- sleep "$duration" \
  2> "$out/perf.csv" || true

journalctl --since "$start_iso" --no-pager \
  | grep -Ei 'hyprland|aquamarine|cursor|drm|kms|blit' \
  > "$out/journal.txt" || true

echo "results: $out"
