#!/usr/bin/env bash
set -euo pipefail

label="${1:-vrr-transition}"
duration="${2:-20}"
out="${LATENCY_RESULTS_DIR:-hypr-vrr-$(date +%Y%m%d-%H%M%S)-$label}"
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
  hyprctl getoption misc:vrr || true
  hyprctl getoption render:direct_scanout || true
  hyprctl getoption render:tearing || true
  hyprctl getoption cursor:no_hardware_cursors || true
  hyprctl getoption cursor:use_cpu_buffer || true
  echo
  uname -a
  nvidia-smi || true
} > "$out/environment.txt" 2>&1

available="$(trace-cmd list -e 2>/dev/null || true)"
args=()

add_event() {
  local event="$1"
  if grep -Fq "$event" <<<"$available"; then
    args+=( -e "$event" )
  fi
}

add_event drm:drm_vblank_event
add_event drm:drm_vblank_event_queued
add_event drm:drm_vblank_event_delivered
add_event drm:drm_crtc_commit
add_event drm:drm_atomic_commit_start
add_event drm:drm_atomic_commit_done
add_event sched:sched_waking
add_event sched:sched_wakeup
add_event sched:sched_switch

echo "capture ${duration}s: perform one planned cursor/direct-scanout transition now"

trace-cmd record -i "${args[@]}" -o "$out/kernel.dat" -- sleep "$duration" &
trace_pid=$!

perf stat -x, \
  -e task-clock,cycles,instructions,context-switches,cpu-migrations \
  -p "$pid" -- sleep "$duration" \
  2> "$out/perf.csv" || true

wait "$trace_pid" || true

journalctl --since "$start_iso" --no-pager \
  | grep -Ei 'hyprland|aquamarine|direct.scanout|vrr|cursor|drm|kms|present' \
  > "$out/journal.txt" || true

echo "results: $out"
