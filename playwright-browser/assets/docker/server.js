const { chromium } = require('playwright-core');

(async () => {
  const port = parseInt(process.env.PORT || '9222');
  const host = process.env.HOST || '0.0.0.0';
  
  console.log(`Starting Playwright server on ${host}:${port}...`);
  
  try {
    const launchOptions = {
      port: port,
      host: host,
      browser: 'chromium',
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu']
    };

    // Note: playwright-core respects PLAYWRIGHT_BROWSERS_PATH environment variable
    // which is set to /ms-playwright in the official Docker image.
    const browserServer = await chromium.launchServer(launchOptions);
    
    console.log('Browser server started successfully.');
    console.log('WS Endpoint:', browserServer.wsEndpoint());
    console.log('Remote Debugging URL:', `http://${host}:${port}`);

    // Handle shutdown
    const shutdown = async () => {
      console.log('Shutting down...');
      await browserServer.close();
      process.exit(0);
    };

    process.on('SIGINT', shutdown);
    process.on('SIGTERM', shutdown);

  } catch (err) {
    console.error('Failed to launch browser server:', err);
    process.exit(1);
  }
})();
