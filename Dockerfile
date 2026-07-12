# =============================================================================
# Runtime-only Dockerfile for Render Free Tier (512MB RAM)
#
# IMPORTANT: This image does NOT run `pnpm run build`. The Vite/Remix build is
# far too memory-hungry for a 512MB container and will OOM (exit code 134).
#
# Workflow:
#   1. Build locally (or in CI):   pnpm install && pnpm run build
#   2. Commit the `build/` directory (`.gitignore` allows it)
#   3. Render builds this image, which only installs prod deps and copies
#      the pre-compiled `build/` output into the runtime stage.
# =============================================================================

# ---- Production Dependencies Stage ----
FROM node:22-bookworm-slim AS prod-deps
WORKDIR /app

# Disable Husky git hooks and any lifecycle scripts during install
ENV HUSKY=0
ENV CI=true
ENV NODE_ENV=production

# Enable pnpm via corepack (no global npm install needed)
RUN corepack enable && corepack prepare pnpm@9.14.4 --activate

# Install ONLY runtime production dependencies.
# --ignore-scripts skips husky "prepare" and all postinstall hooks.
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --prod --no-frozen-lockfile --ignore-scripts \
  && pnpm store prune

# ---- Production Runtime Stage ----
FROM node:22-bookworm-slim AS bolt-ai-production
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=5173
ENV HOST=0.0.0.0
ENV RUNNING_IN_DOCKER=true
# Hard-cap the Node heap well under Render's 512MB ceiling so the OS,
# libuv threads, and native buffers still have headroom.
ENV NODE_OPTIONS="--max-old-space-size=384"

# curl is required for Render healthchecks
RUN apt-get update && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/*

# Copy production node_modules from the deps stage
COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=prod-deps /app/package.json ./package.json

# Copy the PRE-BUILT output directly from the build context.
# `.dockerignore` explicitly allows the `build/` directory through.
COPY build ./build

EXPOSE 5173

# Healthcheck matching Render's deployment checks
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
  CMD curl -fsS http://localhost:5173/ || exit 1

# Start remix-serve directly via its binary — no pnpm/npm process wrapper,
# which saves ~30-50MB of RSS at runtime.
CMD ["node", "./node_modules/@remix-run/serve/dist/cli.js", "./build/server/index.js"]
