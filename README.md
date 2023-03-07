# changie-release-action

Automate version and release management using [changie](https://github.com/miniscruff/changie)

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
```
