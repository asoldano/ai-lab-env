#!/usr/bin/env bash
set -euo pipefail

TAG="${MCP_ATLASSIAN_TAG:-v0.21.0}"
REPO_DIR="/home/dev/.local/share/mcp-atlassian"

mkdir -p /home/dev/.local/share

if [ ! -d "${REPO_DIR}/.git" ]; then
  git clone https://github.com/sooperset/mcp-atlassian.git "${REPO_DIR}"
fi

cd "${REPO_DIR}"

git fetch --tags --force
git checkout "${TAG}"
git reset --hard "${TAG}"

# Deliberate choice: use Python 3.12 for this environment
uv python install 3.12

# Recreate the venv from the project's lockfile
rm -rf .venv
uv sync --frozen --python 3.12 --no-dev

# Re-register MCP server in Claude config
claude mcp remove jira --scope user 2>/dev/null || true
claude mcp add-json jira --scope user '{
  "command": "/home/dev/.local/share/mcp-atlassian/.venv/bin/mcp-atlassian",
  "env": {
    "TOOLSETS": "all"
  }
}'

echo "mcp-atlassian ${TAG} is ready in ${REPO_DIR}"
