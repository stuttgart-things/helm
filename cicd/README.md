# stuttgart-things/helm/cicd

<details><summary>VCLUSTER</summary>

## DEPLOYMENT

```bash
cat <<EOF > vcluster.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@cicd/vcluster.yaml.gotmpl
    values:
      - clusterName: dev-cluster
      - namespace: vcluster
EOF
```

## CONNECT TO VCLUSTER

```bash
vcluster connect dev-cluster -n vcluster
```

</details>

<details><summary>ARGOCD</summary>

### GENERATE PASSWORD

```bash
sudo apt -y install apache2-utils
adminPassword=$(htpasswd -nbBC 10 "" 'Test2025!' | tr -d ':\n' | sed 's/$2y/$2a/')
adminPasswordMTime=$(echo $(date +%FT%T%Z))
```

### ARGOCD w/ VAULT PLUGIN

```bash
cat <<EOF > argocd.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@cicd/argocd.yaml.gotmpl
    values:
      - namespace: argocd
      - clusterIssuer: selfsigned
      - issuerKind: cluster-issuer
      - hostname: argocd
      - domain: 172.18.0.2.nip.io
      - ingressClassName: nginx
      - adminPassword: $2y$10$sX7RPXUpEQKjdi7hjyYI0e0r0dlfaM1JmmVmujd05Lx5CJpEqJomC
      - adminPasswordMTime: 2025-03-19T07:39:33UTC
      - enableAvp: true
      - vaultAddr: https://vault.172.18.0.2.nip.io
      - vaultNamespace: root
      - vaultRoleID: 1fa31949-8d0e-c100-c8ae-6eb287f8ea08
      - vaultSecretID: b76ddf4b-ba30-fc01-61fd-9d97588a6c09
      - imageHelfile: ghcr.io/helmfile/helmfile:v0.171.0
      - imageAvp: ghcr.io/stuttgart-things/sthings-avp:1.18.1-1.32.3-3.17.2
EOF

helmfile apply -f argocd.yaml # APPLY HELMFILE
```

### ARGOCD w/o VAULT PLUGIN + CERT CREATION OUTSIDE CERT-MANAGER

```bash
helmfile apply -f git::https://github.com/stuttgart-things/helm.git@cicd/argocd.yaml.gotmpl \
--state-values-set namespace=argocd \
--state-values-set issuerName=cluster-issuer-approle \
--state-values-set issuerKind=clusterIssuer \
--state-values-set domain=demo-infra.example.com \
--state-values-set ingressClassName=nginx \
--state-values-set adminPassword="$(htpasswd -nbBC 10 "" 'Test2025!' | tr -d ':\n' | sed 's/$2y/$2a/')" \
--state-values-set adminPasswordMTime="$(echo $(date +%FT%T%Z))" \
--state-values-set enableIngress=true \
--state-values-set enableAvp=false \
--state-values-set createCertificateResource=true \
--state-values-set issuerKind=ClusterIssuer
```

### ARGOCD w/o VAULT PLUGIN + w/o INGRESS

```bash
cat <<EOF > argocd.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@cicd/argocd.yaml.gotmpl
    values:
      - namespace: argocd
      - clusterIssuer: selfsigned
      - issuerKind: cluster-issuer
      - hostname: argocd
      - domain: 172.18.0.2.nip.io
      - ingressClassName: nginx
      - adminPassword: ""
      - adminPasswordMTime: ""
      - enableAvp: false
EOF

helmfile template -f argocd.yaml # RENDER ONLY
helmfile apply -f argocd.yaml # APPLY HELMFILE
```

</details>

<details><summary>KOMOPLANE</summary>

```bash
cat <<EOF > komoplane.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/komoplane.yaml
    values:
      - namespace: crossplane-system
      - clusterIssuer: selfsigned
      - issuerKind: cluster-issuer
      - hostname: komoplane
      - domain: 172.18.0.5.nip.io
      - ingressClassName: nginx
EOF
```

</details>

<details><summary>FLUX-OPERATOR</summary>

### DEPLOY FLUX-OPERATOR ONLY

```bash
cat <<EOF > flux-operator.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@cicd/flux-operator.yaml.gotmpl
    values:
      - version: 0.28.0
EOF

helmfile template -f flux-operator.yaml # RENDER ONLY
helmfile apply -f flux-operator.yaml # APPLY HELMFILE # APPLY HELMFILE
```

### DEPLOY FLUX-OPERATOR+SOPS+INSTANCE

```bash

```bash
cat <<EOF > flux-sops-instance.yaml
---
helmfiles:
  - path: /home/sthings/projects/apps/helm/cicd/flux-operator.yaml.gotmpl
    values:
      - version: 0.28.0
  - path: /home/sthings/projects/apps/helm/cicd/flux-operator.yaml.gotmpl
    values:
      - version: 0.28.0
      - installOperator: false
      - secrets:
         git-token-auth:
           namespace: flux-system
           kvs:
             username: {{ env "GITHUB_USER" }}
             password: {{ env "GITHUB_TOKEN" }}
         sops-age:
           namespace: flux-system
           kvs:
             age.agekey: "<REPLACE-ME>"
      - instance:
          name: flux-stuttgart-things
          gitUrl: https://github.com/stuttgart-things/stuttgart-things.git
          gitRef: refs/heads/main
          gitPath: clusters/stuttgart-things/clusters/vcluster/xplane
          gitTokenSecretRef: git-token-auth
          enableSops: true
```

</details>

<details><summary>CROSSPLANE</summary>

```bash
dagger call -m github.com/stuttgart-things/dagger/helm@v0.57.0 \ helmfile-operation \
--helmfile-ref "git::https://github.com/stuttgart-things/helm.git@cicd/crossplane.yaml.gotmpl" \
--operation apply \
--state-values "version=2.1.3" \
--kube-config file://config.yaml \
--progress plain -vv
```

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

### CRDS

```bash
kubectl apply -k https://github.com/stuttgart-things/helm/cicd/crds/tekton
```

### DEPLOY

```bash
cat <<EOF > tekton.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@cicd/tekton.yaml.gotmpl
    values:
      - namespace: tekton-operator
      - pipelineNamespace: tekton-pipelines
      - version: 0.77.5
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
