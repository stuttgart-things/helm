# stuttgart-things/helm/database

Database Helmfile templates for deploying common stateful services.

---

## SERVICES

<details><summary>REDIS-STACK</summary>

```bash
helmfile apply -f \
git::https://github.com/stuttgart-things/helm.git@database/redis-stack.yaml.gotmpl \
--state-values-set storageClass=openebs-hostpath \
--state-values-set password=<REPLACE-ME>
```

</details>

<details><summary>OPENLDAP</summary>

```bash
cat <<EOF > openldap.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@database/openldap.yaml.gotmpl
    values:
      - adminUser: admin
      - ldapDomain: dc=sthings,dc=de
EOF
```

</details>

<details><summary>ZOT </summary>

```bash
cat <<EOF > zot.yaml
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
      - domain: k8scluster.example.com
      - adminUser: admin
      - adminPassword: <your-password>
      - storageClass: nfs4-csi
      - clusterIssuer: cluster-issuer-approle
      - issuerKind: ClusterIssuer
EOF
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
```

</details>


<details><summary>REGISTRY</summary>

### DEPLOYMENT

```bash
cat <<EOF > registry.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@database/registry.yaml.gotmpl
    values:
      # see @database/registry.yaml.gotmpl for more defaults to overwrite
      - clusterIssuer: letsencrypt-prod
      - hostname: registry
      - projectStorageClass: vsphere-csi
      - domain: example.com
      - size: 10Gi
      # generate htpasswd password:
      # htpasswd -nbB admin admin
      - htpasswd: admin:$2y$05$lzjRgAlLIavPLxXi9Q7lnOcjW2rIIQXkeXU0Pj2kA7K9bMAYKianC
EOF
```

### USAGE EXAMPLES

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

<details><summary>POSTGRESDB</summary>

```bash
cat <<EOF > postgresdb.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@database/postgresdb.yaml.gotmpl
    values:
      - namespace: postgres
      - version: 16.7.26
EOF
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
