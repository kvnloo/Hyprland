# High-polling cursor-path experiment

Reference: Hyprland discussion 14434 documents mouse-motion-linked CPU saturation around cursor fallback paths. Current Hyprland exposes `cursor:no_hardware_cursors` and `cursor:use_cpu_buffer`; the latter defaults to auto and is enabled for NVIDIA systems.

## Goal

Find whether pointer report rate is amplified into compositor work.

## Manual matrix

Keep the scene static and repeat the same mouse movement for each state.

- current automatic hardware cursor policy
- software cursor
- hardware cursor with CPU buffer
- 125 / 500 / 1000 / 2000+ Hz where supported
- VRR off / on

Do not change multiple variables between paired runs.

## Capture

```sh
bash experiments/e2e-latency/capture-cursor-run.sh hw-auto-1000 15
```

The script records Hyprland/Aquamarine environment, current cursor options, `perf stat` counters, and relevant journal messages.

Useful follow-up counters after reproduction:

- damage operations per second
- cursor buffer imports per second
- DRM/KMS commits per second
- render passes per second
- main-thread wakeups
- visible cursor age

If CPU cost scales with report rate only on a software/fallback path, trace the first operation whose rate follows mouse events.

No upstream promotion from this branch.
