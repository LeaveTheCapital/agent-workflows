#!/usr/bin/env bash

set -euo pipefail

readonly SECRET_NAME="OPEN_API_KEY_SECRET"
readonly AGENT_TOKEN_SECRET_NAME="AGENT_GITHUB_TOKEN"
readonly LABEL_NAME="agent-pr"
readonly WORKFLOW_NAME="issue-to-pr.yml"
readonly LEGACY_WORKFLOW_NAME="codex-issue.yml"

usage() {
  cat <<'EOF'
Usage: setup.sh [TARGET_DIRECTORY]

Installs the Codex issue workflow and adds OPEN_API_KEY_SECRET to the target
GitHub repository. TARGET_DIRECTORY defaults to the current directory and must
be inside a Git repository with a GitHub remote.

Set OPENAI_API_KEY before running to avoid an interactive prompt:
  OPENAI_API_KEY=sk-... /path/to/agent-workflows/scripts/setup.sh

Optionally set AGENT_GITHUB_TOKEN to a GitHub App or personal access token so
pull requests created by the agent trigger other workflows without approval:
  AGENT_GITHUB_TOKEN="$(gh auth token)" OPENAI_API_KEY=sk-... \
    /path/to/agent-workflows/scripts/setup.sh
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

target_directory=${1:-.}
if ! target_root=$(git -C "$target_directory" rev-parse --show-toplevel 2>/dev/null); then
  echo "error: $target_directory is not inside a Git repository" >&2
  exit 1
fi

repository=$(cd -- "$target_root" && gh repo view --json nameWithOwner --jq .nameWithOwner)

script_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_workflow="$script_directory/../templates/$WORKFLOW_NAME"
target_workflow="$target_root/.github/workflows/$WORKFLOW_NAME"
legacy_target_workflow="$target_root/.github/workflows/$LEGACY_WORKFLOW_NAME"

if [[ -e $legacy_target_workflow ]]; then
  echo "error: legacy workflow exists at $legacy_target_workflow" >&2
  echo "migrate or remove it before installing $WORKFLOW_NAME to avoid duplicate runs" >&2
  exit 1
fi

if [[ -e $target_workflow ]] && ! cmp -s "$source_workflow" "$target_workflow"; then
  echo "error: $target_workflow already exists and differs from this template" >&2
  exit 1
fi

if [[ ! -e $target_workflow ]]; then
  mkdir -p "$(dirname -- "$target_workflow")"
  cp "$source_workflow" "$target_workflow"
  echo "Installed $target_workflow."
else
  echo "Workflow already up to date at $target_workflow."
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

agent_github_token=${AGENT_GITHUB_TOKEN:-}
if [[ -n $agent_github_token ]]; then
  printf '%s' "$agent_github_token" |
    gh secret set "$AGENT_TOKEN_SECRET_NAME" --repo "$repository"
fi

gh label create "$LABEL_NAME" \
  --repo "$repository" \
  --description "Ask the configured coding agent to implement this issue" \
  --force

default_workflow_permissions=$(gh api \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  "repos/$repository/actions/permissions/workflow" \
  --jq .default_workflow_permissions)

gh api \
  --method PUT \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  "repos/$repository/actions/permissions/workflow" \
  -f "default_workflow_permissions=$default_workflow_permissions" \
  -F can_approve_pull_request_reviews=true \
  >/dev/null

echo "Configured $SECRET_NAME for $repository."
if [[ -n $agent_github_token ]]; then
  echo "Configured $AGENT_TOKEN_SECRET_NAME for $repository."
fi
echo "Created or updated the $LABEL_NAME label."
echo "Allowed GitHub Actions to create and approve pull requests."
