# stuttgart-things/helm

Deploy Helm charts declaratively

| Category    | Description           |
|-------------|-----------------------|
| 💾 [DATABASES](./database/README.md)  | Database deployments |
| 📊 [MONITORING](./monitoring/README.md) | Monitoring stack setup |

## APPS

<details><summary>KYVERNO</summary>

```bash
cat <<EOF > kyverno.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/kyverno.yaml
    values:
      - namespace: kyverno
EOF

helmfile template -f kyverno.yaml # RENDER ONLY
helmfile apply -f kyverno.yaml # APPLY HELMFILE
```

</details>

<details><summary>FLUX-OPERATOR</summary>

```bash
cat <<EOF > flux-operator.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/flux-operator.yaml
    values:
      - namespace: flux-system
EOF

helmfile template -f flux-operator.yaml # RENDER ONLY
helmfile apply -f flux-operator.yaml # APPLY HELMFILE
```

</details>

<details><summary>HARBOR</summary>

```bash
cat <<EOF > harbor.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/harbor.yaml
    values:
      - namespace: harbor
      - enablePersistence: true
      - storageClass: standard
      - issuerName: selfsigned
      - issuerKindCert: ClusterIssuer
      - issuerKind: cluster-issuer
      - hostname: harbor
      - domain: 172.18.0.5.nip.io
      - ingressClassName: nginx
      - adminPassword: halloHarborTest123
      - pvSizeRegistry: 12Gi
      - pvSizeTrivy: 5Gi
      - pvSizeJobService: 1Gi
EOF

helmfile template -f harbor.yaml # RENDER ONLY
helmfile apply -f harbor.yaml # APPLY HELMFILE
```

</details>

<details><summary>MINIO</summary>

```bash
cat <<EOF > minio.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/minio.yaml
    values:
      - namespace: minio
      - clusterIssuer: selfsigned
      - issuerKind: cluster-issuer
      - domain: 172.18.0.2.nip.io
      - ingressClassName: nginx
      - rootUser: adminadmin
      - rootPassword: adminadmin
      - hostnameConsole: artifacts-console
      - hostnameApi: artifacts
      - storageClass: standard
EOF

helmfile template -f minio.yaml # RENDER ONLY
helmfile apply -f minio.yaml # APPLY HELMFILE
```

</details>

<details><summary>ARGOCD</summary>

### GENERATE PASSWORD

```bash
sudo apt -y install apache2-utils
adminPassword=$(htpasswd -nbBC 10 "" 'Test2025!' | tr -d ':\n')
adminPasswordMTime=$(echo $(date +%FT%T%Z))
```

### ARGOCD w/ VAULT PLUGIN

```bash
cat <<EOF > argocd.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/argocd.yaml
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

helmfile template -f argocd.yaml # RENDER ONLY
helmfile apply -f argocd.yaml # APPLY HELMFILE
```

### ARGOCD w/o VAULT PLUGIN

```bash
cat <<EOF > argocd.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/argocd.yaml
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

<details><summary>VAULT</summary>

### DEPLOY

```bash
cat <<EOF > vault.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/vault.yaml
    values:
      - namespace: vault
      - injectorEnabled: true
      - clusterIssuer: selfsigned
      - issuerKind: cluster-issuer
      - hostname: vault
      - domain: 172.18.0.2.nip.io
      - ingressClassName: nginx
EOF

helmfile template -f vault.yaml # RENDER ONLY
helmfile apply -f vault.yaml # APPLY HELMFILE
```

### UNSEAL

```bash
kubectl -n vault exec -it vault-server-0 -- vault operator init
kubectl -n vault exec -it vault-server-0 -- vault operator unseal <UNSEALKEY-X>
kubectl -n vault exec -it vault-server-0 -- vault operator unseal <UNSEALKEY-Y>
# ...
kubectl -n vault exec -it vault-server-0 -- vault status
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

helmfile template -f komoplane.yaml # RENDER ONLY
helmfile apply -f komoplane.yaml # APPLY HELMFILE
```

</details>

<details><summary>CLUSTERBOOK</summary>

```bash
cat <<EOF > clusterbook.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/clusterbook.yaml
    values:
      - namespace: clusterbook
      - enableIngress: true
      - enableCertificateRequest: true
      - ingressDomain: 172.18.0.5.nip.io
      - issuerKind: ClusterIssuer
      - issuerName: selfsigned
      - imageTag: v1.5.0 # pragma: allowlist secret
      - hostname: clusterbook
      - tlsSecretName: clusterbook-ingress-tls # pragma: allowlist secret
      - app: clusterbook
EOF

helmfile template -f clusterbook.yaml # RENDER ONLY
helmfile apply -f clusterbook.yaml # APPLY HELMFILE
```

</details>

<details><summary>AWX</summary>

### AWX-OPERATOR

```bash
cat <<EOF > awx-operator.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/awx-operator.yaml
    values:
      - namespace: awx
EOF

helmfile template -f awx-operator.yaml # RENDER ONLY
helmfile apply -f awx-operator.yaml # APPLY HELMFILE # APPLY HELMFILE
```

### AWX INSTANCE

```bash
cat <<EOF > awx.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/awx.yaml
    values:
      - namespace: awx
      - app: awx
      - ingressType: ingress
      - postgresStorageClass: standard
      - projectStorageClass: standard
      - clusterIssuer: selfsigned
      - secrets:
          sthings-admin-password:
            namespace: awx
            kvs:
              password: ref+vault://apps/awx/password-dev
          sthings-custom-certs:
            namespace: awx
            kvs:
              bundle-ca.crt: ref+vault://apps/awx/cabundle

      - instances:
          dev:
            name: awx-dev
            namespace: awx
            adminUser: sthings
            adminPasswordSecret: sthings-admin-password
            bundleCacertSecret: sthings-custom-certs
            hostname: awx-dev
            domain: 172.18.0.3.nip.io
            ingressClassName: nginx
            ingressSecret: awx-dev
            postgresStorageLimits: 8Gi
            postgresStorageRequest: 1Gi
            projectPersistence: false
            projectsStorageAccessMode: ReadWriteOnce
            fsGroupChangePolicy: OnRootMismatch
EOF

helmfile template -f awx.yaml # RENDER ONLY
helmfile apply -f awx.yaml # APPLY HELMFILE # APPLY HELMFILE
```

</details>

<details><summary>NGINX</summary>

### w/ LOADBALANCER

```bash
cat <<EOF > nginx-lb.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/nginx.yaml.gotmpl
    values:
      - profile: nginx
      - replicas: 1
      - serviceType: LoadBalancer
      - enableIngress: false
EOF

helmfile template -f nginx-lb.yaml # RENDER ONLY
helmfile apply -f nginx-lb.yaml # APPLY HELMFILE # APPLY HELMFILE
```

### w/ INGRESS + CERT

```bash
cat <<EOF > nginx.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@apps/nginx.yaml.gotmpl
    values:
      - namespace: nginx
      - profile: nginx
      - serviceType: ClusterIP
      - enableIngress: true
      - clusterIssuer: selfsigned
      - issuerKind: cluster-issuer
      - hostname: webserver
      - domain: dev3.172.18.0.3.nip.io
      - ingressClassName: nginx
EOF

helmfile template -f nginx.yaml # RENDER ONLY
helmfile apply -f nginx.yaml# APPLY HELMFILE # APPLY HELMFILE
```

</details>

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
EOF

helmfile template -f grafana.yaml # RENDER ONLY
helmfile apply -f grafana.yaml# APPLY HELMFILE # APPLY HELMFILE
```

</details>

## CICD

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

<details><summary>CROSSPLANE</summary>

```bash
cat <<EOF > crossplane.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@cicd/crossplane.yaml
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

## INFRA

<details><summary>OPENEBS</summary>

```bash
cat <<EOF > openebs.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/openebs.yaml
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

<details><summary>METALLB</summary>

```bash
cat <<EOF > metallb.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/metallb.yaml
    values:
      - version: 6.4.5
      - ipRange: 10.31.103.4-10.31.103.4 # EXAMPLE RANGE
EOF

helmfile template -f metallb.yaml # RENDER ONLY
helmfile apply -f metallb.yaml # APPLY HELMFILE
```

</details>

<details><summary>CILIUM</summary>

```bash
cat <<EOF > cilium.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/cilium.yaml
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

<details><summary>VELERO</summary>

```bash
cat <<EOF > velero.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/velero.yaml
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

<details><summary>CERT-MANAGER</summary>

### w/ SELF-SIGNED

```bash
cat <<EOF > cert-manager.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/cert-manager.yaml
    values:
      - version: v1.17.1
      - config: selfsigned
EOF

helmfile template -f cert-manager.yaml # RENDER ONLY
helmfile apply -f cert-manager.yaml # APPLY HELMFILE
```

### VAULT

```bash
cat <<EOF > cert-manager.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/cert-manager.yaml
    values:
      - config: vault
      - pkiServer: https://vault-vsphere.labul.example.com:8200
      - pkiPath: pki/sign/sthings-vsphere.labul.example.com
      - issuer: cluster-issuer-approle
      - approleSecret: ref+vault://apps/vault/secretID
      - approleID: ref+vault://apps/vault/roleID
      - pkiCA: ref+vault://apps/vault/vaultCA
EOF

export VAULT_AUTH_METHOD=approle
export VAULT_ADDR=https://<VAULT-URL>:8200
export VAULT_SECRET_ID=623c991f-d.. #example value
export VAULT_ROLE_ID=1d42d7e7-8.. #example value
export VAULT_NAMESPACE=root

helmfile template -f cert-manager.yaml # RENDER ONLY
helmfile apply -f ccert-manager.yaml # APPLY HELMFILE
```

</details>

<details><summary>INGRESS-NGINX</summary>

```bash
cat <<EOF > ingress-nginx.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/ingress-nginx.yaml
    values:
      - enableHostPort: false # for kind enable
EOF

helmfile template -f ingress-nginx.yaml # RENDER ONLY
helmfile apply -f ingress-nginx.yaml # APPLY HELMFILE
```

</details>

<details><summary>METRICS-SERVER</summary>

```bash
cat <<EOF > metrics-server.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/metrics-server.yaml
EOF

helmfile template -f metrics-server.yaml # RENDER ONLY
helmfile apply -f metrics-server.yaml # APPLY HELMFILE
```

</details>

<details><summary>LONGHORN</summary>

```bash
cat <<EOF > longhorn.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/longhorn.yaml
    values:
      - longhornDefaultClass: false
EOF

helmfile template -f longhorn.yaml # RENDER ONLY
helmfile apply -f longhorn.yaml# APPLY HELMFILE # APPLY HELMFILE
```

</details>

<details><summary>NFS-CSI</summary>

```bash
cat <<EOF > nfs-csi.yaml
---
helmfiles:
  - path: git::https://github.com/stuttgart-things/helm.git@infra/nfs-csi.yaml
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
  - path: git::https://github.com/stuttgart-things/helm.git@infra/nfs-server-provisioner.yaml
    values:
      - version: 1.8.0
EOF

helmfile template -f nfs-server-provisioner.yaml # RENDER ONLY
helmfile apply -f nfs-server-provisioner.yaml # APPLY HELMFILE
```

</details>

## USAGE/DEV

<details><summary>TASKS</summary>

```bash
task: Available tasks for this project:
* branch:                      Create branch from main
* check:                       Run pre-commit hooks
* commit:                      Commit + push code into branch
* create-test-app:             Switch to local branch
* pr:                          Create pull request into main
* release:                     push new version
* run-pre-commit-hook:         Run the pre-commit hook script to replace .example.com with .example.com
* switch-local:                Switch to local branch
* switch-remote:               Switch to remote branch
* tasks:                       Select a task to run
* tests-create-includes:       Create test files
* tests-render-includes:       Test render includes
```

</details>

<details><summary>HELMFILE</summary>

```bash
# INIT HELMFILE PLUGINS
helmfile init

# SET CACHE DIR AND EXECUTE HELMFILE OPERATION (WHICH IS PULLING)
export HELMFILE_CACHE_HOME=/tmp/helmfile/cache
helmfile template -f nginx.yaml

# CHECK DOWNLOAD GIT REPO STRUCTURE
ls -lta ${HELMFILE_CACHE_HOME}
# DELETE CACHE FOR TRY 'N ERROR W/ GIT SOURCES
rm -rf ${HELMFILE_CACHE_HOME}

helmfile template -f nginx.yaml
helmfile apply -f nginx.yaml
helmfile sync -f nginx.yaml
```

</details>

<details><summary>SOPS w/ AGE</summary>

### REQUIREMEMNTS

```bash
# REQUIREMEMNTS
sops --version
age --version

# GENERATE AN AGE KEY
age-keygen -o age-key.txt

# CREATE SOPS CONFIG
AGE_PUB_KEY=$(grep -oP '(?<=# public key: ).*' age-key.txt)
cat <<EOF > .sops.yaml
creation_rules:
  - path_regex: .*\.yaml
    age: "${AGE_PUB_KEY}$"
EOF

# SECRET EXAMPLE
cat <<EOF > secrets.yaml
webserver:
  url: test.example.com
EOF

sops --encrypt secrets.yaml > secrets.enc.yaml

export SOPS_AGE_KEY_FILE=age-key.txt
sops --decrypt secrets.enc.yaml
```

### USE SECRETS IN HELMFILE

```
cat <<EOF > nginx.yaml
---
environments:
  dev:
    secrets:
      - secrets.enc.yaml

releases:
  - name: nginx
    namespace: default
    chart: bitnami/nginx
    version: "15.5.0"
    values:
      - values.yaml.gotmpl
EOF

cat <<EOF > values.yaml.gotmpl
ingress:
  enabled: true
  hostname: {{ .Values.webserver.url }}
EOF

export SOPS_AGE_KEY_FILE=age-key.txt
helmfile template -f nginx.yaml -e dev
```

</details>

<details><summary>LOAD IMAGES INTO KIND CLUSTER</summary>

```bash
docker pull docker.io/bitnami/keycloak:26.3.1-debian-12-r1
kind load docker-image docker.io/bitnami/
keycloak:26.3.1-debian-12-r1 -n dev
```

</details>


<details><summary>TEMPLATE TEST</summary>

```bash
# LOCAL - NO INCLUDE
helmfile -f apps/grafana.yaml template \
--state-values-set createCertificateResource=false,ingressEnabled=false,hostname=test,domain=test.com,enablePersistence=false
```

```bash
TEST_DIR=/tmp/helmfiles
rm -rf ${TEST_DIR}/* && mkdir ${TEST_DIR} || true

app=$(yq '.template | keys | .[]' tests/helmfiles.yaml | gum choose)

machineshop render \
--source local \
--template tests/helmfiles.yaml \
--output file \
--kind multikey \
--key ${app} \
--destination ${TEST_DIR}/${app}.yaml \
--values "source=$(pwd)/${app}.yaml"

helmfile template ${TEST_DIR}/${app}.yaml
```

</details>

## LICENSE

<details><summary>APACHE LICENSE</summary>

```bash
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

</details>

## AUTHORS

```yaml
---
authors:
  - Patrick Hermann, stuttgart-things 03/2025
```
