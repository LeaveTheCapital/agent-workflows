# Agent workflows

Reusable automation for personal GitHub repositories.

## Codex issue workflow

Copy `.github/workflows/codex-issue.yml` into a repository. When the repository
owner adds the `codex-pr` label to one of their own issues, the workflow asks
Codex to implement it, commits any resulting changes to a new branch, and opens
a pull request for review.

The repository must allow GitHub Actions to create pull requests. In the
repository settings, enable **Actions > General > Workflow permissions > Allow
GitHub Actions to create and approve pull requests**.

Create the label once per repository:

```sh
gh label create codex-pr --description "Ask Codex to implement this issue"
```

Configure the API key from inside the target repository:

```sh
OPENAI_API_KEY=sk-... /path/to/agent-workflows/scripts/setup.sh
```

Or pass a repository explicitly:

```sh
OPENAI_API_KEY=sk-... ./scripts/setup.sh OWNER/REPOSITORY
```

The script stores the value as the GitHub Actions secret
`OPEN_API_KEY_SECRET`; it does not write the key to disk.

Only an issue authored by the repository owner and labeled by the repository
owner can trigger the job. Codex runs with workspace write access, while the
workflow itself owns the branch, commit, push, and pull-request steps.
