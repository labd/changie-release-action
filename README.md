# changie-release-action
Automate version and release management using [changie](https://github.com/miniscruff/changie)

This action creates a new PR with an updated `CHANGELOG.md` file. When merged it
will automatically create a new tag and trigger another GitHub action workflow
that can then do the actual release.

The workflow is inspired both by [changie](https://github.com/miniscruff/changie)
and [@changesets/action](https://github.com/changesets/action)

## Usage

```yaml
name: Test changes

on:
  push:
    branches:
      - 'main'

permissions:
  contents: write
  pull-requests: write
  actions: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v3
      with:
        fetch-depth: 0

    - name: Prepare release
      uses: labd/changie-release-action@v0.6.2
      with:
        github-token: ${{ secrets.GITHUB_TOKEN }}

        # Optionally run a command with the new version number when the new
        # version is determined.
        version-command: 'echo "New version is $PACKAGE_VERSION" > version.txt'

        # Trigger another release workflow to do the actual release.
        # Set to for example `release.yaml` to trigger that workflow.
        # Default is no trigger
        release-workflow: 'release.yaml'
```

## Using a GitHub App token

Pull requests created with the default `GITHUB_TOKEN` don't start workflows
(checks stay at "action required"). Use a GitHub App installation token
instead, e.g. via `actions/create-github-app-token`:

```yaml
    - name: Create release app token
      id: app-token
      uses: actions/create-github-app-token@v3
      with:
        app-id: ${{ vars.RELEASE_APP_ID }}
        private-key: ${{ secrets.RELEASE_APP_PRIVATE_KEY }}
        permission-contents: write
        permission-pull-requests: write
        # only needed when `release-workflow` is set
        permission-actions: write

    - name: Prepare release
      uses: labd/changie-release-action@v0.6.2
      with:
        github-token: ${{ steps.app-token.outputs.token }}
```

## Triggering a release

This triggered workflow needs the `on: workflows` event. For example:

```yaml
name: Release

on:
  workflow_dispatch:

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set env
        run: echo "${GITHUB_REF#refs/*/}"
```
