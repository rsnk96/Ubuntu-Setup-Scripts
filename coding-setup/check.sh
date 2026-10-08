#!/usr/bin/env bash
# Health check for the agent workstation. Exits non-zero if any FAIL line prints.
# WARN lines are things that work today but will not survive a reboot or logout.
# Secrets are never put on a command line or printed.
set -uo pipefail

KEYS_FILE="$HOME/.config/cli-proxy-api/keys.env"
PROXY_CONFIG="$HOME/.config/cli-proxy-api/config.yaml"
CONSOLE_UNIT="$HOME/.config/systemd/user/cliproxy-console.service"
T3_USERDATA="$HOME/.t3/userdata"
T3_PORT=3773
failures=0

pass() { printf 'PASS  %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*"; failures=$((failures + 1)); }
check() { local label="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$label"; else fail "$label"; fi; }

# True if every listener on the port is bound to loopback.
loopback_only() {
  local listeners
  listeners="$(ss -Htln "sport = :$1" | awk '{print $4}')"
  [ -n "$listeners" ] && ! grep -qvE '^(127\.0\.0\.1|\[::1\]):' <<<"$listeners"
}

http_code() { curl -s -m 5 -o /dev/null -w '%{http_code}' "$1" 2>/dev/null; }

json_get() {
  python3 - "$1" "$2" <<'PY' 2>/dev/null
import json, sys
value = json.load(open(sys.argv[1]))
for part in sys.argv[2].split("."):
    value = value[part]
print(str(value).lower())
PY
}

echo "-- services (survive reboot)"
for unit in cli-proxy-api.service cliproxy-console.service; do
  check "$unit enabled" systemctl --user is-enabled "$unit"
  check "$unit active" systemctl --user is-active "$unit"
done
check "tailscaled enabled" systemctl is-enabled tailscaled
if [ -f "$HOME/.config/autostart/t3code.desktop" ]; then pass "T3 autostart entry present"; else fail "T3 autostart entry missing (T3 will not start after a reboot)"; fi
if [ "$(loginctl show-user "$USER" -p Linger --value 2>/dev/null)" = "yes" ]; then
  pass "linger on (user services run without a login)"
else
  warn "linger off: nothing starts after a reboot until you log in to the desktop"
fi

echo "-- console runtime"
console_node="$(sed -n 's/^ExecStart=\(.*\) server.mjs$/\1/p' "$CONSOLE_UNIT" 2>/dev/null)"
if [ -n "$console_node" ] && [ -x "$console_node" ]; then
  check "console Node $console_node can import node:sqlite" "$console_node" -e "import('node:sqlite')"
else
  fail "console unit has no usable Node (${console_node:-no unit installed})"
fi
if [ -L "$HOME/.local/share/cliproxy-console" ] && [ -f "$HOME/.local/share/cliproxy-console/server.mjs" ]; then
  pass "console symlink resolves"
else
  fail "console symlink missing or dangling"
fi

echo "-- exposure"
check "proxy :8317 is loopback only" loopback_only 8317
check "console :8787 is loopback only" loopback_only 8787
if loopback_only "$T3_PORT"; then
  pass "T3 :$T3_PORT is loopback only"
else
  fail "T3 :$T3_PORT is reachable from the network; set serverExposureMode to local-only in $T3_USERDATA/desktop-settings.json, quit T3 and start it again"
fi

echo "-- endpoints"
[ "$(http_code http://127.0.0.1:8787/)" = 200 ] && pass "console answers" || fail "console does not answer on :8787"
[ "$(http_code http://127.0.0.1:$T3_PORT/)" = 200 ] && pass "T3 answers" || fail "T3 does not answer on :$T3_PORT (is the app running?)"
if [ -f "$KEYS_FILE" ]; then
  . "$KEYS_FILE"
  code="$(curl -s -m 10 -o /dev/null -w '%{http_code}' --config <(printf 'header = "Authorization: Bearer %s"\n' "$CLIENT_API_KEY") http://127.0.0.1:8317/v1/models)"
  [ "$code" = 200 ] && pass "proxy accepts the client key" || fail "proxy /v1/models returned $code with the client key"
else
  [ "$(http_code http://127.0.0.1:8317/v1/models)" = 401 ] && pass "proxy listening (no keys.env here, so the client key was not tried)" || fail "proxy not answering on :8317"
fi

echo "-- agent CLIs"
for tool in claude cursor-agent opencode2; do
  if PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH" command -v "$tool" >/dev/null; then pass "$tool installed"; else fail "$tool missing: run ./install.sh agents"; fi
done

echo "-- accounts"
auth_count="$(find "$HOME/.cli-proxy-api" -maxdepth 1 -name 'claude-*.json' 2>/dev/null | wc -l)"
if [ "$auth_count" -gt 0 ]; then pass "$auth_count Claude login(s) on disk"; else fail "no Claude login: run ./install.sh login claude"; fi

echo "-- config"
if [ -f "$PROXY_CONFIG" ]; then
  [ "$(stat -c %a "$PROXY_CONFIG")" = 600 ] && pass "proxy config mode 600" || fail "proxy config is not mode 600"
  grep -q '^request-retry:' "$PROXY_CONFIG" && warn "proxy config uses the legacy top-level request-retry; move it under routing.retry"
else
  fail "proxy config missing"
fi
[ "$(json_get "$HOME/.claude-cliproxy/settings.json" env.ANTHROPIC_BASE_URL)" = "http://127.0.0.1:8317" ] && pass "Claude home points at the proxy" || fail "Claude home does not point at the proxy"
session_env="$HOME/.config/environment.d/claude-cliproxy.conf"
if [ -f "$session_env" ] && grep -qx "CLAUDE_CONFIG_DIR=$HOME/.claude-cliproxy" "$session_env"; then
  pass "session CLAUDE_CONFIG_DIR points at the isolated Claude home"
else
  fail "session CLAUDE_CONFIG_DIR is not $HOME/.claude-cliproxy (run ./install.sh claude)"
fi
live_claude_home="$(systemctl --user show-environment 2>/dev/null | sed -n 's/^CLAUDE_CONFIG_DIR=//p')"
if [ "$live_claude_home" = "$HOME/.claude-cliproxy" ]; then
  pass "this login exports CLAUDE_CONFIG_DIR"
else
  warn "this login does not export CLAUDE_CONFIG_DIR yet; log out and back in"
fi
[ "$(json_get "$T3_USERDATA/settings.json" providers.claudeAgent.homePath)" = "$HOME/.claude-cliproxy" ] && pass "T3 uses the Claude home" || fail "T3 settings do not point at $HOME/.claude-cliproxy"
[ "$(json_get "$T3_USERDATA/desktop-settings.json" tailscaleServeEnabled)" = true ] && pass "T3 Tailscale Serve enabled" || fail "T3 tailscaleServeEnabled is not true"

echo "-- tailscale"
if command -v tailscale >/dev/null; then
  state="$(tailscale status --json 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin).get("BackendState",""))' 2>/dev/null)"
  [ "$state" = Running ] && pass "tailscale running" || fail "tailscale state is '${state:-unknown}'"
  serve="$(tailscale serve status 2>&1)"
  grep -q "127.0.0.1:$T3_PORT" <<<"$serve" && pass "Serve publishes T3 (tailnet only)" || fail "Serve is not publishing 127.0.0.1:$T3_PORT"
  ! grep -q 'Funnel on' <<<"$serve" && pass "Funnel off" || fail "Funnel is on"
else
  fail "tailscale not installed"
fi

echo
if [ "$failures" -eq 0 ]; then echo "all checks passed"; else echo "$failures check(s) failed"; fi
exit $((failures > 0))
