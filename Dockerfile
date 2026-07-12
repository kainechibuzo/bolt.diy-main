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
K
Kaine's workspace


k
My project

Production

bolt.diy-main

Web Service
bolt.diy-main
Docker
Free
Upgrade your instance

Connect

Manual Deploy
Service ID:
srv-d99c0hks728c73d1oo7g

kainechibuzo / bolt.diy-main
master
https://bolt-diy-main-2jko.onrender.com

Settings
General
Name
A unique name for your Web Service.
bolt.diy-main

Edit
Region
Your services in the same region can communicate over a private network.
Oregon (US West)
Instance Type
Free
0.1 CPU
512 MB
Update
Please enter your payment information to select an instance type with higher limits.
See remaining free usage, or learn about free service limits.
Build
Source
The build source for your Web Service
https://github.com/kainechibuzo/bolt.diy-main

Edit
Branch
The Git branch to build and deploy.
Branch
master

Edit
Root DirectoryOptional
If set, Render runs commands from this directory instead of the repository root. Additionally, code changes outside of this directory do not trigger an auto-deploy. Most commonly used with a monorepo.

Edit
Registry Credential
If your service pulls private Docker images from a registry, specify a credential that can access those images. Manage your credentials in Settings.
No credential

Edit
Dockerfile Path
The path to your service's Dockerfile, relative to the repo root. Defaults to ./Dockerfile.
./Dockerfile

Edit
Docker Build Context Directory
The path to your service's Docker build context, relative to the repo root. Defaults to the root.
$
.

Edit
Git Credentials
User providing the credentials to pull the repository.
kainechibuzo@gmail.com (you)
Use My Credentials
Build Filters
Include or ignore specific paths in your repo when determining whether to trigger an auto-deploy. Paths are relative to your repo's root directory. Learn more.

Edit
Included Paths
Changes that match these paths will trigger a new build.


Add Included Path
Ignored Paths
Changes that match these paths will not trigger a new build.


Add Ignored Path
Deploy
Docker Command
Optionally override your Dockerfile's CMD and ENTRYPOINT instructions with a different command to start your service.

Edit
Pre-Deploy CommandOptional
Render runs this command before the start command. Useful for database migrations and static asset uploads.
$

Edit
Auto-Deploy
By default, Render automatically deploys your service whenever you update its code or configuration. Disable to handle deploys manually. Learn more.
autoDeployTrigger

On Commit

Edit
Deploy Hook
Your private URL to trigger a deploy for this server. Remember to keep this a secret.
••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••



Regenerate hook
Custom Domains
You can point custom domains you own to this service.


Add Custom Domain
Render Subdomain
If enabled, your service remains reachable at its onrender.com subdomain in addition to all custom domains. Disable to serve exclusively from custom domains.


enabled
Your service is reachable at https://bolt-diy-main-2jko.onrender.com.
PR Previews
Pull Request Previews
Spin up temporary instances to test pull requests opened against the master branch of kainechibuzo/bolt.diy-main. Choose Automatic to preview all PRs, or Manual for only PRs with [render preview] in their title. Pull Request Previews create a new instance for just this service. Use Preview Environments to clone a group of services for every PR.
prPreviewsEnabled

Off

Edit
Networking
Edge Caching
Serve static content at the edge to improve performance and reduce service load. Learn more.
Paid
Edge Caching is only available for paid instances.
Upgrade
Notifications
Service Notifications
Set notifications to receive for your service. This setting will override your workspace's default settings.
notificationsToSend

Use workspace default (Only failure notifications)

Edit
Preview Environment Notifications
Configure notifications for preview environments and service previews.
previewNotificationsEnabled

Use account default (Disabled)

Edit
Health Checks
Health Check Path
Provide an HTTP endpoint path that Render messages periodically to monitor your service. Learn More.

Edit
Maintenance Mode


Paid
Maintenance mode is only available for paid instances.
Upgrade

Delete Web Service

Suspend Web Service
0 services selected:

Move

