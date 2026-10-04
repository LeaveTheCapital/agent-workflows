#!/usr/bin/env bash

set -euo pipefail

readonly SECRET_NAME="OPEN_API_KEY_SECRET"

usage() {
  cat <<'EOF'
Usage: setup.sh [OWNER/REPOSITORY]

Adds OPEN_API_KEY_SECRET to a GitHub repository. When no repository is given,
the repository for the current directory is used.

Set OPENAI_API_KEY before running to avoid an interactive prompt:
  OPENAI_API_KEY=sk-... /path/to/agent-workflows/scripts/setup.sh
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 2
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "error: GitHub CLI (gh) is required" >&2
  exit 1
fi

gh auth status >/dev/null

repository=${1:-}
if [[ -z $repository ]]; then
  repository=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
fi

api_key=${OPENAI_API_KEY:-}
if [[ -z $api_key ]]; then
  read -r -s -p "OpenAI API key: " api_key
  echo
fi

if [[ -z $api_key ]]; then
  echo "error: the OpenAI API key cannot be empty" >&2
  exit 1
fi

printf '%s' "$api_key" | gh secret set "$SECRET_NAME" --repo "$repository"
echo "Configured $SECRET_NAME for $repository."
