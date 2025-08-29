# stuttgart-things/helm/apps

App Helmfile templates.

---

## SERVICES

<details><summary>REDIS-STACK</summary>

```bash
# BASIC
cat <<EOF > redis-stack.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/redis-stack.yaml.gotmpl
    values:
      - namespace: redis-stack
      - password: {{ env "REDIS_STACK_PASSWORD" | default "whateverpa$$w0rd" }}
      - storageClass: standard
EOF
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

### w/ INGRESS + CERT

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
