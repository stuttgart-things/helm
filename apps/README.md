# stuttgart-things/helm/apps

<details><summary>GITEA</summary>

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

helmfile template -f gitea.yaml # RENDER ONLY
helmfile apply -f gitea.yaml # APPLY HELMFILE
```

</details>
