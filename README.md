# changie-release-action
Automate version and release management using [changie](https://github.com/miniscruff/changie)

This action creates a new PR with an updated `CHANGELOG.md` file. When merged it will automatically
create a new tag and trigger another GitHub action workflow that can then do the actual release.

The workflow is inspired both by [changie](https://github.com/miniscruff/changie) and [@changesets/action](https://github.com/changesets/action)

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
      uses: labd/changie-release-action@v0.1.0
      with:
        github-token: ${{ secrets.GITHUB_TOKEN }}
        
        # Trigger another release workflow to do the actual release.
        # Defaults to `release.yaml`, leave empty to disable
        release-workflow: 'release.yaml' 
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
