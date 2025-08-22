# stuttgart-things/helm/infra

Infrastructure Helmfile templates for deploying common Kubernetes components.

---

## Usage

Each service can be deployed by writing a small Helmfile definition and then applying it.

```bash
# Render only
helmfile template -f <service>.yaml

# Apply
helmfile apply -f <service>.yaml
```

---

## SERVICES

<details><summary>OPENEBS</summary>

```bash
cat <<EOF > openebs.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/openebs.yaml.gotmpl
    values:
      - namespace: openebs-system
      - profile: localpv
      - openebs_volumesnapshots_enabled: false
      - openebs_csi_node_init_containers_enabled: false
      - openebs_local_lvm_enabled: false
      - openebs_local_zfs_enabled: false
      - openebs_replicated_mayastor_enabled: false
EOF

helmfile template -f openebs.yaml # RENDER ONLY
helmfile apply -f openebs.yaml # APPLY HELMFILE
```

</details>

<details><summary>CILIUM</summary>

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

helmfile template -f cilium.yaml # RENDER ONLY
helmfile apply -f cilium.yaml # APPLY HELMFILE
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

helmfile template -f ingress-nginx.yaml # RENDER ONLY
helmfile apply -f ingress-nginx.yaml # APPLY HELMFILE
```

</details>

<details><summary>CERT-MANAGER</summary>

### w/ SELF-SIGNED

```bash
cat <<EOF > cert-manager.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/cert-manager.yaml.gotmpl
    values:
      - version: v1.17.1
      - config: selfsigned
EOF

helmfile template -f cert-manager.yaml # RENDER ONLY
helmfile apply -f cert-manager.yaml # APPLY HELMFILE
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

helmfile template -f longhorn.yaml # RENDER ONLY
helmfile apply -f longhorn.yaml# APPLY HELMFILE # APPLY HELMFILE
```

</details>

<details><summary>METALLB</summary>

```bash
cat <<EOF > metallb.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/metallb.yaml.gotmpl
    values:
      - version: 6.4.5
      - ipRange: 10.31.103.4-10.31.103.4 # EXAMPLE RANGE
EOF

helmfile template -f metallb.yaml # RENDER ONLY
helmfile apply -f metallb.yaml # APPLY HELMFILE
```

</details>

<details><summary>METRICS-SERVER</summary>

```bash
cat <<EOF > metrics-server.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/metrics-server.yaml.gotmpl
EOF

helmfile template -f metrics-server.yaml # RENDER ONLY
helmfile apply -f metrics-server.yaml # APPLY HELMFILE
```

</details>

<details><summary>NFS-CSI</summary>

```bash
cat <<EOF > nfs-csi.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/nfs-csi.yaml.gotmpl
    values:
      - nfsServerFQDN: 10.31.101.26
      - nfsSharePath: /data/col1/sthings
      - clusterName: k3d-my-cluster
      - nfsSharePath: /data/col1/sthings
EOF

helmfile template -f nfs-csi.yaml # RENDER ONLY
helmfile apply -f nfs-csi.yaml # APPLY HELMFILE
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

helmfile template -f nfs-server-provisioner.yaml # RENDER ONLY
helmfile apply -f nfs-server-provisioner.yaml # APPLY HELMFILE
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

helmfile template -f velero.yaml # RENDER ONLY
helmfile sync -f velero.yaml # APPLY HELMFILE
```

</details>
