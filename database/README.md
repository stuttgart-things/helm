# stuttgart-things/helm/database

<details><summary>LOKI</summary>

```bash
cat <<EOF > loki.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@database/loki.yaml.gotmpl
    values:
      - namespace: observability
      - version: 6.31.0
      - profile: fs
EOF

helmfile template -f loki.yaml # RENDER ONLY
helmfile apply -f loki.yaml # APPLY HELMFILE
```

</details>

<details><summary>OPENLDAP</summary>

```bash
cat <<EOF > openldap.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@datbase/openldap.yaml.gotmpl
    values:
      - adminUser: admin
      - ldapDomain: dc=sthings,dc=de
EOF

helmfile template -f openldap.yaml # RENDER ONLY
helmfile apply -f openldap.yaml # APPLY HELMFILE
```

</details>

<details><summary>ZOT </summary>

```bash
cat <<EOF > zot-registry.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@database/zot.yaml.gotmpl
    values:
      - version: 0.1.75
      - domain: example.com
      - storageClassName: openebs-hostpath
      - storageSize: 1Gi
      - clusterIssuer: cluster-issuer-approle
      - issuerKind: ClusterIssuer
EOF

helmfile template -f zot-registry.yaml # RENDER ONLY
helmfile apply -f zot-registry.yaml # APPLY HELMFILE
```

</details>

<details><summary>KEYCLOAK</summary>

```bash
cat <<EOF > keycloak.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@database/keycloak.yaml.gotmpl
    values:
      - ingressClassName: nginx
      - hostname: keycloak
      - domain: k8scluster.sthings-vsphere.example.com
      - adminUser: admin
      - adminPassword: <your-password>
      - storageClass: nfs4-csi
      - clusterIssuer: cluster-issuer-approle
      - issuerKind: ClusterIssuer
EOF

helmfile template -f keycloak.yaml # RENDER ONLY
helmfile apply -f keycloak.yaml # APPLY HELMFILE
```

```bash
cat <<EOF > keycloak-minimal.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@database/keycloak.yaml.gotmpl
    values:
      - clusterIssuer: selfsigned
      - domain: 172.18.0.4.nip.io
EOF

helmfile template -f keycloak-minimal.yaml # RENDER ONLY
helmfile apply -f keycloak-minimal.yaml # APPLY HELMFILE
```

</details>


<details><summary>REGISTRY</summary>

```bash
cat <<EOF > registry.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@database/registry.yaml.gotmpl
    values:
      # see @database/registry.yaml.gotmpl for more default values to overwrite
      - clusterIssuer: letsencrypt-prod
      - hostname: registry
      - projectStorageClass: vsphere-csi
      - domain: example.com
      - size: 10Gi
      # generate htpassd pw
      # sudo apt-get install apache2-utils   # Debian/Ubuntu
      # htpasswd -nbB admin admin
      - htpasswd: admin:$2y$05$lzjRgAlLIavPLxXi9Q7lnOcjW2rIIQXkeXU0Pj2kA7K9bMAYKianC
EOF

helmfile template -f registry.yaml # RENDER ONLY
helmfile apply -f registry.yaml # APPLY HELMFILE
```

```bash
# login w/ container runtime
docker login ${HOSTNAME}.${DOMAIN}

# list repos
curl -u ${USER}:${PASSWORD} -X GET https://${HOSTNAME}.${DOMAIN}/v2/_catalog | jq .repositories[]
# e.g. "python-app/my-python-app"

# list tags
REPO="python-app/my-python-app"
curl -u ${USER}:${PASSWORD} -X GET https://${HOSTNAME}.${DOMAIN}/v2/${REPO}$/tags/list

# DELETE IMAGE FROM REGISTRY
registry='https://${HOSTNAME}.${DOMAIN}'
repo_name='exampleimagename'
auth='--user ${USER}:${PASSWORD}'
curl $auth -v sSL -X DELETE "https://${registry}/v2/${repo_name}/manifests/$(
    curl $auth -sSL -I \
        -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        "https://${registry}/v2/${repo_name}/manifests/$(
            curl $auth -sSL "https://${registry}/v2/${repo_name}/tags/list" | jq -r '.tags[0]'
        )" \
    | awk '$1 == "Docker-Content-Digest:" { print $2 }' \
    | tr -d $'\r' \
)"
```

</details>

<details><summary>POSTGRES</summary>

### DEPLOY OPERATOR

```bash
cat <<EOF > postgres.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@database/postgres.yaml.gotmpl
    values:
      - namespace: postgres
      - version: 0.24.0
EOF

helmfile template -f postgres.yaml # RENDER ONLY
helmfile apply -f postgres.yaml # APPLY HELMFILE
```

### CONFIGURE INSTANCE (EXAMPLE)

```bash
kubectl apply -f - << EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: backstage
---
apiVersion: v1
kind: Secret
type: kubernetes.io/basic-auth
metadata:
  name: app-secret
  namespace: backstage
stringData:
  username: "" # pragma: allowlist secret
  password: "" # pragma: allowlist secret
---
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: backstage
  namespace: backstage
spec:
  instances: 1
  primaryUpdateStrategy: unsupervised
  storage:
    size: 1Gi
  bootstrap:
    initdb:
      secret:
        name: app-secret
      postInitSQL:
        - ALTER ROLE app CREATEDB
EOF
```

</details>