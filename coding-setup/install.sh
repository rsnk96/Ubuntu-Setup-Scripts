#!/usr/bin/env bash
# Builds the agent workstation described in README.md. Idempotent: re-running a
# phase converges on the same state and never regenerates existing secrets.
#
#   ./install.sh                 every phase, in order
#   ./install.sh console t3      only the named phases
#   ./install.sh login claude    OAuth login for one subscription (interactive)
#
# Phases: node agents proxy claude console t3 autostart tailscale check
# Opt-in (not run by default): power
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_DIR="$HERE/config"

BIN="$HOME/.local/bin/cli-proxy-api"
PROXY_CONFIG_DIR="$HOME/.config/cli-proxy-api"
PROXY_CONFIG="$PROXY_CONFIG_DIR/config.yaml"
KEYS_FILE="$PROXY_CONFIG_DIR/keys.env"
UNIT_DIR="$HOME/.config/systemd/user"
CLAUDE_HOME="$HOME/.claude-cliproxy"
CONSOLE_LINK="$HOME/.local/share/cliproxy-console"
T3_APP="/opt/T3 Code (Nightly)/t3code"
T3_USERDATA="$HOME/.t3/userdata"
NODE=""

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -ne 0 ] || die "run as your own user; the script calls sudo where it needs it"
[ -f /etc/os-release ] && . /etc/os-release
[ "${ID:-}" = "ubuntu" ] || die "Ubuntu only (found ${ID:-unknown})"

for tool in curl python3 openssl sha256sum tar sed; do
  command -v "$tool" >/dev/null || die "$tool is missing (the parent 1-BasicSetUp.sh installs the basics)"
done

node_ok() { "$1" -e "import('node:sqlite')" >/dev/null 2>&1; }

find_node() {
  local candidate
  for candidate in "${CLIPROXY_NODE:-}" /usr/bin/node "$(command -v node || true)"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ] && node_ok "$candidate"; then
      NODE="$candidate"
      return 0
    fi
  done
  return 1
}

phase_node() {
  log "Node with node:sqlite"
  if ! find_node; then
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
    sudo apt-get install -y nodejs
    find_node || die "no Node on this machine can import node:sqlite; set CLIPROXY_NODE to one that can"
  fi
  echo "using $NODE ($("$NODE" -v))"
}

need_node() { [ -n "$NODE" ] || find_node || phase_node; }

load_keys() {
  [ -f "$KEYS_FILE" ] || die "$KEYS_FILE is missing. Run the proxy phase on a new machine. On a machine built before install.sh existed, create it with MANAGEMENT_KEY='...' and CLIENT_API_KEY='...' (mode 0600)."
  set -a
  . "$KEYS_FILE"
  set +a
}

systemd_install_unit() {
  local name="$1" node_path="${2:-}"
  mkdir -p "$UNIT_DIR"
  if [ -n "$node_path" ]; then
    sed "s|@NODE@|$node_path|g" "$CONFIG_DIR/$name" >"$UNIT_DIR/$name"
  else
    cp "$CONFIG_DIR/$name" "$UNIT_DIR/$name"
  fi
  systemctl --user daemon-reload
}

# Prints "<version> <url> <sha256>" for the newest CLIProxyAPI release of this
# architecture. The sha256 is the digest GitHub computed for the uploaded asset.
latest_cliproxy() {
  python3 - "$1" <<'PY'
import json, sys, urllib.request

arch = sys.argv[1]
with urllib.request.urlopen("https://api.github.com/repos/router-for-me/CLIProxyAPI/releases/latest") as response:
    release = json.load(response)
version = release["tag_name"].lstrip("v")
name = f"CLIProxyAPI_{version}_linux_{arch}.tar.gz"
for asset in release["assets"]:
    if asset["name"] == name:
        digest = (asset.get("digest") or "").removeprefix("sha256:")
        if not digest:
            sys.exit(f"GitHub published no sha256 for {name}")
        print(version, asset["browser_download_url"], digest)
        sys.exit(0)
sys.exit(f"no {name} in release {release['tag_name']}")
PY
}

phase_proxy() {
  log "CLIProxyAPI (newest release)"
  local arch latest url sha installed found
  case "$(uname -m)" in
    x86_64) arch=amd64 ;;
    aarch64 | arm64) arch=aarch64 ;;
    *) die "unsupported architecture $(uname -m)" ;;
  esac
  found="$(latest_cliproxy "$arch")" || die "could not read the newest CLIProxyAPI release from GitHub"
  read -r latest url sha <<<"$found"
  installed="$("$BIN" --version 2>&1 | sed -n 's/^CLIProxyAPI Version: \([0-9.]*\).*/\1/p' | head -1 || true)"
  if [ "$installed" != "$latest" ]; then
    echo "installing CLIProxyAPI $latest (installed: ${installed:-none})"
    local tmp archive="CLIProxyAPI_${latest}_linux_${arch}.tar.gz"
    tmp="$(mktemp -d)"
    curl -fL -o "$tmp/$archive" "$url"
    echo "$sha  $tmp/$archive" | sha256sum -c -
    tar -xzf "$tmp/$archive" -C "$tmp"
    mkdir -p "$(dirname "$BIN")"
    install -m 0755 "$tmp/cli-proxy-api" "$BIN"
    rm -r "$tmp"
  else
    echo "CLIProxyAPI $installed is already the newest release"
  fi

  mkdir -p "$PROXY_CONFIG_DIR"
  chmod 700 "$PROXY_CONFIG_DIR"
  if [ ! -f "$KEYS_FILE" ]; then
    [ ! -f "$PROXY_CONFIG" ] || die "$PROXY_CONFIG exists but $KEYS_FILE does not; refusing to mint keys that would not match it"
    (umask 077 && printf "MANAGEMENT_KEY='%s'\nCLIENT_API_KEY='%s'\n" "$(openssl rand -hex 32)" "$(openssl rand -hex 32)" >"$KEYS_FILE")
    echo "generated $KEYS_FILE (mode 0600). Copy it to your password manager."
  fi
  load_keys

  if [ ! -f "$PROXY_CONFIG" ]; then
    python3 - "$CONFIG_DIR/cli-proxy-api.config.yaml" "$PROXY_CONFIG" <<'PY'
import os, sys
src, dest = sys.argv[1:3]
text = open(src).read()
text = text.replace("REPLACE_WITH_MANAGEMENT_KEY", os.environ["MANAGEMENT_KEY"])
text = text.replace("REPLACE_WITH_CLIENT_API_KEY", os.environ["CLIENT_API_KEY"])
fd = os.open(dest, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
with os.fdopen(fd, "w") as handle:
    handle.write(text)
PY
  fi

  systemd_install_unit cli-proxy-api.service
  systemctl --user enable cli-proxy-api.service
  systemctl --user restart cli-proxy-api.service
}

install_session_claude_home() {
  mkdir -p "$HOME/.config/environment.d"
  sed "s|@CLAUDE_HOME@|$CLAUDE_HOME|g" "$CONFIG_DIR/claude-cliproxy.environment.conf" \
    >"$HOME/.config/environment.d/claude-cliproxy.conf"
  echo "wrote ~/.config/environment.d/claude-cliproxy.conf (takes effect on the next login)"
}

phase_agents() {
  log "Agent CLIs: Claude Code, Cursor Agent, OpenCode 2"
  export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"
  command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash
  command -v cursor-agent >/dev/null || curl -fsS https://cursor.com/install | bash
  if ! command -v opencode2 >/dev/null; then
    command -v unzip >/dev/null || sudo apt-get install -y unzip
    command -v bun >/dev/null || curl -fsSL https://bun.sh/install | bash
    bun add -g @opencode/cli
  fi
  local tool
  for tool in claude cursor-agent opencode2; do
    command -v "$tool" >/dev/null || die "$tool is not on PATH after its installer ran"
  done
}

phase_claude() {
  log "Isolated Claude home $CLAUDE_HOME"
  install_session_claude_home
  [ ! -f "$KEYS_FILE" ] || load_keys
  python3 - "$CONFIG_DIR/claude-cliproxy.settings.example.json" <<'PY'
import json, os, sys
from pathlib import Path

example = json.loads(Path(sys.argv[1]).read_text())
dest = Path.home() / ".claude-cliproxy" / "settings.json"
dest.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
current = json.loads(dest.read_text()) if dest.exists() else {}
env = current.setdefault("env", {})
for key, value in example["env"].items():
    if key == "ANTHROPIC_AUTH_TOKEN":
        token = os.environ.get("CLIENT_API_KEY") or env.get(key)
        if not token or token.startswith("REPLACE_"):
            sys.exit("no client API key: run the proxy phase first")
        env[key] = token
    else:
        env[key] = value
dest.write_text(json.dumps(current, indent=2) + "\n")
dest.chmod(0o600)
PY
  local item
  for item in CLAUDE.md skills plugins hooks; do
    if [ -e "$HOME/.claude/$item" ] && { [ ! -e "$CLAUDE_HOME/$item" ] || [ -L "$CLAUDE_HOME/$item" ]; }; then
      ln -sfn "$HOME/.claude/$item" "$CLAUDE_HOME/$item"
    fi
  done
}

phase_console() {
  log "Quota console"
  need_node
  (cd "$HERE/cliproxy-console" && "$NODE" --test >/dev/null) || die "console tests failed"
  if [ -e "$CONSOLE_LINK" ] && [ ! -L "$CONSOLE_LINK" ]; then
    die "$CONSOLE_LINK exists and is not a symlink; move it away first"
  fi
  mkdir -p "$(dirname "$CONSOLE_LINK")"
  ln -sfn "$HERE/cliproxy-console" "$CONSOLE_LINK"

  local data="$HERE/cliproxy-console/data"
  if [ ! -f "$data/settings.json" ] && [ -f "$KEYS_FILE" ]; then
    load_keys
    mkdir -p "$data"
    chmod 700 "$data"
    python3 - "$data/settings.json" <<'PY'
import json, os, sys
dest = sys.argv[1]
body = {
    "baseUrl": "http://127.0.0.1:8317",
    "managementKey": os.environ["MANAGEMENT_KEY"],
    "clientApiKey": os.environ["CLIENT_API_KEY"],
}
fd = os.open(dest, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
with os.fdopen(fd, "w") as handle:
    json.dump(body, handle, indent=2)
PY
  fi

  systemd_install_unit cliproxy-console.service "$NODE"
  systemctl --user enable cliproxy-console.service
  systemctl --user restart cliproxy-console.service
}

t3_running() { pgrep -x t3code >/dev/null 2>&1; }

merge_json() {
  # merge_json <dest> <snippet> [KEY=VALUE ...]; nested dicts merge, anything else is replaced.
  python3 - "$@" <<'PY'
import json, os, sys
from pathlib import Path

dest, snippet, *overrides = sys.argv[1:]
path = Path(dest)
current = json.loads(path.read_text()) if path.exists() else {}
incoming = json.loads(Path(snippet).read_text())

def merge(into, src):
    for key, value in src.items():
        if isinstance(value, dict) and isinstance(into.get(key), dict):
            merge(into[key], value)
        else:
            into[key] = value

merge(current, incoming)
for item in overrides:
    dotted, value = item.split("=", 1)
    if value.startswith("env:"):
        value = os.environ[value[4:]]
    node = current
    *parents, leaf = dotted.split(".")
    for part in parents:
        node = node.setdefault(part, {})
    node[leaf] = value
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(current, indent=2) + "\n")
path.chmod(0o600)
PY
}

# T3 Nightly ships only as a .deb attached to the GitHub releases page
# (https://github.com/pingdotgg/t3code/releases), next to preview builds that
# install to a different directory. Only the newest -nightly. asset is taken. Set T3_DEB to a .deb you already downloaded to skip this.
install_t3_deb() {
  local deb="${T3_DEB:-}" tmp name url digest
  if [ -z "$deb" ]; then
    tmp="$(mktemp -d)"
    found="$(python3 - "$(dpkg --print-architecture)" <<'PY'
import json, sys, urllib.request

arch = sys.argv[1]
with urllib.request.urlopen("https://api.github.com/repos/pingdotgg/t3code/releases?per_page=30") as response:
    releases = json.load(response)
for release in releases:
    if release["draft"]:
        continue
    for asset in release["assets"]:
        if "-nightly." in asset["name"] and asset["name"].endswith(f"-{arch}.deb"):
            print(asset["name"], asset["browser_download_url"], (asset.get("digest") or "").removeprefix("sha256:"))
            sys.exit(0)
sys.exit(f"no nightly {arch} .deb on the newest releases")
PY
    )" || die "could not find a T3 Nightly .deb on GitHub; download one from the releases page and set T3_DEB"
    read -r name url digest <<<"$found"
    [ -n "$digest" ] || die "GitHub published no sha256 for $name; download it from the releases page and set T3_DEB"
    curl -fL -o "$tmp/$name" "$url"
    echo "$digest  $tmp/$name" | sha256sum -c -
    deb="$tmp/$name"
  fi
  sudo apt-get install -y "$deb"
}

phase_t3() {
  log "T3 Code Nightly"
  if [ ! -x "$T3_APP" ]; then
    install_t3_deb
  fi
  [ -x "$T3_APP" ] || die "T3 Code is not at $T3_APP after install"
  install_session_claude_home

  load_keys
  if t3_running; then
    echo "T3 is running. settings.json is merged now, but desktop-settings.json is rewritten by the app on exit, so quit T3 and re-run this phase to apply the Serve and exposure settings."
  else
    merge_json "$T3_USERDATA/desktop-settings.json" "$CONFIG_DIR/t3-desktop-settings.snippet.json"
  fi
  merge_json "$T3_USERDATA/settings.json" "$CONFIG_DIR/t3-settings.snippet.json" \
    "providers.claudeAgent.homePath=$CLAUDE_HOME" \
    "usageLimitSources.cliproxy-local.managementKey=env:MANAGEMENT_KEY"
}

phase_autostart() {
  log "Start T3 at login"
  mkdir -p "$HOME/.config/autostart"
  cp "$CONFIG_DIR/t3code-autostart.desktop" "$HOME/.config/autostart/t3code.desktop"
}

phase_tailscale() {
  log "Tailscale"
  command -v tailscale >/dev/null || curl -fsSL https://tailscale.com/install.sh | sh
  local state
  state="$(tailscale status --json 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin).get("BackendState",""))' 2>/dev/null || true)"
  if [ "$state" != "Running" ]; then
    echo "Join this new device to your tailnet: approve it in the browser with the account your other devices use. The URL is a secret."
    sudo tailscale up --operator="$USER" --hostname="$(hostname)" --accept-routes=false
  fi
  cat <<EOF

Remove the older devices from your tailnet. Open https://login.tailscale.com/admin/machines,
delete the laptop this one replaces and any stale entry named "$(hostname)". While an old entry
holds the name, this device can be renamed "$(hostname)-1" and the Serve URL on your other devices changes.
If that already happened, delete the old entry and run: sudo tailscale set --hostname="$(hostname)"
EOF
  echo "T3 publishes itself with Tailscale Serve once it starts. If the first start reports that HTTPS is disabled, enable it for the tailnet in the admin console and restart T3."
}

phase_power() {
  log "Always-on power policy (closed lid and AC power never suspend)"
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' ||
    echo "gsettings unavailable here; set 'When plugged in: never suspend' in Settings > Power"
  sudo install -d /etc/systemd/logind.conf.d
  printf '[Login]\nHandleLidSwitch=ignore\nHandleLidSwitchExternalPower=ignore\nHandleLidSwitchDocked=ignore\n' |
    sudo tee /etc/systemd/logind.conf.d/10-coding-box.conf >/dev/null
  sudo systemctl kill -s HUP systemd-logind
}

phase_login() {
  local provider="${1:-claude}"
  case "$provider" in
    claude | codex) ;;
    *) die "login takes claude or codex" ;;
  esac
  "$BIN" -config "$PROXY_CONFIG" "-$provider-login"
}

phase_check() { "$HERE/check.sh"; }

main() {
  local phases=("$@")
  [ "${#phases[@]}" -gt 0 ] || phases=(node agents proxy claude console t3 autostart tailscale check)
  if [ "${phases[0]}" = "login" ]; then
    phase_login "${phases[1]:-claude}"
    return
  fi
  local phase
  for phase in "${phases[@]}"; do
    case "$phase" in
      node | agents | proxy | claude | console | t3 | autostart | tailscale | power | check) "phase_$phase" ;;
      *) die "unknown phase '$phase'" ;;
    esac
  done
  cat <<'EOF'

Next, once per subscription (browser on this machine):
  ./install.sh login claude
Then open T3 from the application menu, or log out and in to see it start on its own.
EOF
}

main "$@"
