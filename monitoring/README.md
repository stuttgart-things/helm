# stuttgart-things/helm/monitoring

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