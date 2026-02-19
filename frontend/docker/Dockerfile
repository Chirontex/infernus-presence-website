# Build stage
FROM node:18-alpine AS builder

ARG NODE_VERSION=18

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci --prefer-offline --no-audit

# Copy source code
COPY . .

# Build application (generates .nuxt dist in development mode, or static build in production)
RUN npm run build || true

# Development stage
FROM node:18-alpine

ARG NODE_VERSION=18

WORKDIR /app

# Install dependencies
RUN npm install -g npm@latest

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci --prefer-offline --no-audit

# Copy source code
COPY . .

# Copy build output from builder stage (if any)
COPY --from=builder /app/.nuxt /app/.nuxt

# Create non-root user
RUN addgroup -g 1000 node && adduser -D -u 1000 -G node node

# Fix permissions
RUN chown -R node:node /app

# Switch to node user
USER node

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=3 --start-period=15s \
    CMD wget --quiet --tries=1 --spider http://localhost:3000 || exit 1

# Start development server with hot reload
CMD ["npm", "run", "dev"]
