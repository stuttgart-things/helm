# stuttgart-things/helm/cicd

<details><summary>FLUX-OPERATOR</summary>

```bash
cat <<EOF > flux-operator.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@cicd/flux-operator.yaml.gotmpl
EOF

helmfile template -f flux-operator.yaml # RENDER ONLY
helmfile apply -f flux-operator.yaml # APPLY HELMFILE # APPLY HELMFILE
```

</details>


<details><summary>CROSSPLANE</summary>

```bash
cat <<EOF > crossplane.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@cicd/crossplane.yaml.gotmpl
    values:
      - namespace: crossplane-system
      - providers:
          - xpkg.upbound.io/crossplane-contrib/provider-helm:v0.21.0
          - xpkg.upbound.io/crossplane-contrib/provider-kubernetes:v0.18.0
      - terraform:
          configName: tf-provider
          image: ghcr.io/stuttgart-things/images/sthings-cptf:1.12.0
          package: xpkg.upbound.io/upbound/provider-terraform
          version: v0.21.0
          poll: 10m
          reconcileRate: 10
          s3SecretName: s3
      - secrets:
          s3:
            namespace: crossplane-system
            kvs:
              AWS_ACCESS_KEY_ID: ref+vault://apps/artifacts/accessKey
              AWS_SECRET_ACCESS_KEY: ref+vault://apps/artifacts/secretKey
EOF

helmfile template -f crossplane.yaml # RENDER ONLY
helmfile apply -f crossplane.yaml # APPLY HELMFILE # APPLY HELMFILE
```

</details>

<details><summary>TEKTON</summary>

```bash
cat <<EOF > tekton.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@cicd/tekton.yaml.gotmpl
    values:
      - namespace: tekton-pipelines
EOF

helmfile template -f tekton.yaml # RENDER ONLY
helmfile apply -f tekton.yaml # APPLY HELMFILE
```

</details>

<details><summary>GHA-RUNNER-CONTROLLER</summary>

```bash
cat <<EOF > gha-runner-controller.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@cicd/gha-runner-controller.yaml
    values:
      - namespace: arc-systems

helmfile template -f gha-runner-controller.yaml# RENDER ONLY
helmfile apply -f gha-runner-controller.yaml # APPLY HELMFILE
EOF
```

</details>

<details><summary>GHA-RUNNER-SCALE-SET</summary>

```bash
cat <<EOF > gha-runner-scale-set.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@cicd/gha-runner-scale-set.yaml
    values:
      - repoName: ansible
      - namespace: arc-runner
      - githubRepoUrl: https://github.com/stuttgart-things/ansible
      - githubToken: <REPLACE-ME>
      - storageAccessMode: ReadWriteOnce
      - storageClassName: openebs-hostpath
      - storageRequest: 50Mi
      - runnerVersion: 2.323.0
      - ghaControllerNamespace: arc-systems
      - ghaControllerServiceAccount: gha-runner-scale-set-controller-gha-rs-controller
EOF

helmfile template -f gha-runner-scale-set.yaml # RENDER ONLY
helmfile apply -f gha-runner-scale-set.yaml # APPLY HELMFILE
```

</details>
