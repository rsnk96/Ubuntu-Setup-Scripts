# Agents

This repository is two layers.

1. `1-BasicSetUp.sh` and `2-GenSoftware.sh` rebuild a desktop Ubuntu install. Follow `README.md`. Do not run those scripts as part of an unrelated code change.
2. `coding-setup/` is the agent workstation: CLIProxy on `127.0.0.1:8317`, the quota console, T3 Code pointed at an isolated Claude home, and Tailscale Serve so other devices of the same user start sessions on this machine.

When the task is to rebuild that workstation, replicate it on a new laptop, or change how Claude, T3, or the proxy are wired, read [coding-setup/AGENTS.md](coding-setup/AGENTS.md) and follow it. That directory is self-contained and can be split into its own repository later.

Do not commit OAuth files, API keys, management keys, or a filled-in `config.yaml`. The copies under `coding-setup/config/` are templates.
