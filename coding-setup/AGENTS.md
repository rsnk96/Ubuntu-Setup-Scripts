# Coding setup agents

When the user wants this workstation rebuilt, moved to a new machine, or wired the same way again, run `./install.sh` and follow [README.md](README.md). The script is the procedure, the README explains it, and this file is the contract. If they disagree, trust the script for commands and this file for what you must not do.

This directory is the source of truth and can stand alone as its own repository. The parent `AGENTS.md` only points here.

## Do this

- On a blank Ubuntu machine, run the parent `1-BasicSetUp.sh` and `2-GenSoftware.sh` first, when those scripts are present.
- Run `./install.sh`, then `./install.sh login claude` once per subscription in a browser on that machine (`codex` only if the user asks), then `./check.sh`. Report the real output of `check.sh`; a WARN is not a pass.
- Prefer re-running one phase to editing a deployed file by hand. Phases are idempotent and merge into existing settings.
- Keep the proxy on `127.0.0.1:8317` with `management.allow-remote: false`, and T3 on loopback (`serverExposureMode: "local-only"`). Tailscale Serve is published by T3 itself.
- Leave `CLAUDE_CONFIG_DIR` pointed at `~/.claude-cliproxy` for the login session. `install.sh` writes `~/.config/environment.d/claude-cliproxy.conf`. It is read at login, and T3's history lookup uses it instead of `providers.claudeAgent.homePath`.
- CLIProxyAPI is not pinned: `install.sh proxy` installs the newest release and checks the sha256 GitHub publishes for the asset. After an upgrade, run `npm test` in `cliproxy-console/` and read the board for an Anthropic or management-API error banner.
- Run `npm test` in `cliproxy-console/` after any console change. The console runs from the repo through `~/.local/share/cliproxy-console`, so `systemctl --user restart cliproxy-console.service` picks the edit up.
- Change the README, `install.sh`, `check.sh` and the units together. A behaviour that exists in only one of them is a bug.

## Do not do this

- Do not copy `~/.cli-proxy-api/*.json`, `~/.claude-cliproxy/.credentials.json`, `keys.env`, `cliproxy-console/data/settings.json`, or a filled-in `config.yaml` into the repository.
- Do not print management keys, client API keys, OAuth tokens, or Tailscale login URLs in chat, commit logs, or a pasted process listing. Do not put a key on a `curl` command line.
- Do not run `tailscale serve` by hand against T3. Do not publish port 8317 or 8787 with Serve or Funnel. Do not enable Funnel, an exit node, or subnet routes.
- Do not set `server.host` to an empty string or `0.0.0.0`, and do not set T3's `serverExposureMode` to `network-accessible`.
- Do not unset `CLAUDE_CONFIG_DIR` or point it at `~/.claude`. Session fork will not see transcripts written under the isolated home.
- Do not replace `~/.t3/userdata/settings.json` or `desktop-settings.json` wholesale. Edit `desktop-settings.json` only while T3 is closed; the app rewrites it on exit.
- Do not start the console by hand (`node server.mjs`) and leave it running. It must be the systemd unit, or it dies with the shell that started it.
- Do not point the console unit at a Node that cannot import `node:sqlite`. The unit's `ExecStartPre` will refuse to start; fix the Node, not the check.
- Do not `enable-linger` or enable autologin unless the user wants services to outlive a desktop login. Say that the T3 desktop app still stops at logout.
- A Claude login callback from a dead process cannot be redeemed. Start a new `./install.sh login claude`.

## Files an agent may edit

| Change | Where |
| --- | --- |
| Quota board behaviour | `cliproxy-console/` |
| Default proxy routing | `config/cli-proxy-api.config.yaml` |
| Units | `config/*.service` |
| Claude overlay | `config/claude-cliproxy.settings.example.json` |
| Login-session `CLAUDE_CONFIG_DIR` | `config/claude-cliproxy.environment.conf` |
| T3 keys this stack owns | `config/t3-settings.snippet.json`, `config/t3-desktop-settings.snippet.json` |
| Login autostart | `config/t3code-autostart.desktop` |
| Provisioning and verification | `install.sh`, `check.sh` |
| Rebuild steps | `README.md` and this file, together |
