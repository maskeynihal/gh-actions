# Reusable Backup and Commit Workflow

This reusable GitHub Action workflow performs automated backups from a remote server and commits them to a GitHub repository.

## Features

- SSH to remote server using Deployer
- Run Laravel backup command (`php artisan backup:run`)
- Copy backup file from remote server to GitHub Actions runner
- Commit and push backup to a specified GitHub repository
- Automated commit messages with date and description

## Prerequisites

### Required Secrets

1. **GH_PAT**: GitHub Personal Access Token with `repo` access to push to the target repository
2. A private key secret in your repository (default name: `PRIVATE_KEY`). You reference this by setting the input `private-key-name`. The reusable workflow resolves it via `secrets[inputs.private-key-name]`.

> If the reusable workflow and caller are in the same organization, you can use `secrets: inherit` in the caller to make repository secrets (like `PRIVATE_KEY`) available.

### Setting up GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate a new token with `repo` scope
3. Add the token as a secret named `GH_PAT` in your repository

### Setting up SSH Key Secret

1. Add your SSH private key as a repository secret (e.g., `PRIVATE_KEY`)
2. Pass its name via the `private-key-name` input (defaults to `PRIVATE_KEY`)

## Usage

### Basic Usage

Create a workflow file (e.g., `.github/workflows/daily-backup.yml`):

```yaml
name: Daily Backup

on:
  workflow_dispatch:
    inputs:
      deploy-namespace:
        description: "Deploy Namespace"
        required: true
        type: string
      target-repo:
        description: "Target repository (owner/repo)"
        required: true
        type: string

jobs:
  backup:
    uses: ./.github/workflows/reusable_backup_and_commit.yml
    with:
      deploy-namespace: ${{ inputs.deploy-namespace }}
      target-repo: ${{ inputs.target-repo }}
      target-branch: main
      backup-directory: backups
      private-key-name: PRIVATE_KEY
    secrets:
      GH_PAT: ${{ secrets.GH_PAT }}
    # If in the same org, optionally inherit secrets:
    # secrets: inherit
```

### Scheduled Backup

Run backups automatically on a schedule:

```yaml
name: Scheduled Backup

on:
  schedule:
    # Run every day at 2 AM UTC
    - cron: "0 2 * * *"

jobs:
  backup:
    uses: ./.github/workflows/reusable_backup_and_commit.yml
    with:
      deploy-namespace: production
      target-repo: your-org/backup-repo
      target-branch: main
      backup-directory: backups
      private-key-name: PRIVATE_KEY
    secrets:
      GH_PAT: ${{ secrets.GH_PAT }}
```

## Inputs

| Input              | Description                                       | Required | Default       |
| ------------------ | ------------------------------------------------- | -------- | ------------- |
| `deploy-namespace` | Deploy namespace for SSH connection               | Yes      | -             |
| `target-repo`      | Target repository with owner (e.g., `owner/repo`) | Yes      | -             |
| `target-branch`    | Target branch to commit to                        | No       | `main`        |
| `backup-directory` | Directory to store backups in the target repo     | No       | `backups`     |
| `private-key-name` | Name of the secret containing the private key     | No       | `PRIVATE_KEY` |

## Secrets

| Secret   | Description                                   | Required |
| -------- | --------------------------------------------- | -------- |
| `GH_PAT` | GitHub Personal Access Token with repo access | Yes      |

## Workflow Steps

1. **Checkout code**: Checks out the source repository containing the Deployer scripts
2. **Setup PHP**: Installs PHP for running composer and Deployer
3. **Install Dependencies**: Installs composer dependencies
4. **Run Backup on Remote Server**: Executes `php artisan backup:run` on the remote server using Deployer and identifies the latest zip under `storage/app/<app.name>/`
5. **Copy Backup File to Runner**: Downloads the backup file from the remote server
6. **Checkout Target Repository**: Checks out the repository where backups will be stored at `target-branch`
7. **Copy Backup to Target Repository**: Moves the backup file to the target repository
8. **Commit and Push Backup**: Commits and pushes the backup with a timestamped message to `target-branch`
9. **Cleanup**: Removes temporary files
10. **Summary**: Displays a summary of the backup operation

## Commit Message Format

The workflow creates commit messages in the following format:

```
Backup: <deploy-namespace> - 2025-12-26 14:30:00

Automated backup from <deploy-namespace>
Backup file: <filename>.zip
Triggered by: <github.actor>
Workflow: <github.workflow>
Run ID: <github.run_id>
```

## Example Scenarios

### Manual Backup Trigger (choices)

```yaml
on:
  workflow_dispatch:
    inputs:
      deploy-namespace:
        description: "Deploy Namespace"
        required: true
        type: choice
        options:
          - production
          - staging
          - development
      target-repo:
        description: "Target repository"
        required: true
        default: "your-org/backups"
```

### Multiple Environment Backups

```yaml
jobs:
  backup-production:
    uses: ./.github/workflows/reusable_backup_and_commit.yml
    with:
      deploy-namespace: production
      target-repo: your-org/backups
      target-branch: main
      backup-directory: backups/production
      private-key-name: PRIVATE_KEY
    secrets:
      GH_PAT: ${{ secrets.GH_PAT }}

  backup-staging:
    uses: ./.github/workflows/reusable_backup_and_commit.yml
    with:
      deploy-namespace: staging
      target-repo: your-org/backups
      target-branch: main
      backup-directory: backups/staging
      private-key-name: PRIVATE_KEY
    secrets:
      GH_PAT: ${{ secrets.GH_PAT }}
```

## Troubleshooting

### Backup file not found

- Ensure your Laravel application has the backup package configured correctly
- Confirm `app.name` resolves properly and backups are stored under `storage/app/<app.name>/`
- Verify SSH connection and permissions on the remote server

### Push failed

- Ensure the `GH_PAT` token has sufficient permissions
- Verify the target repository exists and is accessible
- Check that the target branch exists

### SSH connection issues

- Ensure the private key secret exists and the `private-key-name` input matches it
- If using a reusable workflow within the same org, consider `secrets: inherit`
- Check that the Deployer configuration and host are correct

## Notes

- SSH is managed by Deployer; no manual ssh-keyscan or keyfile writing needed
- Large backup files may take longer to transfer; consider Git LFS or external storage
- You can specify a custom secret name for the private key using the `private-key-name` input
