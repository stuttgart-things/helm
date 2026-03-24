# stuttgart-things/helm/infra

Infrastructure Helmfile templates for deploying common Kubernetes components.

---

## SERVICES

<details><summary>OPENEBS</summary>

```bash
# DEPLOY w/ DAGGER
dagger call -m github.com/stuttgart-things/dagger/helm@v0.57.0 \
helmfile-operation \
--helmfile-ref "git::https://github.com/stuttgart-things/helm.git@infra/openebs.yaml.gotmpl" \
--operation apply \
--state-values "namespace=openebs,profile=localpv" \
--kube-config file://config.yaml \
--progress plain -vv
```

```bash
# DEPLOY w/ HELMFILE
cat <<EOF > openebs.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/openebs.yaml.gotmpl
    values:
      - namespace: openebs
      - profile: localpv
EOF

helmfile template -f openebs.yaml # RENDER ONLY
helmfile apply -f openebs.yaml # APPLY HELMFILE
```

</details>

<details><summary>CILIUM</summary>

### CRDS

```bash
# w/ kubectl
kubectl apply -k https://github.com/stuttgart-things/helm/infra/crds/cilium
```

```bash
# w/ dagger
dagger call -m github.com/stuttgart-things/dagger/kubernetes@v0.57.0 kubectl \
--operation apply \
--kustomize-source https://github.com/stuttgart-things/helm/infra/crds/cilium \
--kube-config file://config.yaml
```

### KIND

```bash
cat <<EOF > cilium.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/cilium.yaml.gotmpl
    values:
      - config: kind
      - clusterName: helm-dev
      - configureLB: true
      - ipRangeStart: 172.18.250.0
      - ipRangeEnd: 172.18.250.50
EOF
```

```bash
# w/ dagger (kind)
dagger call -m github.com/stuttgart-things/dagger/helm@v0.57.0 helmfile-operation \
--helmfile-ref "git::https://github.com/stuttgart-things/helm.git@infra/cilium.yaml.gotmpl" \
--operation apply \
--state-values "config=kind,clusterName=dev,configureLB=false" \
--kube-config file://config.yaml \
--progress plain -vv
```

### K3S

```bash
cat <<EOF > cilium.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/cilium.yaml.gotmpl
    values:
      - config: k3s
      - clusterName: cluster1.labul.sva.de
      - networkDevice: ens192
      - configureLB: true
      - ipRangeStart: 10.31.103.50
      - ipRangeEnd: 10.31.103.80
EOF
```

```bash
# w/ dagger (k3s)
dagger call -m github.com/stuttgart-things/dagger/helm@v0.57.0 helmfile-operation \
--helmfile-ref "git::https://github.com/stuttgart-things/helm.git@infra/cilium.yaml.gotmpl" \
--operation apply \
--state-values "config=k3s,clusterName=cluster1.labul.sva.de,networkDevice=ens192,configureLB=false" \
--kube-config file://config.yaml \
--progress plain -vv
```

### DEPLOY w/ GATEWAY (DAGGER)

```bash
dagger call -m github.com/stuttgart-things/dagger/helm@v0.57.0 helmfile-operation \
--helmfile-ref "git::https://github.com/stuttgart-things/helm.git@infra/cilium.yaml.gotmpl" \
--operation apply \
--state-values "config=kind,clusterName=dev,configureLB=true,deployGateway=true,gatewayDomain=172.18.0.2.nip.io,gatewayTlsSecret=wildcard-tls,ipRangeStart=172.18.250.0,ipRangeEnd=172.18.250.50" \
--kube-config file://config.yaml \
--progress plain -vv
```

</details>

<details><summary>INGRESS-NGINX</summary>

```bash
cat <<EOF > ingress-nginx.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/ingress-nginx.yaml.gotmpl
    values:
      - enableHostPort: false # for kind enable
EOF
```

</details>

<details><summary>CERT-MANAGER</summary>

### w/ SELF-SIGNED (DAGGER)

```bash
dagger call -m github.com/stuttgart-things/dagger/helm@v0.57.0 \
helmfile-operation \
--helmfile-ref "git::https://github.com/stuttgart-things/helm.git@infra/cert-manager.yaml.gotmpl" \
--operation apply \
--state-values "version=v1.19.2,config=selfsigned" \
--kube-config file://config.yaml \
--progress plain -vv
```

### w/ SELF-SIGNED (HELMFILE)

```bash
cat <<EOF > cert-manager-selfsigned.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/cert-manager.yaml.gotmpl
    values:
      - version: v1.19.2
      - config: selfsigned
EOF

helmfile template -f cert-manager-selfsigned.yaml # RENDER ONLY
helmfile apply -f cert-manager-selfsigned.yaml # APPLY HELMFILE
```

### w/ VAULT-APPROLE (HELMFILE)

```bash
cat <<EOF > cert-manager-vault.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/cert-manager.yaml.gotmpl
    values:
      - version: v1.19.2
      - config: vault-approle
      - approleID: <APPROLE_ID>
      - approleSecret: {{ env "VAULT_SECRET_ID" }}
      - issuer: 4sthings
      - pkiPath: pki/sign/4sthings.example.com
      - pkiServer: https://vault-vsphere.example.com:8200
      - pkiCA: "LS0tLS1CRU..." # BASE64 CA CERT
EOF

helmfile apply -f cert-manager-vault.yaml # APPLY HELMFILE
```

</details>

<details><summary>TRUST-MANAGER</summary>

### DEPLOY (DAGGER)

```bash
dagger call -m github.com/stuttgart-things/dagger/helm@v0.57.0 \
helmfile-operation \
--helmfile-ref "git::https://github.com/stuttgart-things/helm.git@infra/trust-manager.yaml.gotmpl" \
--operation apply \
--state-values "version=0.22.0,namespace=cert-manager" \
--kube-config file://config.yaml \
--progress plain -vv
```

### DEPLOY w/ TRUST BUNDLE (HELMFILE)

```bash
cat <<EOF > trust-manager.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/trust-manager.yaml.gotmpl
    values:
      - namespace: cert-manager
      - version: 0.22.0
      - deployBundle: true
      - bundleName: cluster-trust-bundle
      - caSecret: cluster-ca-secret
      - caKey: ca.crt
      - vaultCaSecret: vault-pki-ca
      - vaultCaKey: ca.crt
      - trustBundleTargetKey: trust-bundle.pem
EOF

helmfile template -f trust-manager.yaml # RENDER ONLY
helmfile apply -f trust-manager.yaml # APPLY HELMFILE
```

</details>

<details><summary>LONGHORN</summary>

```bash
cat <<EOF > longhorn.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/longhorn.yaml.gotmpl
    values:
      - longhornDefaultClass: false
EOF
```

</details>

<details><summary>METALLB</summary>

```bash
cat <<EOF > metallb-deployment.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/metallb-deployment.yaml.gotmpl
    values:
      - version: 6.4.22
      - configureMetallb: false
      - deployMetallb: true
EOF

cat <<EOF > metallb-configuration.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/metallb-configuration.yaml.gotmpl
    values:
      - ipRange: 10.31.103.4-10.31.103.4 # EXAMPLE RANGE
      - configureMetallb: true
      - deployMetallb: false
EOF

helmfile apply -f metallb-deployment.yaml # APPLY DEPLOYMENT
kubectl wait --for=condition=Ready pods --all -n metallb-system --timeout=120s
helmfile apply -f metallb-configuration.yaml # APPLY CONFIGURATION
```

</details>

<details><summary>METRICS-SERVER</summary>

```bash
cat <<EOF > metrics-server.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/metrics-server.yaml.gotmpl
EOF
```

</details>

<details><summary>NFS-CSI</summary>

### DEPLOY (DAGGER)

```bash
dagger call -m github.com/stuttgart-things/dagger/helm@v0.57.0 \
helmfile-operation \
--helmfile-ref "git::https://github.com/stuttgart-things/helm.git@infra/nfs-csi.yaml.gotmpl" \
--operation apply \
--state-values "version=v4.13.1,nfsServerFQDN=10.31.101.26,nfsSharePath=/data/k8s/sthings,clusterName=app1" \
--kube-config file://config.yaml \
--progress plain -vv
```

### DEPLOY (HELMFILE)

```bash
cat <<EOF > nfs-csi.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/nfs-csi.yaml.gotmpl
    values:
      - nfsServerFQDN: 10.31.101.26
      - nfsSharePath: /data/k8s/sthings
      - clusterName: app1
EOF

helmfile template -f nfs-csi.yaml # RENDER ONLY
helmfile apply -f nfs-csi.yaml # APPLY HELMFILE
```

### OPTIONAL: CREATE NFS SERVER

```bash
# CREATE NFS DIR
sudo mkdir -p /opt/nfs
sudo chown nobody:nogroup /opt/nfs
sudo chmod 777 /opt/nfs
```

```bash
# CONFIGURE EXPORTS
sudo vi /etc/exports

# ADD NFS SERVER LIKE THIS
/opt/nfs *(rw,sync,no_subtree_check,no_root_squash)

sudo exportfs -rav
```

```bash
# INSTALL NFS-SERVER
sudo apt update -y
sudo apt install nfs-kernel-server -y
```

</details>

<details><summary>NFS-SERVER-PROVISIONER</summary>

```bash
cat <<EOF > nfs-server-provisioner.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/nfs-server-provisioner.yaml.gotmpl
    values:
      - version: 1.8.0
EOF
```

</details>

<details><summary>VELERO</summary>

```bash
cat <<EOF > velero.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/velero.yaml.gotmpl
    values:
      - namespace: velero
      - backupsEnabled: true
      - snapshotsEnabled: true
      - deployNodeAgent: true
      - s3StorageLocation: default
      - awsAccessKeyID: adminadmin
      - awsSecretAccessKey: adminadmin
      - s3Bucket: velero
      - s3CaCert: LS0tLS1TVIzQ1...S0tCg==
      - s3Location: artifacts.172.18.0.2.nip.io
      - imageAwsVeleroPlugin: velero/velero-plugin-for-aws:v1.11.1
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
