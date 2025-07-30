# stuttgart-things/helm/monitoring

<details><summary>GRAFANA</summary>

```bash
cat <<EOF > grafana.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/grafana.yaml
    values:
      - ingressEnabled: true
      - hostname: grafana.k8scluster
      - domain: sthings-vsphere.example.com
      - storageClassName: longhorn
      - size: 1 # storage size in Gi
      - clusterIssuer: cluster-issuer-approle
      - issuerKind: ClusterIssuer
      # - grafanaConfig: |
      #     server:
      #       protocol: http
      #       root_url: https://grafana.example.com
      #       serve_from_sub_path: false
EOF

helmfile template -f grafana.yaml # RENDER ONLY
helmfile apply -f grafana.yaml# APPLY HELMFILE # APPLY HELMFILE
```

</details>

<details><summary>HEADLAMP</summary>

```bash
cat <<EOF > headlamp.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@monitoring/headlamp.yaml.gotmpl
    values:
	  - ingressEnabled: true
	  - storageEnabled: false
	  - storageAccessModes: ReadWriteOnce
	  - hostname: headlamp.k8scluster
	  - domain: sthings-vsphere.example.com
    - storageClassName: longhorn
	  - clusterIssuer: cluster-issuer-approle
	  - issuerKind: ClusterIssuer
	  - storageSize: 1Gi
EOF

helmfile template -f headlamp.yaml # RENDER ONLY
helmfile apply -f headlamp.yaml # APPLY HELMFILE
```

```bash
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: headlamp-admin
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: headlamp-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: headlamp-admin
    namespace: kube-system
---
apiVersion: v1
kind: Secret
metadata:
  name: headlamp-admin-token
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: headlamp-admin
type: kubernetes.io/service-account-token
EOF

kubectl -n kube-system get secret headlamp-admin-token -o jsonpath='{.data.token}' | base64 -d; echo
```

</details>

<details><summary>PROMTAIL</summary>

```bash
# MAKE SURE TO SET THIS ON THE CLUSTER NODES
echo "fs.inotify.max_user_instances = 1024" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
sysctl fs.inotify
```

```bash
cat <<EOF > promtail.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@monitoring/promtail.yaml.gotmpl
    values:
      - namespace: observability
      - version: 6.17.0
      - lokiServiceName: loki-loki
      - lokiNamespace: observability
EOF

helmfile template -f promtail.yaml # RENDER ONLY
helmfile apply -f promtail.yaml # APPLY HELMFILE
```

</details>
