# stuttgart-things/helm/apps

App Helmfile templates.

---

## SERVICES

<details><summary>RANCHER</summary>

```bash
# EXAMPLE APPLY
export RANCHER_PASSWORD=<REPLACE-ME>

helmfile apply -f \
git::https://github.com/stuttgart-things/helm.git@apps/apps/rancher.yaml.gotmpl \
--state-values-set issuerName=cluster-issuer-approle \
--state-values-set domain=demo-infra.sthings-vsphere.labul.sva.de \
--state-values-set bootstrapPassword={{ env "RANCHER_PASSWORD" | default "hall01234R@ncher" }} \
--state-values-set cacerts=LS0tLS1CRUdJTiBDRV#..
```

</details>

<details><summary>HOMERUN-BASE-STACK</summary>

```bash
# BASIC APPLY

export redisPassword=<REDIS-PASSWORD>
export genericPitcherToken=<GENERIC-TOKEN>

helmfile apply -f \
git::https://github.com/stuttgart-things/helm.git@apps/apps/homerun-base-stack.yaml.gotmpl \
--state-values-set redisStackStorageClass=openebs-hostpath \
--state-values-set genericPitcherDomain=demo-infra.example.com
```

```bash
# CREATE REDISEARCH INDEX
sudo apt install redis-tools -y
kubectl port-forward -n homerun svc/redis-stack 6379:6379
redis-cli -h localhost -p 6379 -a <REDIS-PASSWORD>

FT.CREATE homerun ON HASH PREFIX 1 "message:" SCHEMA messageID TEXT SORTABLE timestamp NUMERIC SORTABLE
FT._LIST
```

```bash
export HOMERUN_ADDRESS=https://homerun.demo-infra.whatever.de/generic
bash tests/homerun-send-events.sh
```

</details>

<details><summary>GITEA</summary>

### SIMPLE DEPLOYMENT

```bash
# BASIC
cat <<EOF > gitea.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/gitea.yaml.gotmpl
    values:
      - namespace: gitea
      - version: 12.1.3
EOF
```

### GITEA DEPLOYMENT + KEYCLOAK AUTH

```bash
# KEYCLOAK OAUTH + NOEDPORT SERVICE, ALLOW WEBHOOKS
cat <<EOF > gitea.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/gitea.yaml.gotmpl
    values:
      - httpServiceType: NodePort
      - nodePortHttp: "31635"
      - webhookAllowList: "*"
      - adminUser: gitea_admin
      - adminPassword: {{ env "GITEA_ADMIN_PASSWORD" | default "admin" }}
      - enableOauth: true
      - oauthName: keycloak
      - oauthProvider: "openidConnect"
      - oauthKey: gitea
      - oauthSecret: "{{ env "GITEA_OAUTH_SECRET" }}"
      - oauthAutoDiscoverUrl: "http://maverick.example.com:31634/realms/apps/.well-known/openid-configuration"
      - oauthScopes: "openid, profile, email"
      - oauthGroupClaimName: "groups"
      - oauthAdminGroup: "apps-admin"
      - oauthEnableAutoRegistration: true
      - oauthAccountLinking: auto
      - rootUrl: http://maverick.example.com:31635/
      - serverDomain: maverick.example.com
EOF
```

</details>

<details><summary>VAULT</summary>

### DEPLOY

```bash
cat <<EOF > vault.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/vault.yaml.gotmpl
    values:
      - namespace: vault
      - storageClass: standard
EOF
```

### UNSEAL

```bash
kubectl -n vault exec -it vault-server-0 -- vault operator init
kubectl -n vault exec -it vault-server-0 -- vault operator unseal <UNSEALKEY-X>
kubectl -n vault exec -it vault-server-0 -- vault operator unseal <UNSEALKEY-Y>
# ...
kubectl -n vault exec -it vault-server-0 -- vault status
```

</details>

<details><summary>NGINX</summary>

### w/ LOADBALANCER

```bash
cat <<EOF > nginx-lb.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/nginx.yaml.gotmpl
    values:
      - profile: nginx
      - replicas: 1
      - serviceType: LoadBalancer
      - enableIngress: false
EOF
```

### w/ INGRESS + CERT (INGRESS ANNOTAION - CERT-MANAGER)

```bash
cat <<EOF > nginx.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/nginx.yaml.gotmpl
    values:
      - namespace: nginx
      - profile: nginx
      - serviceType: ClusterIP
      - enableIngress: true
      - clusterIssuer: selfsigned
      - issuerKind: cluster-issuer
      - hostname: webserver
      - domain: dev3.172.18.0.3.nip.io
      - ingressClassName: nginx
EOF
```

### w/ INGRESS + CERT CREATION (CERTIFICATION - CR)

```bash
cat <<EOF > nginx.yaml
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/nginx.yaml.gotmpl
    values:
      - namespace: nginx
      - profile: nginx
      - serviceType: ClusterIP
      - enableIngress: true
      - hostname: webserver
      - domain: sthings-infra-dev.example.com
      - ingressClassName: nginx
      - createCertificateResource: true
      - certificates:
          nginx:
            hostname: webserver
            domain: sthings-infra-dev.example.com
            issuerName: labda-4sthings
            issuerKind: ClusterIssuer
            namespace: nginx
            secretName: webserver.sthings-infra-dev.example.com-tls
EOF
```

</details>

<details><summary>CLUSTERBOOK</summary>
s
```bash
cat <<EOF > clusterbook.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/clusterbook.yaml
    values:
      - namespace: clusterbook
      - enableIngress: true
      - enableCertificateRequest: true
      - ingressDomain: 172.18.0.5.nip.io
      - issuerKind: ClusterIssuer
      - issuerName: selfsigned
      - imageTag: v1.5.0 # pragma: allowlist secret
      - hostname: clusterbook
      - tlsSecretName: clusterbook-ingress-tls # pragma: allowlist secret
      - app: clusterbook
EOF
```

</details>

<details><summary>AWX</summary>

### AWX-OPERATOR

```bash
cat <<EOF > awx-operator.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/awx.yaml.gotmpl
    values:
      - namespace: awx
      - version: 3.2.0
      - installOperator: true
EOF
```

### AWX-INSTANCE

```bash
cat <<EOF > awx-instance.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/awx.yaml.gotmpl
    values:
      - namespace: awx
      - installOperator: false
      - ingressType: ingress
      - postgresStorageClass: standard
      - projectStorageClass: standard
      - clusterIssuer: selfsigned
      - secrets:
          sthings-admin-password:
            namespace: awx
            kvs:
              password: whatever
      - createSSLCerts: true
      - instances:
          dev:
            name: awx-dev
            namespace: awx
            adminUser: sthings
            adminPasswordSecret: sthings-admin-password
            bundleCacertSecret: sthings-custom-certs
            hostname: awx-dev
            domain: 172.18.0.3.nip.io
            ingressClassName: nginx
            ingressSecret: awx-dev
            postgresStorageLimits: 8Gi
            postgresStorageRequest: 1Gi
            projectPersistence: false
            projectsStorageAccessMode: ReadWriteOnce
            fsGroupChangePolicy: OnRootMismatch
EOF
```

### AWX INSTANCE

```bash
cat <<EOF > awx.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/awx.yaml
    values:
      - namespace: awx
      - app: awx
      - ingressType: ingress
      - postgresStorageClass: standard
      - projectStorageClass: standard
      - clusterIssuer: selfsigned
      - secrets:
          sthings-admin-password:
            namespace: awx
            kvs:
              password: ref+vault://apps/awx/password-dev
          sthings-custom-certs:
            namespace: awx
            kvs:
              bundle-ca.crt: ref+vault://apps/awx/cabundle

      - instances:
          dev:
            name: awx-dev
            namespace: awx
            adminUser: sthings
            adminPasswordSecret: sthings-admin-password
            bundleCacertSecret: sthings-custom-certs
            hostname: awx-dev
            domain: 172.18.0.3.nip.io
            ingressClassName: nginx
            ingressSecret: awx-dev
            postgresStorageLimits: 8Gi
            postgresStorageRequest: 1Gi
            projectPersistence: false
            projectsStorageAccessMode: ReadWriteOnce
            fsGroupChangePolicy: OnRootMismatch
EOF
```

</details>

<details><summary>KYVERNO</summary>

```bash
cat <<EOF > kyverno.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/kyverno.yaml.gotmpl
    values:
      - version: 3.5.1
      - namespace: kyverno
EOF
```

</details>

<details><summary>HARBOR</summary>

### w/ INGRESS + CERT (INGRESS ANNOTATION - CERT-MANAGER)

```bash
export HARBOR_PASSWORD=<REPLACE-ME>

helmfile apply -f git::https://github.com/stuttgart-things/helm.git@apps/harbor.yaml.gotmpl \
--state-values-set-string "namespace=harbor,domain=idp.kubermatic.sva.dev,issuerName=letsencrypt-prod,storageClass=vsphere-csi,adminPassword=${HARBOR_PASSWORD}"
```

<details><summary>MINIO</summary>

### w/ INGRESS + CERT (INGRESS ANNOTAION - CERT-MANAGER)

```bash
cat <<EOF > minio.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/minio.yaml
    values:
      - namespace: minio
      - clusterIssuer: selfsigned
      - issuerKind: cluster-issuer
      - domain: 172.18.0.2.nip.io
      - ingressClassName: nginx
      - rootUser: adminadmin
      - rootPassword: adminadmin
      - hostnameConsole: artifacts-console
      - hostnameApi: artifacts
      - storageClass: standard
EOF
```

### w/ INGRESS + CERT CREATION (CERTIFICATION - CR)

```bash
cat <<EOF > minio.yaml
---
helmfiles:
  - path: /home/sthings/projects/apps/helm/apps/minio.yaml.gotmpl
    values:
      - namespace: minio
      - clusterIssuer: labda-4sthings
      - issuerKind: cluster-issuer
      - domain: sthings-infra-dev.example.com
      - ingressClassName: nginx
      - rootUser: adminadmin
      - rootPassword: adminadmin
      - hostnameConsole: artifacts-console
      - hostnameApi: artifacts
      - storageClass: openebs-hostpath
      - createCertificateResource: true
      - certificates:
          api:
            hostname: artifacts
            domain: sthings-infra-dev.example.com
            issuerName: labda-4sthings
            issuerKind: ClusterIssuer
            namespace: minio
            secretName: artifacts.sthings-infra-dev.example.com-tls
          console:
            hostname: artifacts-console
            domain: sthings-infra-dev.example.com
            issuerName: labda-4sthings
            issuerKind: ClusterIssuer
            namespace: minio
            secretName: artifacts-console.sthings-infra-dev.example.com-tls
EOF
```

</details>

</details>

<details><summary>BACKSTAGE</summary>

### BASIC DEPLOYMENT

```bash
cat <<EOF > backstage.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/backstage.yaml.gotmpl
    values:
      - namespace: portal
      - storageClass: openebs-hostpath
      - clusterDomain: <CLUSTER-DOMAIN>
      - postgresql:
          enabled: true
          username: backstage
          password: <POSTGRES-PASSWORD>
          architecture: standalone
      - backstage:
          replicas: 1
          imageRegistry: ghcr.io
          imageRepository: stuttgart-things/sthings-backstage
          imageTag: "<IMAGE-TAG>"
          extraAppConfig:
              filename: app-config.extra.yaml
              configMapRef: backstage-app-config
EOF
```

### w/ INGRESS

```bash
cat <<EOF > backstage.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/backstage.yaml.gotmpl
    values:
      - namespace: portal
      - storageClass: openebs-hostpath
      - clusterDomain: <CLUSTER-DOMAIN>
      - postgresql:
          enabled: true
          username: backstage
          password: <POSTGRES-PASSWORD>
          architecture: standalone
      - ingress:
          enabled: true
      - backstage:
          replicas: 1
          imageRegistry: ghcr.io
          imageRepository: stuttgart-things/sthings-backstage
          imageTag: "<IMAGE-TAG>"
          extraAppConfig:
              filename: app-config.extra.yaml
              configMapRef: backstage-app-config
      - secrets:
          backstage-secrets:
              namespace: portal
              kvs:
                  APP_TITLE: <APP-TITLE>
                  ORGANIZATION_NAME: <ORG-NAME>
                  APP_BASE_URL: https://backstage.<CLUSTER-DOMAIN>
                  BACKEND_BASE_URL: https://backstage.<CLUSTER-DOMAIN>
                  CORS_ORIGIN: https://backstage.<CLUSTER-DOMAIN>
                  CLAIM_MACHINERY_API_URL: https://claim-api.<CLUSTER-DOMAIN>
                  CLAIM_MACHINERY_REGISTRY_URL: https://registry-api.<CLUSTER-DOMAIN>
                  AUTH_ENVIRONMENT: development
                  GITHUB_TOKEN: <GITHUB-TOKEN>
                  GITHUB_CLIENT_ID: <GITHUB-CLIENT-ID>
                  GITHUB_CLIENT_SECRET: <GITHUB-CLIENT-SECRET>
                  BACKEND_SECRET: <BACKEND-SECRET>
      - appConfig: |
          app:
            title: Backstage
            baseUrl: ${APP_BASE_URL}
          organization:
            name: ${ORGANIZATION_NAME}
          backend:
            auth:
              keys:
                - secret: ${BACKEND_SECRET:-change-me-in-production}
            baseUrl: ${BACKEND_BASE_URL:-http://localhost:7007}
            listen:
              port: ${BACKEND_PORT:-7007}
            csp:
              connect-src: ["'self'", 'http:', 'https:']
            cors:
              origin: ${CORS_ORIGIN:-http://localhost:3000}
              methods: [GET, HEAD, PATCH, POST, PUT, DELETE]
              credentials: true
            database:
              client: better-sqlite3
              connection: ':memory:'
          integrations:
            github:
              - host: github.com
                token: ${GITHUB_TOKEN}
          proxy:
            endpoints:
              '/claim-machinery':
                target: ${CLAIM_MACHINERY_API_URL:-https://claim-api.idp.kubermatic.sva.dev}
                changeOrigin: true
                pathRewrite:
                  '^/api/proxy/claim-machinery': ''
                allowedHeaders: ['*']
                credentials: 'dangerously-allow-unauthenticated'
              '/machinery-registry':
                target: ${CLAIM_MACHINERY_REGISTRY_URL:-https://claim-api.idp.kubermatic.sva.dev}
                changeOrigin: true
                pathRewrite:
                  '^/api/proxy/machinery-registry': ''
                allowedHeaders: ['*']
                credentials: 'dangerously-allow-unauthenticated'
          techdocs:
            builder: 'local'
            generator:
              runIn: 'local'
            publisher:
              type: 'local'
          auth:
            environment: development
            providers:
              guest: {}
              github:
                development:
                  clientId: ${GITHUB_CLIENT_ID}
                  clientSecret: ${GITHUB_CLIENT_SECRET}
                  signIn:
                    resolvers:
                      - resolver: usernameMatchingUserEntityName
          scaffolder: {}
          claimMachinery:
            apiUrl: ${CLAIM_MACHINERY_API_URL:-https://claim-api.idp.kubermatic.sva.dev}
          catalog:
            import:
              entityFilename: catalog-info.yaml
              pullRequestBranchName: backstage-integration
            rules:
              - allow: [Component, System, API, Resource, Location, Template]
            locations:
              - type: url
                target: https://github.com/stuttgart-things/backstage-resources/blob/main/org/sthings-dev/org.yaml
                rules:
                  - allow: [User, Group]
              - type: url
                target: https://github.com/stuttgart-things/backstage-resources/blob/main/services/sthings-dev/catalog-index.yaml
                rules:
                  - allow: [Component, Location, System, API, Resource, Template]
          kubernetes:
            serviceLocatorMethod:
              type: multiTenant
            clusterLocatorMethods:
              - type: localKubectlProxy
          permission:
            enabled: true
EOF
```

### w/ GATEWAY API

```bash
cat <<EOF > backstage.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/backstage.yaml.gotmpl
    values:
      - namespace: portal
      - storageClass: openebs-hostpath
      - clusterDomain: <CLUSTER-DOMAIN>
      - postgresql:
          enabled: true
          username: backstage
          password: <POSTGRES-PASSWORD>
          architecture: standalone
      - ingress:
          enabled: false
      - backstage:
          replicas: 1
          imageRegistry: ghcr.io
          imageRepository: stuttgart-things/sthings-backstage
          imageTag: "<IMAGE-TAG>"
          extraAppConfig:
              filename: app-config.extra.yaml
              configMapRef: backstage-app-config
      - secrets:
          backstage-secrets:
              namespace: portal
              kvs:
                  APP_TITLE: <APP-TITLE>
                  ORGANIZATION_NAME: <ORG-NAME>
                  APP_BASE_URL: https://backstage.<CLUSTER-DOMAIN>
                  BACKEND_BASE_URL: https://backstage.<CLUSTER-DOMAIN>
                  CORS_ORIGIN: https://backstage.<CLUSTER-DOMAIN>
                  CLAIM_MACHINERY_API_URL: https://claim-api.<CLUSTER-DOMAIN>
                  CLAIM_MACHINERY_REGISTRY_URL: https://registry-api.<CLUSTER-DOMAIN>
                  AUTH_ENVIRONMENT: development
                  GITHUB_TOKEN: <GITHUB-TOKEN>
                  GITHUB_CLIENT_ID: <GITHUB-CLIENT-ID>
                  GITHUB_CLIENT_SECRET: <GITHUB-CLIENT-SECRET>
                  BACKEND_SECRET: <BACKEND-SECRET>
      - gateway:
          name: <GATEWAY-NAME>
          namespace: default
          hostname: backstage
      - appConfig: |
          app:
            title: Backstage
            baseUrl: ${APP_BASE_URL}
          organization:
            name: ${ORGANIZATION_NAME}
          backend:
            auth:
              keys:
                - secret: ${BACKEND_SECRET:-change-me-in-production}
            baseUrl: ${BACKEND_BASE_URL:-http://localhost:7007}
            listen:
              port: ${BACKEND_PORT:-7007}
            csp:
              connect-src: ["'self'", 'http:', 'https:']
            cors:
              origin: ${CORS_ORIGIN:-http://localhost:3000}
              methods: [GET, HEAD, PATCH, POST, PUT, DELETE]
              credentials: true
            database:
              client: better-sqlite3
              connection: ':memory:'
          integrations:
            github:
              - host: github.com
                token: ${GITHUB_TOKEN}
          proxy:
            endpoints:
              '/claim-machinery':
                target: ${CLAIM_MACHINERY_API_URL:-https://claim-api.idp.kubermatic.sva.dev}
                changeOrigin: true
                pathRewrite:
                  '^/api/proxy/claim-machinery': ''
                allowedHeaders: ['*']
                credentials: 'dangerously-allow-unauthenticated'
              '/machinery-registry':
                target: ${CLAIM_MACHINERY_REGISTRY_URL:-https://claim-api.idp.kubermatic.sva.dev}
                changeOrigin: true
                pathRewrite:
                  '^/api/proxy/machinery-registry': ''
                allowedHeaders: ['*']
                credentials: 'dangerously-allow-unauthenticated'
          techdocs:
            builder: 'local'
            generator:
              runIn: 'local'
            publisher:
              type: 'local'
          auth:
            environment: development
            providers:
              guest: {}
              github:
                development:
                  clientId: ${GITHUB_CLIENT_ID}
                  clientSecret: ${GITHUB_CLIENT_SECRET}
                  signIn:
                    resolvers:
                      - resolver: usernameMatchingUserEntityName
          scaffolder: {}
          claimMachinery:
            apiUrl: ${CLAIM_MACHINERY_API_URL:-https://claim-api.idp.kubermatic.sva.dev}
          catalog:
            import:
              entityFilename: catalog-info.yaml
              pullRequestBranchName: backstage-integration
            rules:
              - allow: [Component, System, API, Resource, Location, Template]
            locations:
              - type: url
                target: https://github.com/stuttgart-things/backstage-resources/blob/main/org/sthings-dev/org.yaml
                rules:
                  - allow: [User, Group]
              - type: url
                target: https://github.com/stuttgart-things/backstage-resources/blob/main/services/sthings-dev/catalog-index.yaml
                rules:
                  - allow: [Component, Location, System, API, Resource, Template]
          kubernetes:
            serviceLocatorMethod:
              type: multiTenant
            clusterLocatorMethods:
              - type: localKubectlProxy
          permission:
            enabled: true
EOF
```

</details>

## USAGE

Each service can be deployed by writing a small Helmfile definition and then applying it.

```bash
# RENDER ONLY
helmfile template -f <service>.yaml

# APPLY
helmfile apply -f <service>.yaml

# DESTROY
helmfile destroy -f <service>.yaml
```
---
