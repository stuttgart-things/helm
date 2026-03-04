# Skill: create-helmfile

Create a new Helmfile definition (`.yaml.gotmpl`) with companion values file(s) following this repository's conventions.

## Trigger

When the user asks to create/add a new helmfile, helm release, or chart deployment.

## Gather Information

Ask the user (if not already provided):

1. **Release name** (e.g., `grafana`, `redis`)
2. **Category**: `apps/`, `infra/`, `database/`, `monitoring/`, or `cicd/`
3. **Helm chart** — repository URL and chart name
4. **Repository type**: OCI (`ghcr.io/...`, `oci: true`) or HTTPS (`https://...`, `oci: false`)
5. **Default chart version**
6. **Namespace** (defaults to release name)
7. **Key Helm values** to parameterize (ingress, persistence, service type, etc.)
8. **Certificate support**: whether to include the optional `createCertificateResource` pattern

## File Generation

### 1. Main Helmfile: `<category>/<release-name>.yaml.gotmpl`

Structure (all sections separated by `---`):

```yaml
---
environments:
  default:
    values:
      - namespace: <release-name>
      - version: <default-version>
      # One key-value pair per list item
      # Nested structures for complex objects (certificates, instances)
---
repositories:
  - name: <repo-name>
    url: <repo-url>
    oci: true/false
  # Always include stuttgart-things repo if using certificate pattern
  # - name: stuttgart-things
  #   url: ghcr.io/stuttgart-things
  #   oci: true

releases:
  - name: <release-name>
    installed: true
    namespace: {{ .Values.namespace }}
    chart: <repo-name>/<chart-name>
    version: {{ .Values.version }}
    values:
      - values/<release-name>.values.yaml.gotmpl

# Certificate pattern (if requested):
{{- if .Values.createCertificateResource }}
  - name: <release-name>-ingress-certs
    disableValidationOnInstall: true
    installed: true
    namespace: {{ .Values.namespace }}
    chart: stuttgart-things/sthings-cluster
    version: 0.3.15
    values:
      - values/certificate.values.yaml.gotmpl
{{- end }}
```

### 2. Values File: `<category>/values/<release-name>.values.yaml.gotmpl`

Use Go template interpolation for all parameterized values:

```yaml
---
# Chart-specific values using {{ .Values.key }} references
someKey: {{ .Values.someValue }}

{{- if .Values.enableIngress }}
ingress:
  enabled: true
  ingressClassName: {{ .Values.ingressClassName }}
  hostname: {{ .Values.hostname }}.{{ .Values.domain }}
  {{- if not .Values.createCertificateResource }}
  annotations:
    cert-manager.io/{{ .Values.issuerKindAnnotation }}: "{{ .Values.issuerName }}"
  {{- end }}
  tls: true
{{- end }}
```

### 3. Certificate Values (if certificate pattern is used): reuse existing `values/certificate.values.yaml.gotmpl`

If the category doesn't already have a `values/certificate.values.yaml.gotmpl`, create one:

```yaml
---
customresources:
{{- range $k, $v := .Values.certificates }}
  {{ $k }}:
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: {{ $v.hostname }}.{{ $v.domain }}
      namespace: {{ $v.namespace }}
    spec:
      commonName: {{ $v.hostname }}.{{ $v.domain }}
      dnsNames:
        - {{ $v.hostname }}.{{ $v.domain }}
      issuerRef:
        name: {{ $v.issuerName }}
        kind: {{ $v.issuerKind }}
      secretName: {{ $v.secretName }}
{{- end }}
```

## Environment Values Conventions

Follow these patterns for the `environments.default.values` block:

- **One key-value per list item**: `- key: value` (not grouped)
- **Common keys** (include as applicable):
  - `namespace`, `version` — always
  - `serviceType: ClusterIP` — for services
  - `enableIngress: false` — for ingress toggle
  - `hostname`, `domain`, `ingressClassName: nginx` — for ingress
  - `issuerName: selfsigned`, `issuerKind: ClusterIssuer`, `issuerKindAnnotation: "cluster-issuer"` — for TLS
  - `createCertificateResource: false` — for certificate toggle
  - `enablePersistence: false`, `storageClass: ""`, `storageSize: 8Gi` — for persistence
  - `imageRegistry`, `imageRepository`, `imageTag` — for custom images
- **Nested structures** for certificates and complex objects:
  ```yaml
  - certificates:
      <release-name>:
        hostname: {{ .Values.hostname }}
        domain: {{ .Values.domain }}
        issuerName: {{ .Values.issuerName }}
        issuerKind: {{ .Values.issuerKind }}
        namespace: {{ .Values.namespace }}
        secretName: {{ .Values.hostname }}.{{ .Values.domain }}-tls
  ```

## Templating Patterns

Use these Go template constructs as needed:

- `{{ .Values.key }}` — simple interpolation
- `{{ .Values.key | default "fallback" }}` — default values
- `{{ .Values.key | quote }}` — string quoting
- `{{ env "ENV_VAR" }}` — environment variable access
- `{{- if .Values.boolKey }}...{{- end }}` — conditional blocks
- `{{- if hasKey .Values "optionalKey" }}...{{- end }}` — optional key checks
- `{{- range $k, $v := .Values.mapKey }}...{{- end }}` — iteration
- `{{ .Release.Namespace }}` — release namespace context

## Dependency Pattern

When a release depends on another (e.g., configuration after main chart), use `needs`:

```yaml
  - name: <release-name>-configuration
    needs:
      - {{ .Values.namespace }}/<release-name>
```

## Rules

- File extension is always `.yaml.gotmpl` for helmfiles and values files
- Values files go in `<category>/values/` subdirectory
- Values file naming: `<release-name>.values.yaml.gotmpl` (or `<release-name>-<variant>.values.yaml.gotmpl` for variants)
- Use `disableValidationOnInstall: true` on releases that create CRDs or custom resources
- Always use `installed: true` explicitly on releases
- Repository `oci` field must be explicitly `true` or `false`
- The `stuttgart-things/sthings-cluster` chart (OCI, `ghcr.io/stuttgart-things`) is used for deploying arbitrary custom resources (certificates, cluster issuers, secrets)
- Conditional repository inclusion when repos are only needed for optional features:
  ```yaml
  repositories:
  {{- if .Values.createCertificateResource }}
    - name: stuttgart-things
      url: ghcr.io/stuttgart-things
      oci: true
  {{- end }}
  ```
- After creating files, suggest a helmfile template command to verify:
  ```bash
  helmfile -f <category>/<release-name>.yaml.gotmpl template \
    --state-values-set key1=val1,key2=val2
  ```
