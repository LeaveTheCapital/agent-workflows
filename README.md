# Agent workflows

Reusable automation for personal GitHub repositories.

## Codex issue workflow

Run the setup script from a repository. It copies
`.github/workflows/codex-issue.yml` into that repository, configures the API key,
creates the `codex-pr` label, and allows GitHub Actions to create pull requests.
When the repository owner adds that label to one of their own issues, the
workflow asks Codex to implement it, commits any resulting changes to a new
branch, and opens a pull request for review.

Set up the workflow from inside the target repository:

```sh
OPENAI_API_KEY=sk-... /path/to/agent-workflows/scripts/setup.sh
```

Or pass a local target repository directory explicitly:

```sh
OPENAI_API_KEY=sk-... ./scripts/setup.sh /path/to/target-repository
```

The script refuses to overwrite a different existing workflow. It stores the
API key as the GitHub Actions secret `OPEN_API_KEY_SECRET`; it does not write
the key to disk. Review and commit the installed workflow in the target
repository after setup.

The GitHub CLI login must have repository administration permission so setup
can enable **Actions > General > Workflow permissions > Allow GitHub Actions to
create and approve pull requests**. The script preserves the repository's
existing default workflow permission (`read` or `write`).

Only an issue authored by the repository owner and labeled by the repository
owner can trigger the job. Codex runs with workspace write access, while the
workflow itself owns the branch, commit, push, and pull-request steps.
