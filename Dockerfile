# ---- base stage ----
FROM node:22-bookworm-slim AS base
WORKDIR /app

ENV HUSKY=0
ENV CI=true

RUN corepack enable && corepack prepare pnpm@9.14.4 --activate

# ---- production dependencies stage ----
COPY package.json ./
RUN pnpm install --no-frozen-lockfile --ignore-scripts

# Strip away devDependencies safely
ENV NODE_ENV=production
RUN pnpm prune --prod --ignore-scripts

# ---- final runtime stage ----
FROM node:22-bookworm-slim AS bolt-ai-production
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=5173
ENV HOST=0.0.0.0
ENV RUNNING_IN_DOCKER=true

RUN apt-get update && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/*

# Copy pre-built bundles from your repository and the lightweight production dependencies
COPY build ./build
COPY package.json ./
COPY --from=base /app/node_modules ./node_modules

EXPOSE 5173

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
  CMD curl -fsS http://localhost:5173/ || exit 1

CMD ["pnpm", "run", "dockerstart"]
