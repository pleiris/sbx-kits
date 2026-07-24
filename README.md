# sbx-kits

Personal kits for [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/).

Each top-level directory containing `spec.yaml` or `spec.yml` is treated as a
kit. The test harness uses the Technology Compatibility Kit from
[`docker/sbx-kits-contrib`](https://github.com/docker/sbx-kits-contrib), pinned
in `go.mod` for reproducible builds.

## Test Kits

The standard TCK validates every kit and exercises it with Testcontainers:

```bash
./scripts/test-all.sh
```

Run one kit from the repository root:

```bash
./scripts/test-kit.sh chezmoi-dotfiles
```

The same wrapper can be run from inside a kit directory:

```bash
../scripts/test-kit.sh
```

Standard tests require Go 1.26.2 or newer and a working Docker daemon.

A kit whose install requires sandbox-managed credentials can include a
`testdata/tck-skip-install` marker. Its standard TCK run uses Go's `-short`
mode, which retains validation and container assertions but leaves install
execution to the E2E test.

## E2E Tests

The E2E wrapper runs the exact upstream `TestE2EKit` test from the version
pinned in `go.mod`. It creates a real sandbox under the isolated
`sbx-kits-contrib-tck` app name and applies a `deny-all` network policy before
testing the kit's declared network access.

```bash
./scripts/test-kit-e2e.sh chezmoi-dotfiles
```

Prerequisites:

- `sbx` installed and available on `PATH`
- KVM access on Linux
- Docker Hub authentication for the scoped daemon
- A Secret Service provider on Linux

Authenticate the scoped daemon once with:

```bash
sbx --app-name sbx-kits-contrib-tck login
```

For kits that clone private GitHub repositories, also configure a GitHub token:

```bash
gh auth token | sbx --app-name sbx-kits-contrib-tck secret set -g github
```

Set `POLICY=` to preserve the scoped daemon's current policy instead of
initializing `deny-all`.

## Dependency Updates

Update the TCK deliberately and review its test changes before merging:

```bash
go get github.com/docker/sbx-kits-contrib@latest
go mod tidy
```

Dependabot also opens weekly update pull requests for Go modules and GitHub
Actions.

## CI

`.github/workflows/tck.yml` runs the standard TCK once per discovered kit on
pushes and pull requests.

`.github/workflows/e2e.yml` can be run manually against the release or nightly
`sbx` channel. To run release E2E tests automatically on pushes to `main`, set
the repository variable `RUN_E2E` to `true`. E2E CI requires the repository
secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`. Kits that clone private
GitHub repositories also require `SBX_GITHUB_TOKEN`, containing a token with
read access to those repositories.
