#!/usr/bin/env bash
#
# Fail if a helmfile release takes its chart version from an environment value
# without a "# renovate:" annotation on that value.
#
# Renovate's helmfile manager reads releases[].version. A Go template such as
#   version: {{ .Values.version }}
# is skipped with skipReason "contains-variable" -- no PR, no warning, no log
# entry. The annotation plus the customManager in renovate.json is what makes
# the default in environments.default.values visible again.
#
set -euo pipefail

cd "$(dirname "$0")/.."

fail=0

mapfile -t files < <(
  git ls-files 'apps/*' 'cicd/*' 'database/*' 'infra/*' 'monitoring/*' \
    | grep -E '\.ya?ml(\.gotmpl)?$' \
    | grep -v '/values/'
)

for f in "${files[@]}"; do
  grep -q '^releases:' "$f" || continue

  # value keys referenced as a chart version, e.g. "version: {{ .Values.foo }}"
  mapfile -t keys < <(
    grep -oE '^[[:space:]]+version:[[:space:]]*\{\{[[:space:]]*\.Values\.[A-Za-z0-9_]+' "$f" \
      | sed 's/.*\.Values\.//' | sort -u
  )

  for key in "${keys[@]:-}"; do
    [ -n "$key" ] || continue

    line=$(grep -nE "^[[:space:]]*-[[:space:]]+${key}:" "$f" | head -1 | cut -d: -f1 || true)
    if [ -z "$line" ]; then
      echo "ERROR: $f: chart version uses .Values.${key}, but no '- ${key}:' default exists in this file"
      fail=1
      continue
    fi

    if [ "$line" -lt 2 ] || ! sed -n "$((line - 1))p" "$f" | grep -q '# renovate:'; then
      echo "ERROR: $f:${line}: '- ${key}:' has no '# renovate:' annotation -- Renovate will never update this chart"
      fail=1
    fi
  done
done

if [ "$fail" -ne 0 ]; then
  cat <<'HINT'

Add the annotation directly above the value, derived from the repositories entry
the release's chart points at:

  OCI repo (oci: true)  ->  # renovate: datasource=docker depName=<host>/<path>/<chart>
  plain HTTPS repo      ->  # renovate: datasource=helm depName=<chart> registryUrl=<url>

Example:

  environments:
    default:
      values:
        # renovate: datasource=helm depName=cert-manager registryUrl=https://charts.jetstack.io
        - version: v1.21.0

Never add extractVersion / extractVersionTemplate: Renovate writes the extracted
value back, so stripping a leading "v" produces a default that resolves to no tag.
HINT
  exit 1
fi

echo "OK: every templated chart version carries a '# renovate:' annotation"
