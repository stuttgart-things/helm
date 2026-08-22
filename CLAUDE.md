# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**stuttgart-things/helm** — A collection of declarative Helmfile configurations for deploying Helm charts to Kubernetes clusters. This is NOT a Helm chart repository; it contains Helmfile definitions (`.yaml.gotmpl` files) organized by category that use Go templating for parameterization.

## Repository Structure

Helmfile definitions are organized into five categories, each a top-level directory:

- `infra/` — Core Kubernetes infrastructure (cert-manager, ingress-nginx, metallb, cilium, longhorn, etc.)
- `database/` — Stateful services (postgres, keycloak, redis, openldap, etc.)
- `monitoring/` — Observability stack (grafana, loki, promtail, headlamp)
- `cicd/` — CI/CD tools (argocd, crossplane, flux, tekton, vcluster, etc.)
- `apps/` — Application deployments (nginx, harbor, gitea, vault, minio, etc.)

### Helmfile Anatomy

Each `.yaml.gotmpl` file is a self-contained Helmfile with:
1. An `environments.default.values` block defining all configurable parameters with defaults
2. A `repositories` section declaring Helm chart sources (OCI or HTTP)
3. A `releases` section using Go template expressions (e.g., `{{ .Values.namespace }}`) to reference environment values
4. Optional companion `values/*.yaml.gotmpl` files for complex chart value overrides

CRD helmfiles live in `infra/crds/` and `cicd/crds/` subdirectories.

## Common Commands

Task runner ([go-task](https://taskfile.dev)) is the primary build tool. Key tasks:

```bash
task --list                    # List all available tasks
task do                        # Interactive task selector (uses gum)
task render                    # Render a helmfile using Dagger
task install-release           # Test a release on a cluster
task uninstall-release         # Uninstall a release
task create-kind-cluster       # Create a local kind test cluster
task destroy-kind-cluster      # Destroy the kind test cluster
task tests-render-includes     # Render all test includes
task check                     # Run pre-commit hooks
task release                   # Semantic release (runs check, PR, then release)
```

Direct helmfile usage:
```bash
helmfile init                              # Initialize helmfile plugins
helmfile template -f <path>.yaml.gotmpl    # Template locally without include
helmfile apply -f <path>.yaml              # Apply to cluster
helmfile sync -f <path>.yaml               # Sync to cluster
```

Template testing without includes:
```bash
helmfile -f apps/grafana.yaml template \
  --state-values-set createCertificateResource=false,ingressEnabled=false,hostname=test,domain=test.com
```

## Linting and CI

- **YAML lint**: `yamllint` with config in `.yamllint` (max line length 110, warning only)
- **Pre-commit hooks** (`.pre-commit-config.yaml`): trailing-whitespace, end-of-file-fixer, check-merge-conflict, detect-private-key, detect-secrets, shellcheck, hadolint, check-github-workflows
- **CI workflow** (`.github/workflows/workflow.yaml`): Runs YAML linting on feature/fix/renovate branches
- Run hooks locally: `task check`

## Conventions

- **Commit messages**: Follow [Angular commit convention](https://www.conventionalcommits.org/) — semantic-release uses `@semantic-release/commit-analyzer` with Angular preset (`.releaserc`)
- **Branch naming**: `feature/**`, `feat/**`, `fix/**`, `renovate/**`
- **Releases**: Automated via `npx semantic-release` on `main` branch with tag format `v${version}`
- **Dependency updates**: Renovate manages Helm chart version updates (`renovate.json`) — see [Dependency Management](#dependency-management) for the annotation every templated chart version needs
- **Domain sanitization**: A pre-commit hook replaces `.sva.de` domains with `.example.com` in committed files

## Dependency Management

Renovate is configured in `renovate.json` with the `helmfile` manager matching every
`.yaml` / `.yaml.gotmpl` file, plus two `customManagers` for the templated versions
described below. `.k2n/**` and `tests/**` are in `ignorePaths` — the k2n examples are
generation input, not deployed state.

### Templated chart versions need a `# renovate:` annotation

Renovate's `helmfile` manager reads `releases[].version`. It cannot resolve Go
templates — `version: {{ .Values.version }}` is skipped with
`skipReason: contains-variable` and produces **no PR, no warning, no log entry**.

Since the helmfiles keep their versions in `environments.default.values`, that hid
every chart in this repo from Renovate. Each such value therefore carries a comment
naming the datasource, and a `customManager` updates the default in place:

```yaml
environments:
  default:
    values:
      # renovate: datasource=helm depName=cert-manager registryUrl=https://charts.jetstack.io
      - version: v1.21.0
```

Derive the annotation from the `repositories` entry the release's `chart:` points at:

| repositories entry | Annotation |
|---|---|
| `oci: true`, `url: ghcr.io/<path>` | `datasource=docker depName=ghcr.io/<path>/<chart>` |
| plain HTTPS repo | `datasource=helm depName=<chart> registryUrl=<url>` |

A `chart:` that is itself a full `oci://` URL (e.g. the gha-runner helmfiles) uses that
URL verbatim as `depName`.

**When adding a release, add the annotation too** — without it the chart is silently
invisible to Renovate and will never be updated. `task check-renovate` (also wired into
pre-commit and the CI workflow) fails on any templated chart version that is missing one.

```bash
task check-renovate      # fail on a missing annotation
task lint-renovate       # validate renovate.json against the Renovate schema
task preview-renovate    # dry-run Renovate against the working tree, writing nothing
```

### Never set `extractVersion` / `extractVersionTemplate`

`extractVersion` does not only normalise the version for comparison — Renovate writes
the **extracted** value back. With `^v?(?<version>.*)$` a registry tag of `v0.2.2` is
written as `0.2.2`, and `ghcr.io/stuttgart-things/homerun`, `cert-manager` and
`vcluster` are all tagged **with** the `v`, so the default would resolve to no chart at
all. Leave the field off and each datasource's own versioning writes the tag back
exactly as published.

### Known lookup failure

`docker-registry` (`database/registry.yaml.gotmpl`, `twuni` → https://helm.twun.io) is
reported on the Dependency Dashboard as `Failed to look up helm package
docker-registry: no-result`. Its version is hard-coded, so this is unrelated to the
annotations — fixing it means repointing the helmfile at a repository that resolves.

Worth re-checking with `task preview-renovate` after any change: `harbor` points at
https://charts.bitnami.com/bitnami, which Bitnami has been winding down in favour of
`oci://registry-1.docker.io/bitnamicharts`. If the lookup comes back empty, the
helmfile's `repositories` entry needs repointing, not the annotation.

## Key Tools

- **helmfile** — Declarative Helm chart deployment
- **machineshop** — Stuttgart-Things templating CLI used for rendering test configs
- **dagger** — Used for rendering helmfiles in CI (`github.com/stuttgart-things/dagger/helm`)
- **kind** — Local Kubernetes clusters for testing
- **gum** — Interactive CLI prompts in task commands
- **k2n** — AI-assisted helmfile generation (`task generate-helmfile`)
- **sops + age** — Secret encryption for helmfile environments
