# CLIProxy console

Local board for a [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) instance. It shows the same three quota stages from Theo Browne’s Oct 2, 2026 video, [If you have a Claude sub, watch this](https://www.youtube.com/watch?v=D8PikZ1KhUo), and points Claude Code, OpenCode, and Cursor at one proxy.

Theo’s on-screen dashboard is his private fork. He says a fresh install will not look like it. The stock UI is [Cli-Proxy-API-Management-Center](https://github.com/router-for-me/Cli-Proxy-API-Management-Center) at `/management.html`. Other public tools cover parts of this (Quotio, Infinitus, CLIProxy Quota Tray, [quota-reset-router](https://github.com/WebDevCaptain/quota-reset-router)). None of them is his fork.

## Run

Normally it runs as the `cliproxy-console.service` user unit that `../install.sh console` installs. For development, stop the unit first, then:

```bash
npm test
npm start
```

Open http://127.0.0.1:8787. Until you connect, the Quota page is sample data.

## Connect your proxy

CLIProxyAPI v8 listens on port 8317. A minimal `config.yaml`:

```yaml
config-version: 8
server:
  host: "127.0.0.1"
  port: 8317
management:
  allow-remote: false
  secret-key: "replace-with-a-management-password"
access:
  api-keys:
    - "replace-with-the-key-clients-send"
routing:
  strategy: "round-robin"
  session-affinity: true
  session-affinity-ttl: "1h"
oauth:
  auth-dir: "~/.cli-proxy-api"
```

1. Start the proxy, then run `cli-proxy-api --claude-login` once for each Claude subscription. Each login writes another `claude-*.json` under `~/.cli-proxy-api`.
2. In this console, open Proxy, enter `http://127.0.0.1:8317` and the management key.

The console calls `/v8/management` and falls back to `/v0/management` when v8 is absent. The management key is written to `data/settings.json` with mode `0600` and is not printed back.

Docker, bound to localhost:

```bash
docker run --rm -p 127.0.0.1:8317:8317 \
  -v "$PWD/config.yaml:/CLIProxyAPI/config.yaml" \
  -v "$HOME/.cli-proxy-api:/root/.cli-proxy-api" \
  eceasy/cli-proxy-api:latest
```

## Routing

**Prefer soonest weekly reset** sets `routing.strategy` to `fill-first`, turns `session-affinity` on, and raises priority on the account whose 7-day window ends first. **Spread evenly** sets `round-robin` and leaves affinity on, so a thread that already started stays on its account.

Codex websocket is a flag on each Codex auth file (`websockets: true`). The video’s point is that Codex subscriptions stay on HTTP until that is turned on.

## Clients

The Clients page prints the base URL and the `access.api-keys` value for:

- Claude Code: `~/.claude/settings.json`, base URL with no `/v1`
- OpenCode: `opencode.json`, Anthropic base URL including `/v1`
- Cursor: Override OpenAI Base URL only. Cursor has no Anthropic base-URL setting, so Claude models inside Cursor stay on Anthropic.

That client key is separate from the management key and from the Claude OAuth files.
