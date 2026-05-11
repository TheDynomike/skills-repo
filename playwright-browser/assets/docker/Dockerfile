FROM mcr.microsoft.com/playwright:v1.49.1-jammy

# Run as root to allow port binding
USER root

WORKDIR /app

COPY package.json .

# Install dependencies
RUN npm install

COPY server.js .

# Environment variables for flexibility
ENV PORT=9222
ENV HOST=0.0.0.0

# Remote debugging port
EXPOSE 9222

CMD ["node", "server.js"]
