# Development stage
FROM node:18-alpine

ARG NODE_VERSION=18

WORKDIR /app

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=3 --start-period=15s \
    CMD wget --quiet --tries=1 --spider http://localhost:3000 || exit 1

# Start development server with hot reload
# Note: npm install and npm run build must be executed manually before running the server
CMD ["npm", "run", "dev"]
