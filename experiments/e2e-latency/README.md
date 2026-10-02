# VRR / direct-scanout / photon transition experiment

Live references:

- Hyprland discussion 12013 — VRR cursor stutter
- 13236 — VRR behavior depends on direct scanout and captured cursor state
- 14124 — several-frame stutter after cursor visibility toggles direct scanout
- 14729 — VRR-linked low compositor frame rate on newer Intel eDP systems

## Goal

Capture the transition itself, not only steady state.

## Setup

For full Hyprland/Aquamarine logs, start the session with tracing enabled:

```sh
HYPRLAND_TRACE=1 AQ_TRACE=1 start-hyprland
```

Then run one controlled transition per capture:

```sh
bash experiments/e2e-latency/capture-vrr-transition.sh cursor-show 20
```

Examples:

- hidden cursor -> visible cursor
- visible -> captured
- direct scanout eligible -> composited
- composited -> direct scanout
- VRR off -> on

## Capture

The helper records:

- compositor configuration/environment;
- DRM/vblank/atomic tracepoints that exist on the kernel;
- scheduler wakeups;
- Hyprland CPU counters;
- relevant journal messages.

Pair it with the DRM first-pixel sampler and frameprobe when the hardware rig is available.

## Question

If a one-event cursor/direct-scanout transition causes several bad frames, identify which state stays changed after the initiating event:

- plane/buffer assignment
- color-management path
- swapchain
- VRR state
- GPU clocks
- queued frames
- direct-scanout eligibility

No upstream promotion from this branch.
