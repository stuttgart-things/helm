# stuttgart-things/helm/apps

<details><summary>GITEA</summary>

```bash
cat <<EOF > gitea.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/gitea.yaml.gotmpl
    values:
      - namespace: gitea
      - version: 12.1.3


EOF

helmfile template -f gitea.yaml # RENDER ONLY
helmfile apply -f gitea.yaml # APPLY HELMFILE
```

</details>
