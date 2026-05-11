---
name: playwright-browser
description: Deploy and connect to a headless Playwright browser in a Docker container or locally on Linux. Use this skill for web automation, scraping, or testing.
---

# Playwright Browser Skill

This skill provides a headless Playwright browser environment, optimized for remote connection via CDP (Chrome DevTools Protocol).

## Deployment

### Option 1: Docker (Recommended)

1.  **Build the image**:
    ```bash
    # From the skill directory
    docker build -t playwright-remote assets/docker
    ```

2.  **Run the container**:
    ```bash
    # Run on a specific network if needed (e.g., --network my-network)
    docker run -d \
      --name playwright-browser \
      -p 9222:9222 \
      playwright-remote
    ```

3.  **Map local domains** (Optional):
    If the browser needs to access services via custom domains:
    ```bash
    docker exec -u root playwright-browser sh -c "echo '<IP_ADDRESS> <DOMAIN_NAME>' >> /etc/hosts"
    ```

### Option 2: Local Linux

1.  **Install dependencies**:
    ```bash
    cd assets/docker
    npm install
    npx playwright install chromium
    npx playwright install-deps chromium
    ```

2.  **Start the server**:
    ```bash
    PORT=9222 node server.js
    ```

## Connecting

The browser exposes a WebSocket endpoint for CDP. Discover it using:
`curl -s http://localhost:9222/json/version`

### Example Connection (Node.js)

```javascript
const { chromium } = require('playwright-core');

async function run() {
  // 1. Get the WebSocket Debugger URL
  const response = await fetch('http://localhost:9222/json/version');
  const data = await response.json();
  const wsUrl = data.webSocketDebuggerUrl;

  // 2. Connect to the remote browser
  const browser = await chromium.connectOverCDP(wsUrl);
  const context = await browser.newContext({ ignoreHTTPSErrors: true });
  const page = await context.newPage();

  // 3. Use the page
  await page.goto('https://example.com');
  console.log(await page.title());

  await browser.close();
}

run();
```

## Troubleshooting

- **Connection Refused**: Ensure the container is running and port 9222 is mapped correctly.
- **SSL Errors**: Use `ignoreHTTPSErrors: true` when connecting to sites with self-signed certificates.
- **DNS/Routing**: If running in Docker, ensure the container can reach your target servers. Use `--network` or `/etc/hosts` mappings.

## Maintenance

- **Stop/Remove**: `docker stop playwright-browser && docker rm playwright-browser`
- **Logs**: `docker logs playwright-browser`
