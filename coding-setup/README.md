# Coding setup

Rebuild kit for the local agent workstation. It is self-contained and can be split into its own repository.

What you get:

- CLIProxyAPI on `127.0.0.1:8317`: one OAuth login per Claude subscription, sticky sessions, failover when an account returns 429.
- A quota console on `127.0.0.1:8787` (`cliproxy-console/`).
- An isolated Claude home, `~/.claude-cliproxy`, that sends Claude Code through the proxy. The login session exports `CLAUDE_CONFIG_DIR` to that home, which is what T3's history lookup reads. `~/.claude` is not rewritten.
- T3 Code (Nightly) using that home, started at login, so threads run on this machine.
- Tailscale Serve, published by T3 itself, so your other devices open T3 over HTTPS. Nothing else is published.

Recorded from the working laptop on 2026-10-04: CLIProxyAPI 8.0.13 (new installs take the newest release), T3 Code `0.0.46~nightly.20261004.2657`, Tailscale 1.102.4, Node with `node:sqlite` (22.13 or newer). The console speaks the v8 management API, so read the release notes before moving past 8.x.

## New machine

```bash
# 1. Base system (repo root)
./1-BasicSetUp.sh && ./2-GenSoftware.sh        # then log out and back in

# 2. Everything in this directory
cd coding-setup
./install.sh                                    # asks for sudo where needed

# 3. One browser login per Claude subscription
./install.sh login claude                       # repeat per account
./install.sh login codex                        # optional

# 4. Verify
./check.sh
```

`install.sh` is idempotent. Re-run it, or a single phase (`./install.sh console t3`), whenever something drifts. It never regenerates an existing key or overwrites other keys in your settings files.

| Phase | What it does |
| --- | --- |
| `node` | Finds a Node that imports `node:sqlite` (`$CLIPROXY_NODE`, `/usr/bin/node`, then `node` on `PATH`). If none works it installs NodeSource Node 24. |
| `agents` | Installs the Claude Code CLI (`claude`), Cursor Agent (`cursor-agent`) and OpenCode 2 (`opencode2`, from `@opencode/cli` through Bun) when they are missing. |
| `proxy` | Installs the newest CLIProxyAPI release (re-running upgrades it) with the sha256 GitHub publishes for the asset checked, generates the two keys into `~/.config/cli-proxy-api/keys.env`, renders `config.yaml`, enables `cli-proxy-api.service`. |
| `claude` | Writes the proxy `env` into `~/.claude-cliproxy/settings.json` (other keys kept), links `CLAUDE.md`, `skills`, `plugins`, `hooks` from `~/.claude` when they exist, and installs `~/.config/environment.d/claude-cliproxy.conf`. |
| `console` | Runs the console tests, symlinks the repo copy to `~/.local/share/cliproxy-console`, seeds `data/settings.json`, enables `cliproxy-console.service` pinned to the Node it found. |
| `t3` | Installs the newest T3 Nightly `.deb` from the [GitHub releases page](https://github.com/pingdotgg/t3code/releases) (sha256 checked; set `T3_DEB` to use one you downloaded), merges `config/t3-settings.snippet.json` into `settings.json` and `config/t3-desktop-settings.snippet.json` into `desktop-settings.json`, and installs the same `CLAUDE_CONFIG_DIR` drop-in as the `claude` phase. |
| `autostart` | Installs `~/.config/autostart/t3code.desktop`. |
| `tailscale` | Installs Tailscale and joins your tailnet with `--operator="$USER" --accept-routes=false`, then reminds you to delete the older devices in the admin console. |
| `power` | Opt-in. Never suspend on AC, ignore the lid switch. For a box that stays closed on a desk. |
| `check` | Runs `check.sh`. |

T3 Code has to come from the releases page. Nightly builds are prereleases there, so the "Latest" badge points at an older stable build; take the newest `T3-Code-<version>-nightly.<date>.<n>-<arch>.deb`. Do not use the t3.codes install script. To install by hand, download that `.deb` and run `sudo apt install ./T3-Code-*.deb`, then `./install.sh t3` for the settings.

Two phases need a human: `tailscale` prints a device-login URL (a secret, do not paste it anywhere), and the first Serve start can refuse until HTTPS is enabled for the tailnet. It prints an admin URL; enable it, then restart T3.

## What survives a restart

| Piece | Mechanism | After a reboot |
| --- | --- | --- |
| `tailscaled` | system service, enabled by the Tailscale package | up at boot |
| CLIProxyAPI, console | user units, `WantedBy=default.target` | up when your user session starts |
| T3 Code | `~/.config/autostart/t3code.desktop`, 10 s delay | up at login |
| `CLAUDE_CONFIG_DIR` | `~/.config/environment.d/claude-cliproxy.conf` | set on the next login |
| Tailscale Serve | T3 publishes it on every start (`tailscaleServeEnabled`) | up when T3 is |
| Claude logins | `~/.cli-proxy-api/*.json`, refreshed by the proxy | unchanged |

Nothing here starts before you log in to the desktop. For a primary box that must come back unattended, pick one:

- GDM autologin (`AutomaticLoginEnable=true` in `/etc/gdm3/custom.conf`). Only with full-disk encryption and a physically safe machine.
- `sudo loginctl enable-linger "$USER"` keeps the proxy and console up without a login, but T3 is still a desktop app and does not start. For a box with no login at all, run `t3 serve --tailscale-serve` from your own user unit instead of the desktop app; that unit is not shipped here.

`./check.sh` prints a WARN while linger is off.

## What never goes in git

OAuth files in `~/.cli-proxy-api/`, `keys.env`, the filled-in `config.yaml`, `cliproxy-console/data/settings.json`, `~/.claude-cliproxy/.credentials.json` (MCP tokens), and Tailscale login URLs. The templates in `config/` carry `REPLACE_WITH_*` placeholders and `install.sh` fills them on the machine.

Copy `~/.config/cli-proxy-api/keys.env` to a password manager after the first run. The proxy rewrites the management key in `config.yaml` to a bcrypt hash, so `keys.env` is the only place the plaintext lives besides the console and T3 settings. Do not copy `~/.cli-proxy-api` between machines; log in again.

## Layout

| Path | Role |
| --- | --- |
| `install.sh`, `check.sh` | Provision and verify. |
| `cliproxy-console/` | Quota board. Source of truth. |
| `config/cli-proxy-api.config.yaml` | Proxy config template (v8 spelling). |
| `config/cli-proxy-api.service`, `config/cliproxy-console.service` | User units. The console unit has an `@NODE@` placeholder. |
| `config/claude-cliproxy.settings.example.json` | The only Claude settings this stack adds. |
| `config/claude-cliproxy.environment.conf` | Login-session `CLAUDE_CONFIG_DIR`. `@CLAUDE_HOME@` is filled in by `install.sh`. |
| `config/t3-settings.snippet.json` | Keys merged into T3's `settings.json`. |
| `config/t3-desktop-settings.snippet.json` | Keys merged into T3's `desktop-settings.json`: loopback bind and Tailscale Serve. |
| `config/t3code-autostart.desktop` | Login autostart. |
| `AGENTS.md` | Contract for an agent doing this rebuild. |

The repo directory is where the console runs from, through the symlink. If you move the repo, run `./install.sh console` again.

## How it fits together

```text
other device -- Tailscale HTTPS :443 --> T3 on this machine, 127.0.0.1:3773
login session CLAUDE_CONFIG_DIR --> ~/.claude-cliproxy
T3 Claude provider --> ~/.claude-cliproxy --> 127.0.0.1:8317 CLIProxy
CLIProxy --> one sticky Claude OAuth account, failover on 429
console :8787 --> CLIProxy management API, loopback only
```

- `CLAUDE_CONFIG_DIR` is exported for the whole login, including a T3 that the updater restarts by executing its own binary. `providers.claudeAgent.homePath` does not feed that lookup. The drop-in is read at login, so a machine that just ran `install.sh` still needs a log out and back in. The same variable is what a terminal `claude` sees, so that command uses the isolated home too.
- T3 runs `tailscale serve` itself when `tailscaleServeEnabled` is true in `~/.t3/userdata/desktop-settings.json`. Do not also run `tailscale serve` by hand; T3 reports a conflict when another backend holds the port.
- `serverExposureMode: "local-only"` binds T3 to `127.0.0.1`. `network-accessible` binds `0.0.0.0` and exposes it on Wi-Fi and any other interface. Serve proxies to loopback, so it does not need that.
- T3 rewrites `desktop-settings.json` when it exits. Edit it only while T3 is closed; `install.sh t3` skips it, with a message, while T3 runs.
- `session-affinity: true` pins a thread and its prompt cache to one account for an hour, subagents included. `routing.retry.request-retry: 3` moves it to another account after 403, 408, 429, 500, 502, 503 or 504.
- `strategy: round-robin` spreads new sessions. The console can switch to `fill-first` and raise priority on the account whose 7-day window ends soonest.
- Codex stays on HTTP until its auth file has `websockets: true`; the console's routing action sets that.

Choices already in the T3 snippet: worktrees for new threads, auto-settle after 14 days, device support on, resume after a server update, resume a thread that hit a limit.

The console also reads local usage for tools already on the disk (Codex `~/.codex/state_5.sqlite`, OpenCode `~/.local/share/opencode/opencode.db`, Cursor's `state.vscdb` and `ai-code-tracking.db`). Missing files show an empty section.

## Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| Phone shows 502 or nothing | T3 is not running. Open it, or log in on the laptop. `./check.sh` shows which layer is down. |
| Console unit restarts in a loop | Its Node cannot import `node:sqlite`. `journalctl --user -u cliproxy-console`. Re-run `./install.sh node console`, or set `CLIPROXY_NODE`. After deleting or upgrading an nvm Node, re-run `./install.sh console`. |
| Console says `EADDRINUSE` | A hand-started copy still holds :8787. Stop it; the unit is the only supported way to run it. |
| `check.sh` fails the T3 loopback test | `desktop-settings.json` still says `network-accessible`. Quit T3, run `./install.sh t3`, start T3. |
| Serve refuses on first start | HTTPS is not enabled for the tailnet. Enable it from the admin URL, then restart T3. |
| A login callback fails | The PKCE verifier died with that process. Start a new `./install.sh login claude`, never reuse the URL. |
| T3: `Claude Agent SDK query failed` / session not found | The transcript is under `~/.claude-cliproxy` and this login has no `CLAUDE_CONFIG_DIR`. Run `./install.sh claude`, log out and back in, then retry the thread. |

## Upgrading the proxy

Run `./install.sh proxy`. It installs the newest release when the installed one differs. Read the v8 config notes before moving past 8.x, then run `npm test` in `cliproxy-console/` after any management-API change. `~/.cli-proxy-api` stays in place, so the logins survive the binary swap.

## Uninstall

```bash
systemctl --user disable --now cliproxy-console.service cli-proxy-api.service
rm ~/.config/systemd/user/{cli-proxy-api,cliproxy-console}.service ~/.config/autostart/t3code.desktop ~/.config/environment.d/claude-cliproxy.conf
rm ~/.local/share/cliproxy-console ~/.local/bin/cli-proxy-api
systemctl --user daemon-reload
# Optional, destroys logins and keys: ~/.cli-proxy-api ~/.config/cli-proxy-api ~/.claude-cliproxy
# T3: remove serverExposureMode, tailscaleServeEnabled and tailscaleServePort from ~/.t3/userdata/desktop-settings.json
#     and the providers.claudeAgent.homePath and usageLimitSources.cliproxy-local keys from settings.json
sudo tailscale down   # or: sudo apt remove tailscale
```
