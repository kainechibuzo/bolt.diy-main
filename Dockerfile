# ---- build stage ----
FROM node:22-bookworm-slim AS build
WORKDIR /app

# CI-friendly env and aggressive V8 memory tuning for 512MB RAM
ENV HUSKY=0
ENV CI=true
ENV NODE_ENV=production

# Use pnpm
RUN corepack enable && corepack prepare pnpm@9.14.4 --activate

# Ensure git is available for build scripts
RUN apt-get update && apt-get install -y --no-install-recommends git \
  && rm -rf /var/lib/apt/lists/*

# Accept (optional) build-time public URL for Remix/Vite
ARG VITE_PUBLIC_APP_URL
ENV VITE_PUBLIC_APP_URL=${VITE_PUBLIC_APP_URL}

# Copy package specs and install directly
COPY package.json ./
RUN pnpm install --no-frozen-lockfile

# Copy source files
COPY . .

# Build the Remix app with extreme garbage collection flags for 512MB limit
RUN NODE_OPTIONS="--max-old-space-size=384 --optimize-for-size --gc-interval=100" pnpm run build

# ---- production dependencies stage ----
FROM build AS prod-deps
RUN pnpm prune --prod --ignore-scripts

# ---- production stage ----
FROM prod-deps AS bolt-ai-production
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=5173
ENV HOST=0.0.0.0
ENV RUNNING_IN_DOCKER=true

# Install curl for healthchecks
RUN apt-get update && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/*

# Copy built files and pruned production dependencies
COPY --from=prod-deps /app/build /app/build
COPY --from=prod-deps /app/node_modules /app/node_modules
COPY --from=prod-deps /app/package.json /app/package.json

EXPOSE 5173

# Healthcheck for deployment platforms
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
  CMD curl -fsS http://localhost:5173/ || exit 1

# Start using native remix-serve from package.json
CMD ["pnpm", "run", "dockerstart"]
