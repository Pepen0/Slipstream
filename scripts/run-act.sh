#!/usr/bin/env bash
set -euo pipefail

# Load .env safely (supports spaces in values)
set -a
source .env
set +a

# Ensure tools
command -v jq >/dev/null 2>&1 || { echo "jq is required. On mac: brew install jq"; exit 1; }

# Build event payload from env
mkdir -p .github/tests
jq -n \
  --arg action "opened" \
  --arg title  "$ISSUE_TITLE" \
  --arg owner  "$REPO_OWNER" \
  --arg name   "$REPO_NAME" \
  --arg full   "$REPO_FULL_NAME" \
  --arg defbr  "$DEFAULT_BRANCH" \
  --arg sender "$SENDER_LOGIN" \
  --argjson number "$ISSUE_NUMBER" \
  '{
    action: $action,
    issue: { number: $number, title: $title },
    repository: {
      full_name: $full,
      default_branch: $defbr,
      name: $name,
      owner: { login: $owner }
    },
    sender: { login: $sender }
  }' > .github/tests/issue-opened.json

# Run act with your settings
act issues \
  -e .github/tests/issue-opened.json \
  -W .github/workflows/auto-branch.yml \
  -s GITHUB_TOKEN="$GITHUB_TOKEN" \
  -P "ubuntu-latest=$UBUNTU_IMAGE" \
  --container-architecture "$ARCH"

# Cleanup
rm .github/tests/issue-opened.json