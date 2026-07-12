# ---- Build Stage ----
FROM node:22-bookworm-slim AS build
WORKDIR /app

# Disable Husky git hooks and enable CI mode
ENV HUSKY=0
ENV CI=true

# Install pnpm
RUN corepack enable && corepack prepare pnpm@9.14.4 --activate

# Install git since some dependencies rely on git endpoints
RUN apt-get update && apt-get install -y --no-install-recommends git \
  && rm -rf /var/lib/apt/lists/*

# Copy package configurations and install ALL dependencies (including devDependencies)
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --no-frozen-lockfile --ignore-scripts

# Copy the rest of the application files
COPY . .

# Run Vite compiler using an exact memory size limit fit for the Free Tier container engine
RUN NODE_OPTIONS="--max-old-space-size=400" pnpm run build

# ---- Production Dependencies Stage ----
FROM build AS prod-deps
# Set production environment and prune devDependencies to shrink memory footprint
ENV NODE_ENV=production
RUN pnpm prune --prod --ignore-scripts

# ---- Production Runtime Stage ----
FROM node:22-bookworm-slim AS bolt-ai-production
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=5173
ENV HOST=0.0.0.0
ENV RUNNING_IN_DOCKER=true

# Install curl for Render healthchecks
RUN apt-get update && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/*

# Copy only the compiled output files and production modules
COPY --from=prod-deps /app/build ./build
COPY --from=prod-deps /app/package.json ./package.json
COPY --from=prod-deps /app/node_modules ./node_modules

EXPOSE 5173

# Healthcheck matching Render's deployment checks
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
  CMD curl -fsS http://localhost:5173/ || exit 1

# Start using native remix-serve from package.json
CMD ["pnpm", "run", "dockerstart"]
