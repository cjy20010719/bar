# BarDisplaySwitcher

This compatibility helper provides the display-aware menu bar layout when a
custom `bar.app` build is not available. It watches for display changes and:

- keeps notch-obscured items in the Bar Panel on the built-in display;
- expands all items into the menu bar when a notch-free external display is
  primary.

Run `./install.sh` to compile the helper, install its per-user LaunchAgent, and
start it. The helper expects `bar.app` at `/Applications/bar.app` with bundle
identifier `com.bar.app`.
