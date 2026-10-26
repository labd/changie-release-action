# changie-release-action
Automate version and release management using [changie](https://github.com/miniscruff/changie),
in the style of [@changesets/action](https://github.com/changesets/action).

On every push to your main branch the action does one of two things:

- **There are unreleased changie entries:** it batches them, updates
  `CHANGELOG.md` and creates or updates a single release PR on the
  `changie-release/<branch>` branch. When the next version changes (e.g. from a
  patch to a minor release) the same PR is updated.
- **The release PR was just merged:** the latest changie version has no tag
  yet, so it sets the `released` output to `true` and the next steps in the
  same job publish the release. Nothing triggers another workflow.

The tag is created on GitHub together with the published release (by
`create-release` or the goreleaser action), not before. So a failed release
leaves no tag behind, and the next push to the branch (e.g. the fix) releases
the version again. This also means a step has to create the release, otherwise
`released` stays `true`.

## Usage

Run the action in a job after your tests. Use a GitHub App token, otherwise CI
does not run on the release PR. The token needs contents and pull-requests
write.

```yaml
  release:
    needs: test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    permissions:
      contents: read
    concurrency:
      group: release
      cancel-in-progress: false
    steps:
      - id: app-token
        uses: actions/create-github-app-token@v3
        with:
          app-id: ${{ vars.RELEASE_APP_ID }}
          private-key: ${{ secrets.RELEASE_APP_PRIVATE_KEY }}
          permission-contents: write
          permission-pull-requests: write

      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
          persist-credentials: false

      - id: changie
        uses: labd/changie-release-action@v2.0.0
        with:
          github-token: ${{ steps.app-token.outputs.token }}

          # Create a GitHub release with the changie notes after tagging.
          # Leave off when another step creates the release (e.g. goreleaser).
          create-release: true

          # Optionally run a command with the new version number when the new
          # version is determined.
          version-command: 'echo "New version is $PACKAGE_VERSION" > version.txt'
```

### Inputs

| Input | Default | Description |
|---|---|---|
| `github-token` | | Token with contents and pull-requests write |
| `changie-version` | `v1.26.0` | The changie version to use |
| `version-command` | | Command to set the version in the package, gets `$PACKAGE_VERSION` |
| `create-version-command` | | Command to determine the new version, gets `$PREVIOUS_VERSION` and must set the `version` output |
| `release-branch` | `changie-release/<branch>` | Branch of the release PR |
| `pull-request-title` | `chore(release): {version}` | Title and commit message of the release PR |
| `pull-request-labels` | | Labels for the release PR |
| `create-release` | `false` | Create a GitHub release with the changie notes |

### Outputs

| Output | Description |
|---|---|
| `released` | `'true'` when the latest version has no tag yet and should be released from this commit |
| `version` | The version of the release PR or the release |
| `notes-file` | Path to a file with the changie notes of that version |
| `pull-request-number` | Number of the release PR |

## Publishing with goreleaser

The `goreleaser` action publishes the release as a draft, uploads all assets
and only then publishes it, so consumers like the Terraform Registry never see
a half-finished release. The release notes are the changie notes.

```yaml
      - if: steps.changie.outputs.released == 'true'
        uses: labd/changie-release-action/goreleaser@v2.0.0
        with:
          github-token: ${{ steps.app-token.outputs.token }}
          version: ${{ steps.changie.outputs.version }}
          release-notes: ${{ steps.changie.outputs.notes-file }}
          # Optional, for signing the checksums
          gpg-private-key: ${{ secrets.GPG_PRIVATE_KEY }}
          gpg-passphrase: ${{ secrets.PASSPHRASE }}
```

For Terraform providers, add a `terraform-registry-manifest.json` with the
protocol version of your provider and include it in the release:

```yaml
checksum:
  extra_files:
    - glob: 'terraform-registry-manifest.json'
      name_template: '{{ .ProjectName }}_{{ .Version }}_manifest.json'
release:
  extra_files:
    - glob: 'terraform-registry-manifest.json'
      name_template: '{{ .ProjectName }}_{{ .Version }}_manifest.json'
```

## Publishing to PyPI

The `pypi` action builds the package with uv, publishes it to PyPI with
[trusted publishing](https://docs.pypi.org/trusted-publishers/) and then
creates the GitHub release (and tag) with the changie notes. Run it in a
separate job, so `id-token: write` and the `pypi` environment only apply to
the release. Configure the trusted publisher on PyPI with the workflow file
that contains this job and the `pypi` environment.

Keep the version in `pyproject.toml` in sync with changie `replacements`, and
run `uv lock` as `version-command` because `uv.lock` also contains the version:

```yaml
replacements:
  - path: pyproject.toml
    find: '^version = ".*"'
    replace: 'version = "{{.VersionNoPrefix}}"'
```

```yaml
  version:
    needs: test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    outputs:
      released: ${{ steps.changie.outputs.released }}
      version: ${{ steps.changie.outputs.version }}
    steps:
      # app token and checkout as above, then:
      - uses: astral-sh/setup-uv@v7
      - id: changie
        uses: labd/changie-release-action@v2.0.0
        with:
          github-token: ${{ steps.app-token.outputs.token }}
          version-command: uv lock

  publish:
    needs: version
    if: needs.version.outputs.released == 'true'
    runs-on: ubuntu-latest
    environment: pypi
    permissions:
      contents: write
      id-token: write
    steps:
      - uses: actions/checkout@v7
        with:
          persist-credentials: false
      - uses: labd/changie-release-action/pypi@v2.0.0
        with:
          github-token: ${{ github.token }}
          version: ${{ needs.version.outputs.version }}
```

## Upgrading from v0.x

- The `release-workflow` input is removed. Publish in the same job using the
  `released` output instead of triggering a separate workflow.
- The release PR now uses the fixed `changie-release/<branch>` branch. Close
  any open `release/vX.Y.Z` PRs after upgrading.
- `actions: write` is no longer needed.
