# stuttgart-things/helm/infra

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
