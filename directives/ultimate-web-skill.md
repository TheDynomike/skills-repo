# Adaptive Web Skill — Agent Build Directive (v7)

## What you are doing

You are building yourself a persistent, containerized adaptive web interaction
stack. This single file is your complete directive. Execute it top to bottom.

You will:
1. Probe the environment and make decisions
2. Write all required files to disk using the heredoc blocks below
3. Build and start the Docker stack
4. Verify all services are healthy
5. Merge the MCP config and append the skill definition to your guardrails

One file in. A running stack out. Do not ask for confirmation — probe, decide, act.
Surface to the human only when a decision genuinely cannot be made from available
information.

---

## Step 0: Environment Probe

Run all of the following. Record every result.

```bash
# Docker
which docker 2>/dev/null && docker --version || echo "DOCKER_MISSING"
docker info 2>/dev/null | grep "Server Version" || echo "DOCKER_DAEMON_DOWN"
docker compose version 2>/dev/null || docker-compose --version 2>/dev/null || echo "COMPOSE_MISSING"

# Ports
for port in 8080 8888 9222 9223 9224 9225 5900 6080; do
  lsof -i :$port 2>/dev/null && echo "PORT_${port}_BUSY" || echo "PORT_${port}_FREE"
done

# Existing containers
docker ps -a --format "{{.Names}} {{.Status}}" 2>/dev/null \
  | grep -E "searxng|cdp-mcp|playwright-mcp" || echo "NO_EXISTING_CONTAINERS"

# Existing MCP configs
for f in ~/.cursor/mcp.json \
          ~/.config/cline/mcp.json \
          ~/.config/claude/claude_desktop_config.json; do
  [ -f "$f" ] && echo "MCP_CONFIG_EXISTS: $f"
done

# OS and arch
uname -s && uname -m

# Working directory
echo "WORKDIR=$(pwd)"
```

---

## Step 1: Decisions

### 1a. Docker
```
docker present AND daemon running AND compose present → PROCEED
docker present AND daemon DOWN
  → try: sudo systemctl start docker
  → re-probe after 10s
  → if still down: SURFACE "Docker daemon not running. Start Docker and re-run."
DOCKER_MISSING
  → SURFACE "Docker not installed. Install from https://docs.docker.com/engine/install/ and re-run."
COMPOSE_MISSING
  → SURFACE "docker compose unavailable. Install Docker Compose and re-run."
```

### 1b. Working directory
```
Create ./adaptive-web-skill/ relative to the directory containing this directive.
All files in Steps 2-4 are written there.
mkdir -p ./adaptive-web-skill/searxng
```

### 1c. Port assignment
```
SearXNG:        prefer 8080, fallback 8888 if PORT_8080_BUSY
CDP MCP:        prefer 9222, fallback 9224 if PORT_9222_BUSY
Playwright MCP: prefer 9223, fallback 9225 if PORT_9223_BUSY
VNC:            prefer 5900 (on-demand only — conflict is acceptable)
noVNC:          prefer 6080 (on-demand only — conflict is acceptable)

Record resolved ports. Substitute them wherever you see
${SEARXNG_PORT}, ${CDP_PORT}, ${PLAYWRIGHT_PORT} in files below.
```

### 1d. Existing containers
```
Container "searxng" running      → skip searxng steps, health check only
Container "cdp-mcp" running      → skip cdp steps, health check only
Container "playwright-mcp" running → skip playwright steps, health check only
```

### 1e. MCP config target
```
~/.cursor/mcp.json exists                          → TARGET=~/.cursor/mcp.json
~/.config/cline/mcp.json exists                    → TARGET=~/.config/cline/mcp.json
~/.config/claude/claude_desktop_config.json exists → TARGET=~/.config/claude/claude_desktop_config.json
none found                                         → TARGET=~/.cursor/mcp.json (create it)
```

### 1f. Secret key
```bash
# Generate once. Record as SEARXNG_SECRET.
SEARXNG_SECRET=$(openssl rand -hex 32)
```

---

## Step 2: Write docker-compose.yml

```bash
cat > ./adaptive-web-skill/docker-compose.yml << 'EOF'
version: "3.9"

networks:
  webskill:
    driver: bridge

volumes:
  playwright-sessions:

services:

  searxng:
    image: searxng/searxng:latest
    container_name: searxng
    restart: unless-stopped
    networks: [webskill]
    ports:
      - "127.0.0.1:${SEARXNG_PORT:-8080}:8080"
    volumes:
      - ./searxng/settings.yml:/etc/searxng/settings.yml:ro
    environment:
      - SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- 'http://localhost:8080/search?q=test&format=json' | python3 -c 'import sys,json; json.load(sys.stdin)' && echo ok"]
      interval: 20s
      timeout: 8s
      retries: 5
      start_period: 25s

  cdp-mcp:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        - SERVICE=cdp
    image: adaptive-web-cdp:latest
    container_name: cdp-mcp
    restart: unless-stopped
    networks: [webskill]
    ports:
      - "127.0.0.1:${CDP_PORT:-9222}:9222"
    environment:
      - DISPLAY=:99
      - SERVICE=cdp
    shm_size: "2gb"
    cap_add: [SYS_ADMIN]
    security_opt: [seccomp=unconfined]
    healthcheck:
      test: ["CMD", "curl", "-sf", "http://localhost:9222/json/version"]
      interval: 20s
      timeout: 8s
      retries: 5
      start_period: 20s

  playwright-mcp:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        - SERVICE=playwright
    image: adaptive-web-playwright:latest
    container_name: playwright-mcp
    restart: unless-stopped
    networks: [webskill]
    ports:
      - "127.0.0.1:${PLAYWRIGHT_PORT:-9223}:9223"
      - "127.0.0.1:5900:5900"
      - "127.0.0.1:6080:6080"
    volumes:
      - playwright-sessions:/sessions
    environment:
      - DISPLAY=:99
      - SESSIONS_DIR=/sessions
      - SERVICE=playwright
    shm_size: "2gb"
    cap_add: [SYS_ADMIN]
    security_opt: [seccomp=unconfined]
    healthcheck:
      test: ["CMD-SHELL", "nc -z localhost 9223 && echo ok || exit 1"]
      interval: 20s
      timeout: 8s
      retries: 5
      start_period: 25s
EOF
```

---

## Step 3: Write searxng/settings.yml

Substitute the actual value of `$SEARXNG_SECRET` from Step 1f before writing.

```bash
cat > ./adaptive-web-skill/searxng/settings.yml << EOF
use_default_settings: true

general:
  debug: false
  instance_name: "adaptive-web-skill"
  enable_metrics: false

search:
  safe_search: 0
  default_lang: "en"
  formats:
    - html
    - json

server:
  port: 8080
  bind_address: "0.0.0.0"
  secret_key: "${SEARXNG_SECRET}"
  limiter: false
  image_proxy: false
  http_protocol_version: "1.1"

ui:
  static_use_hash: true
  default_theme: simple

outgoing:
  request_timeout: 10.0
  max_request_timeout: 30.0
  pool_connections: 100
  pool_maxsize: 20
  enable_http2: true

engines:
  - name: google
    engine: google
    shortcut: g
    disabled: false
    weight: 2
  - name: bing
    engine: bing
    shortcut: b
    disabled: false
    weight: 1
  - name: duckduckgo
    engine: duckduckgo
    shortcut: d
    disabled: false
    weight: 1
  - name: wikipedia
    engine: wikipedia
    shortcut: w
    disabled: false
    weight: 1
  - name: google scholar
    engine: google_scholar
    shortcut: gs
    disabled: false
    weight: 1
  - name: github
    engine: github
    shortcut: gh
    disabled: false
    weight: 1
  - name: stackoverflow
    engine: stackoverflow
    shortcut: so
    disabled: false
    weight: 1
  - name: arxiv
    engine: arxiv
    shortcut: arx
    disabled: false
    weight: 1

enabled_plugins:
  - Hash_plugin
  - Search_on_category_select
  - Tracker_url_remover
EOF
```

---

## Step 4: Write Dockerfile (shared, ARG SERVICE selects cdp vs playwright)

```bash
cat > ./adaptive-web-skill/Dockerfile << 'EOF'
ARG SERVICE=playwright

# ── CDP stage ────────────────────────────────────────────────────────────────
FROM node:20-slim AS cdp

RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium xvfb dbus dbus-x11 curl ca-certificates \
    fonts-liberation fonts-noto fonts-noto-color-emoji \
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 \
    libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 \
    libxrandr2 libgbm1 libasound2 libpango-1.0-0 libpangocairo-1.0-0 \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g chrome-devtools-mcp

RUN groupadd -r appuser && useradd -r -g appuser -m appuser
USER appuser
WORKDIR /home/appuser

COPY --chown=appuser:appuser entrypoint.sh /home/appuser/entrypoint.sh
RUN chmod +x /home/appuser/entrypoint.sh

EXPOSE 9222
ENTRYPOINT ["/home/appuser/entrypoint.sh"]

# ── Playwright stage ─────────────────────────────────────────────────────────
FROM mcr.microsoft.com/playwright:v1.44.0-jammy AS playwright

RUN apt-get update && apt-get install -y --no-install-recommends \
    x11vnc novnc websockify openssl netcat-openbsd \
    curl wget openssh-client procps python3-pip \
  && rm -rf /var/lib/apt/lists/*

# bore: zero-config tunnel for CAPTCHA bridge public URL
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
      x86_64)  ASSET="bore-x86_64-unknown-linux-musl.tar.gz" ;; \
      aarch64) ASSET="bore-aarch64-unknown-linux-musl.tar.gz" ;; \
      *) echo "bore unsupported on $ARCH — ssh fallback will be used" && exit 0 ;; \
    esac && \
    curl -fsSL "https://github.com/ekzhang/bore/releases/latest/download/${ASSET}" \
      -o /tmp/bore.tar.gz \
    && tar xz -C /usr/local/bin/ -f /tmp/bore.tar.gz \
    && chmod +x /usr/local/bin/bore \
    && rm /tmp/bore.tar.gz \
    || echo "bore install failed — ssh fallback will be used"

RUN npm install -g @playwright/mcp

RUN pip3 install --break-system-packages playwright-stealth fake-useragent

RUN mkdir -p /sessions && chmod 777 /sessions

COPY entrypoint.sh /entrypoint.sh
COPY captcha-bridge.sh /captcha-bridge.sh
RUN chmod +x /entrypoint.sh /captcha-bridge.sh

EXPOSE 9223 5900 6080
ENTRYPOINT ["/entrypoint.sh"]
EOF
```

---

## Step 5: Write entrypoint.sh (handles both services via $SERVICE env var)

```bash
cat > ./adaptive-web-skill/entrypoint.sh << 'EOF'
#!/bin/bash
set -e

# ── Virtual display (both services need Xvfb) ────────────────────────────────
Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset &
export DISPLAY=:99
sleep 1

SERVICE="${SERVICE:-playwright}"

if [ "$SERVICE" = "cdp" ]; then
  # ── CDP: launch chrome-devtools-mcp ────────────────────────────────────────
  CHROME_BIN=$(which chromium 2>/dev/null \
    || which chromium-browser 2>/dev/null \
    || which google-chrome 2>/dev/null)

  if [ -z "$CHROME_BIN" ]; then
    echo "[cdp] ERROR: no Chromium binary found" >&2
    exit 1
  fi

  echo "[cdp] Chromium: $CHROME_BIN"
  echo "[cdp] Starting chrome-devtools-mcp on port 9222..."

  exec chrome-devtools-mcp \
    --chrome-path "$CHROME_BIN" \
    --port 9222 \
    --chrome-flags "--no-sandbox \
      --disable-dev-shm-usage \
      --disable-setuid-sandbox \
      --disable-gpu \
      --disable-infobars \
      --disable-extensions \
      --disable-blink-features=AutomationControlled \
      --window-size=1920,1080 \
      --user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"

elif [ "$SERVICE" = "playwright" ]; then
  # ── Playwright: init sessions then launch playwright-mcp ───────────────────
  SESSIONS_DIR="${SESSIONS_DIR:-/sessions}"
  mkdir -p "$SESSIONS_DIR"
  [ -s "$SESSIONS_DIR/default.json" ] || echo '{}' > "$SESSIONS_DIR/default.json"

  echo "[playwright] Sessions: $(ls $SESSIONS_DIR/*.json 2>/dev/null | xargs -I{} basename {} .json | tr '\n' ' ')"
  echo "[playwright] Starting playwright-mcp on port 9223..."

  exec playwright-mcp \
    --browser chromium \
    --headless \
    --port 9223 \
    --storage-state "$SESSIONS_DIR/default.json" \
    --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36" \
    --launch-options '{"args":["--disable-blink-features=AutomationControlled","--no-sandbox","--disable-dev-shm-usage","--disable-setuid-sandbox","--disable-gpu","--disable-infobars","--disable-extensions","--window-size=1920,1080"]}'

else
  echo "ERROR: unknown SERVICE=$SERVICE. Set to 'cdp' or 'playwright'." >&2
  exit 1
fi
EOF
chmod +x ./adaptive-web-skill/entrypoint.sh
```

---

## Step 6: Write captcha-bridge.sh

```bash
cat > ./adaptive-web-skill/captcha-bridge.sh << 'EOF'
#!/bin/bash
# CAPTCHA Bridge — called by agent when challenge detected (Class H)
# Starts x11vnc + noVNC + public tunnel, prints BRIDGE_URL, then blocks.
# Kill with SIGTERM to tear down.
# Usage: /captcha-bridge.sh [novnc_port] [vnc_port]

NOVNC_PORT="${1:-6080}"
VNC_PORT="${2:-5900}"
VNC_PASS=$(openssl rand -base64 6 | tr -d '=+/')

cleanup() {
  echo "[bridge] BRIDGE_TORN_DOWN"
  kill "$X11VNC_PID" "$NOVNC_PID" "$TUNNEL_PID" 2>/dev/null
  rm -f /tmp/bridge_url.txt /tmp/bridge_password.txt
  exit 0
}
trap cleanup SIGTERM SIGINT EXIT

# x11vnc
x11vnc -display :99 -rfbport "$VNC_PORT" -passwd "$VNC_PASS" \
  -forever -noxdamage -quiet -bg 2>/tmp/x11vnc.log
X11VNC_PID=$(pgrep -n x11vnc)
sleep 1

# noVNC
NOVNC_WEB=$(find /usr/share/novnc /usr/local/share/novnc 2>/dev/null \
  -name "vnc.html" | head -1 | xargs dirname || echo "/usr/share/novnc")
websockify --web "$NOVNC_WEB" "$NOVNC_PORT" "localhost:$VNC_PORT" \
  > /tmp/novnc.log 2>&1 &
NOVNC_PID=$!
sleep 1

PUBLIC_URL=""

# Attempt 1: bore
if which bore > /dev/null 2>&1; then
  bore local "$NOVNC_PORT" --to bore.pub > /tmp/tunnel.log 2>&1 &
  TUNNEL_PID=$!
  sleep 4
  BORE_PORT=$(grep -oP 'bore\.pub:\K[0-9]+' /tmp/tunnel.log | head -1)
  if [ -n "$BORE_PORT" ]; then
    PUBLIC_URL="http://bore.pub:${BORE_PORT}/vnc.html?password=${VNC_PASS}&autoconnect=true&resize=scale"
  else
    kill "$TUNNEL_PID" 2>/dev/null; TUNNEL_PID=""
  fi
fi

# Attempt 2: localhost.run (ssh)
if [ -z "$PUBLIC_URL" ] && which ssh > /dev/null 2>&1; then
  ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=20 \
    -o ConnectTimeout=10 \
    -R "80:localhost:${NOVNC_PORT}" nokey@localhost.run \
    > /tmp/tunnel.log 2>&1 &
  TUNNEL_PID=$!
  sleep 5
  LR_URL=$(grep -oP 'https://\S+\.lhr\.life' /tmp/tunnel.log | head -1)
  if [ -n "$LR_URL" ]; then
    PUBLIC_URL="${LR_URL}/vnc.html?password=${VNC_PASS}&autoconnect=true&resize=scale"
  else
    kill "$TUNNEL_PID" 2>/dev/null; TUNNEL_PID=""
  fi
fi

# Fallback: LAN only
if [ -z "$PUBLIC_URL" ]; then
  PUBLIC_URL="http://YOUR_HOST_LAN_IP:${NOVNC_PORT}/vnc.html?password=${VNC_PASS}&autoconnect=true&resize=scale"
  echo "BRIDGE_TUNNEL_UNAVAILABLE — replace YOUR_HOST_LAN_IP with host machine IP"
fi

echo "BRIDGE_URL=${PUBLIC_URL}"
echo "BRIDGE_PASSWORD=${VNC_PASS}"
echo "${PUBLIC_URL}" > /tmp/bridge_url.txt
echo "${VNC_PASS}" > /tmp/bridge_password.txt

wait "$X11VNC_PID"
EOF
chmod +x ./adaptive-web-skill/captcha-bridge.sh
```

---

## Step 7: Build and Start

```bash
cd ./adaptive-web-skill

docker compose up -d --build

# Watch logs for 30s for startup errors
timeout 30 docker compose logs -f || true
```

If `docker compose up` exits non-zero, classify the error:

```
"port is already allocated"
  → re-resolve conflicting port, rewrite docker-compose.yml, retry

"no space left on device"
  → SURFACE "Insufficient disk space (~3GB needed). Free space and re-run."

"failed to solve" / build error
  → docker compose build --no-cache [service]
  → if still failing: output full build log verbatim and halt

"Cannot connect to the Docker daemon"
  → SURFACE "Docker daemon stopped during build. Restart Docker and re-run."

anything else
  → output full error verbatim and halt
```

---

## Step 8: Health Verification

```bash
echo "Waiting for services to initialize..."
sleep 15

# SearXNG
SEARXNG_CHECK=$(curl -sf --max-time 8 \
  "http://localhost:${SEARXNG_PORT:-8080}/search?q=test&format=json" \
  | python3 -c "import sys,json; json.load(sys.stdin); print('SEARXNG_OK')" \
  2>/dev/null || echo "SEARXNG_FAIL")

# CDP
CDP_CHECK=$(curl -sf --max-time 8 \
  "http://localhost:${CDP_PORT:-9222}/json/version" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'Browser' in d; print('CDP_OK')" \
  2>/dev/null || echo "CDP_FAIL")

# Playwright
PW_CHECK=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{}}}' \
  | nc -q 2 localhost ${PLAYWRIGHT_PORT:-9223} 2>/dev/null \
  | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'result' in d; print('PLAYWRIGHT_OK')" \
  2>/dev/null || echo "PLAYWRIGHT_FAIL")

echo "$SEARXNG_CHECK"
echo "$CDP_CHECK"
echo "$PW_CHECK"
```

On any FAIL:
```
→ docker compose logs [service] --tail=30
→ if timeout: wait 20s and retry check once
→ if still failing: output logs verbatim and halt
→ E2E_SEARCH_FAIL only: log as WARNING, do not halt (engines need warm-up)
```

---

## Step 9: Merge MCP Config

```bash
python3 - << PYEOF
import json, os

target = os.path.expanduser("${TARGET_MCP_CONFIG}")
os.makedirs(os.path.dirname(target), exist_ok=True)

try:
    with open(target) as f:
        cfg = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    cfg = {}

# Backup
import shutil, time
if os.path.exists(target):
    shutil.copy(target, f"{target}.bak.{int(time.time())}")

cfg.setdefault("mcpServers", {})
cfg["mcpServers"]["adaptive-web-searxng"] = {
    "env": {"SEARXNG_URL": "http://localhost:${SEARXNG_PORT:-8080}"}
}
cfg["mcpServers"]["adaptive-web-cdp"] = {
    "url": "http://localhost:${CDP_PORT:-9222}"
}
cfg["mcpServers"]["adaptive-web-playwright"] = {
    "url": "http://localhost:${PLAYWRIGHT_PORT:-9223}"
}

with open(target, "w") as f:
    json.dump(cfg, f, indent=2)

print("MCP_CONFIG_MERGED_OK:", target)
PYEOF
```

---

## Step 10: Completion Report

```
╔══════════════════════════════════════════════════════════════════╗
║         ADAPTIVE WEB SKILL — STACK OPERATIONAL                   ║
╠══════════════════════╦═══════════════════════════════════════════╣
║ SearXNG              ║ http://localhost:${SEARXNG_PORT}          ║
║ CDP MCP              ║ http://localhost:${CDP_PORT}              ║
║ Playwright MCP       ║ http://localhost:${PLAYWRIGHT_PORT}       ║
║ CAPTCHA bridge       ║ on-demand via docker exec playwright-mcp  ║
║                      ║   /captcha-bridge.sh                      ║
╠══════════════════════╩═══════════════════════════════════════════╣
║ MCP config: ${TARGET_MCP_CONFIG}                                 ║
║ Sessions:   docker volume: playwright-sessions                   ║
║ Files:      ./adaptive-web-skill/                                ║
╠══════════════════════════════════════════════════════════════════╣
║ Start:  docker compose -f adaptive-web-skill/docker-compose.yml up -d   ║
║ Stop:   docker compose -f adaptive-web-skill/docker-compose.yml down    ║
║ Logs:   docker compose -f adaptive-web-skill/docker-compose.yml logs -f ║
╚══════════════════════════════════════════════════════════════════╝
```

Append the Skill Definition below to your guardrails file, then halt.

---

## Idempotency

Safe to re-run at any time:
- Step 0 probes are read-only
- Step 1f generates a new secret key only if settings.yml is absent
- Steps 2-6 overwrite files (safe — content is deterministic except secret key)
- Step 7 `docker compose up -d --build` skips unchanged layers
- Step 8 health checks are read-only
- Step 9 backs up MCP config before every merge
- Re-run after partial failure picks up from first failed step

---
---

# Skill Definition

*(Append everything below this line to your guardrails file)*

---

## Skill: Adaptive Web

### What this skill is

You have a three-service containerized web stack:

- **adaptive-web-searxng** — meta-search across Google, Bing, DuckDuckGo,
  Wikipedia, GitHub, arXiv simultaneously; returns ranked JSON
- **adaptive-web-cdp** — raw Chrome DevTools Protocol extraction;
  fastest for static pages, no JS rendering overhead
- **adaptive-web-playwright** — full Chromium automation with session
  persistence, stealth patches, UA rotation, form interaction, and
  CAPTCHA bridge

Start: `docker compose -f adaptive-web-skill/docker-compose.yml up -d`
Stop:  `docker compose -f adaptive-web-skill/docker-compose.yml down`

You do not commit to one tool. Classify the task, use the minimum capable
tool, observe the result, escalate only when the result is insufficient.
**The ladder only goes up. Never retry the same class twice per task.**

---

### Stack Status Check

Before any web task:

```bash
docker compose -f ./adaptive-web-skill/docker-compose.yml ps --format json \
  | python3 -c "
import sys, json
lines = [l for l in sys.stdin if l.strip()]
services = [json.loads(l) for l in lines]
running = [s['Service'] for s in services if s.get('State') == 'running']
required = ['searxng', 'cdp-mcp', 'playwright-mcp']
missing = [r for r in required if r not in running]
print('STACK_PARTIAL: ' + str(missing) if missing else 'STACK_OK')
"
```

If STACK_PARTIAL:
```bash
docker compose -f ./adaptive-web-skill/docker-compose.yml up -d
```

---

### Initial Classification

```
Need a URL first?
  YES → Search (Steps 1-3) then classify the result URL
  NO  → classify known URL:

    Login required?
      YES + session exists → Class 2
      YES + no session     → Class 2 with auth-gate pause
      NO  → JS-rendered (SPA)?
              Uncertain        → Class 1, escalate to Class 3 if empty
              Confirmed SPA    → Class 3
            Requires typing/clicking/uploading/submitting?
              YES              → Class 4
            Streaming/async response?
              YES              → Class 5
            Export automation script?
              YES              → Class 6
            None of above      → Class 1

CAPTCHA detected at any point → Class H (out-of-band, immediate)
```

---

### Step 1 — Query Construction

Strip filler. Expand pronouns. Append year if recency implied.
Decompose multi-part requests into separate queries.

---

### Step 2 — Search

```
GET http://localhost:${SEARXNG_PORT}/search?q=QUERY&format=json&engines=google,bing,duckduckgo
```

Empty result: wait 2s, retry once rephrased. Still empty: report
"Search unavailable" and stop. Never hallucinate results.

---

### Step 3 — Ranking

Prefer: .gov/.edu/official sources > snippet relevance > recency.
Avoid: content farms, SEO aggregators. Select top 3.

---

### Browser Identity

All Playwright sessions:
- UA: `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36`
- Viewport: 1920×1080 · locale: en-US · timezone: America/New_York
- Headers: Accept-Language, Sec-CH-UA, Sec-Fetch-* matching Chrome desktop
- Stealth: navigator.webdriver suppressed; plugins/languages/hardwareConcurrency spoofed
- UA fixed for duration of task. Never switch mid-session.

---

### Class 1 — Static Extraction
**Tool:** adaptive-web-cdp
**When:** No auth, server-rendered content

```
1. navigate(url)
2. Wait: readyState === 'complete' (8s timeout)
3. get_text("article, main, [role='main'], body")
4. Truncate to 4000 tokens
```

Escalate to Class 3 if: body < 100 chars / bot-challenge / "JS required" / skeleton

---

### Class 3 — SPA / JS-Rendered
**Tool:** adaptive-web-playwright
**When:** JS-rendered (React/Vue/Angular)

```
1. navigate(url)
2. wait_for_selector("article, main, [role='main']", timeout: 10000)
   fallback: wait_for_selector("body", timeout: 5000)
3. evaluate(document.body.innerText)
4. Truncate to 4000 tokens
```

Escalate to Class 2 if: redirect to /login /signin /auth · login form · 401/403
Escalate to Class 4 if: content behind "Load more" / tab / modal

---

### Class 2 — Session-Gated
**Tool:** adaptive-web-playwright + storageState
**When:** Site requires login

Check session first:
```bash
docker exec playwright-mcp python3 -c "
import json
with open('/sessions/SITENAME.json') as f:
    s = json.load(f)
assert s.get('cookies') or s.get('origins'), 'SESSION_EMPTY'
print('SESSION_OK')
"
```

If SESSION_EMPTY or absent, pause:
> "This site requires a saved session. Capture one with:
> `docker exec -it playwright-mcp npx playwright open --save-storage /sessions/SITENAME.json https://SITE`
> Log in manually then Ctrl+C. Re-run your task after."

```
1. Launch with --storage-state /sessions/SITENAME.json
2. navigate(url)
3. wait_for_selector("[content]", timeout: 10000)
4. Verify not on login page (check URL + form presence)
   If still on login: SESSION_EXPIRED — pause for re-auth
5. Extract, truncate to 4000 tokens
```

Escalate to Class 4 if: authenticated but content behind interaction

---

### Class 4 — Form Interaction
**Tool:** adaptive-web-playwright
**When:** Typing, clicking, uploading, submitting

```
1. navigate(url) [+ storageState if auth required]
2. wait_for_selector([target], timeout: 10000)
3. Text: click([sel]) → fill([sel], [value])
   React: evaluate("el => { el.value='...'; el.dispatchEvent(new Event('input',{bubbles:true})) }")
4. File: set_input_files([sel], [path])
5. click([submit])
6. wait_for_selector([response container], timeout: 15000)
```

Navigation budget: 3 transitions total. Stop and report if exceeded.
Escalate to Class 5 if: response growing / stop button visible

---

### Class 5 — Streaming / Async
**Tool:** adaptive-web-playwright
**When:** Response arrives progressively

Stop polling when ANY signal observed:
- Stop/cancel button disappears
- Copy/regenerate button appears
- Content length delta = 0 across two polls 3s apart
- `aria-busy="false"` or `data-state="complete"` appears

```
Poll: record length → wait 3s → re-read → if delta>0 repeat
      delta==0 twice consecutively → COMPLETE
      max 120s → extract with "may be incomplete" note
```

Extract: `evaluate("document.querySelector('[container]').innerText")`
Truncate to 8000 tokens.

---

### Class 6 — Script Generation
**When:** User asks to export/save an automation script

```python
import asyncio, datetime
from playwright.async_api import async_playwright
from playwright_stealth import stealth_async

try:
    from fake_useragent import UserAgent
    UA = UserAgent().chrome
except Exception:
    POOL = [
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
    ]
    UA = POOL[datetime.datetime.now().minute % len(POOL)]

async def run(storage_state=None):
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True, args=[
            "--disable-blink-features=AutomationControlled", "--no-sandbox",
            "--disable-dev-shm-usage", "--disable-gpu"])
        ctx = await browser.new_context(
            user_agent=UA, viewport={"width":1920,"height":1080},
            locale="en-US", timezone_id="America/New_York",
            extra_http_headers={
                "Accept-Language":"en-US,en;q=0.9",
                "Sec-CH-UA":'"Chromium";v="125","Google Chrome";v="125","Not-A.Brand";v="99"',
                "Sec-CH-UA-Mobile":"?0","Sec-CH-UA-Platform":'"Windows"'},
            **({ "storage_state": storage_state } if storage_state else {}))
        page = await ctx.new_page()
        await stealth_async(page)
        await page.add_init_script("""
            Object.defineProperty(navigator,'webdriver',{get:()=>undefined});
            Object.defineProperty(navigator,'plugins',{get:()=>[1,2,3,4,5]});
            Object.defineProperty(navigator,'languages',{get:()=>['en-US','en']});
            Object.defineProperty(navigator,'hardwareConcurrency',
                {get:()=>[2,4,8,16][Math.floor(Math.random()*4)]});""")
        try:
            pass  # automation steps here
        except Exception as e:
            await page.screenshot(path="error.png")
            open("error.html","w").write(await page.content())
            raise
        finally:
            await browser.close()

asyncio.run(run(storage_state="path/to/session.json"))
```

---

### Class H — CAPTCHA Bridge (out-of-band)

Triggers from ANY class when detected:
- URL/body contains: `recaptcha` `hcaptcha` `cf-challenge` `verify you are human`
  `select all images` `i'm not a robot`
- `cf-mitigated: challenge` response header
- `wait_for_selector` timeout + screenshot shows challenge UI
- Stealth applied but challenge persists after 5s

**H1: Stop and screenshot**
```bash
# Stop all navigation immediately
docker exec playwright-mcp sh -c 'screenshot to /tmp/captcha_detected.png'
```

**H2: Start bridge**
```bash
docker exec -d playwright-mcp /captcha-bridge.sh 6080 5900
sleep 4
BRIDGE_URL=$(docker exec playwright-mcp cat /tmp/bridge_url.txt 2>/dev/null)
VNC_PASS=$(docker exec playwright-mcp cat /tmp/bridge_password.txt 2>/dev/null)
```

**H3: Notify user**
```
⚠️  HUMAN INPUT REQUIRED — CAPTCHA DETECTED

Challenge: [describe: e.g. "reCAPTCHA image grid on accounts.google.com"]

Open this in your browser to interact with the live browser session:
👉 [BRIDGE_URL]
Password (if prompted): [VNC_PASS]

Complete the challenge, then type: CAPTCHA_DONE

Paused. No action will be taken until you respond. Session open 10 minutes.
```

**H4: Poll for resolution**
```python
# Every 5s for up to 600s:
# - check body text for CAPTCHA signals
# - check URL for challenge paths
# On clear: print CAPTCHA_CLEARED, kill bridge, resume triggering class
# On timeout: screenshot, preserve session, report CAPTCHA_TIMEOUT
```

**H5: Tear down**
```bash
docker exec playwright-mcp pkill -f captcha-bridge.sh 2>/dev/null || true
```

**H-Fallback (bridge fails):**
```
⚠️  CAPTCHA DETECTED — bridge unavailable

Open [URL] in your browser, complete the challenge, then type:
RESUME [url-you-land-on]

I will navigate directly there and continue.
```

---

### Escalation Ladder

```
INITIAL CLASSIFICATION
        ↓
CLASS 1 — cdp-mcp, raw static extract
        ↓ empty / bot-wall / JS-required
CLASS 3 — playwright-mcp, SPA wait
        ↓ login redirect / 401 / form detected
CLASS 2 — playwright-mcp, storageState auth
        ↓ content behind interaction
CLASS 4 — playwright-mcp, form/click/upload
        ↓ response still growing / streaming
CLASS 5 — playwright-mcp, poll to completion
        ↓ complete / export requested
CLASS 6 — python script, stealth + UA
        ↓ exhausted / budget exceeded
REPORT  — what was tried, what each returned, why each escalated

══ OUT-OF-BAND ══════════════════════════════
CLASS H ← any class → CAPTCHA detected
        → CAPTCHA_DONE: resume triggering class
        → CAPTCHA_TIMEOUT: halt, preserve session, report
```

Rules:
- Each class attempted at most once per task
- Ladder only goes up
- Navigation budget: 3 transitions shared across all classes
- Class H does not consume a ladder slot
- Class 2 always pauses for session confirmation before proceeding

---

### Synthesis and Citation

- Answer the user's question in the first sentence
- Support with extracted content; note conflicts explicitly
- Paraphrase — never reproduce long verbatim passages
- Label training knowledge: `(from training, not extracted)`
- If extraction failed: say so, state what was retrieved, offer alternatives

```
Sources:
[1] Title — domain — URL — [C1/C2/C3/C4/C5/C6/CH]
[2] ...
```

---

### Degraded Mode

```
All services running     → full ladder (C1–C6 + CH)
searxng down             → skip search; user must provide URL
cdp-mcp down             → skip C1; start at C3
playwright-mcp down      → C1 only; C2–C6 + CH unavailable
CAPTCHA bridge fails     → CH degrades to text fallback
all down                 → report stack offline; run docker compose up -d
```

Never silently degrade. Always report which mode is active.

---

### Safety

- Never open more than 1 Chromium instance per container simultaneously
- Never guess, fabricate, or brute-force credentials
- Never follow links beyond the 3-transition navigation budget
- Never extract more than 8000 tokens from a single page
- PDF pages: snippet only — note "PDF — snippet only"
- CDP unresponsive 10s: `docker restart cdp-mcp`
- Playwright unresponsive 10s: `docker restart playwright-mcp`
- CAPTCHA: invoke Class H immediately — never attempt programmatic bypass
