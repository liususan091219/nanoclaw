#!/usr/bin/env bash
# a script to automatically stop the ongoing nanoclaw service, sync from sonichi/nanoclaw, and restart the nanoclaw agent.
set -euo pipefail

# 1. Stop the nanoclaw service
echo "Stopping nanoclaw service..."
systemctl --user stop nanoclaw 2>/dev/null && echo "  Service stopped." || echo "  Service not running, continuing..."

# 2. Stop lingering nanoclaw containers
echo "Stopping lingering nanoclaw containers..."
CONTAINERS=$(docker ps --filter "name=nanoclaw-" --format "{{.Names}}" 2>/dev/null || true)

if [ -z "$CONTAINERS" ]; then
  echo "  No running nanoclaw containers found."
else
  for name in $CONTAINERS; do
    echo "  Stopping container: $name"
    docker stop "$name" 2>/dev/null || true
  done
fi

# 3. Pull upstream (sonichi/nanoclaw) into local branch 'test'
echo "Pulling upstream (sonichi/nanoclaw) into local branch 'test'..."
git remote set-url upstream https://github.com/sonichi/nanoclaw.git 2>/dev/null || git remote add upstream https://github.com/sonichi/nanoclaw.git
git fetch upstream
git checkout -B main upstream/fix/linux-runtime

# 4. Copy .env from external config directory
echo "Copying .env from ~/nanoclaw_external..."
cp ~/nanoclaw_external/.env /home/xliu127/nanoclaw/.env

# 5. Build and restart the service
echo "Building..."
cd /home/xliu127/nanoclaw
npm run build

echo "Starting nanoclaw service..."
systemctl --user start nanoclaw

echo "Done."
