# Inventory cụm `new`

- Kubernetes: `1.35`
- Số namespace: 29
- Tổng resource trích xuất: 519

> Thông tin nhạy cảm và định danh công ty đã được che. Tra ngược placeholder ở `redaction-map.json` (không chia sẻ file này).


## Namespace `_cluster`



## Namespace `cattle-capi-system`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | capi-controller-manager | 1 | rancher/cluster-api-controller:v1.12.7 |

| Service | Type | Ports |
|---|---|---|
| capi-webhook-service | ClusterIP | 443 |

**ConfigMaps:** `capi-additional-rbac-roles`(1 keys), `core-cluster-api-v1.12.7`(1 keys), `<DOMAIN_7>`(1 keys)

**Secrets:** `capi-env-variables`(Opaque), `capi-webhook-service-cert`(<DOMAIN_43>/tls), `core-cluster-api-v1.12.7-cache`(Opaque)


## Namespace `cattle-fleet-clusters-system`

**ConfigMaps:** `<DOMAIN_7>`(1 keys)


## Namespace `cattle-fleet-local-system`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | fleet-agent | 1 | rancher/fleet-agent:v0.15.2 |

**ConfigMaps:** `fleet-agent`(1 keys), `<DOMAIN_7>`(1 keys)

**Secrets:** `fleet-agent`(Opaque), `<DOMAIN_55>-agent-local.v1`(<DOMAIN_56>/release.v1)


## Namespace `cattle-fleet-system`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | fleet-controller | 1 | rancher/fleet:v0.15.2, rancher/fleet:v0.15.2, rancher/fleet:v0.15.2 |
| Deployment | gitjob | 1 | rancher/fleet:v0.15.2 |
| Deployment | helmops | 1 | rancher/fleet:v0.15.2 |
| CronJob | fleet-cleanup-gitrepo-jobs | None | rancher/fleet:v0.15.2 |

| Service | Type | Ports |
|---|---|---|
| gitjob | ClusterIP | 80 |
| monitoring-fleet-controller | ClusterIP | 8080 |
| monitoring-gitjob | ClusterIP | 8081 |

**ConfigMaps:** `fleet-controller`(1 keys), `fleet-helm-url-regex-migrated`(0 keys), `known-hosts`(1 keys), `<DOMAIN_7>`(1 keys)

**Secrets:** `<DOMAIN_55>-crd.v1`(<DOMAIN_56>/release.v1), `<DOMAIN_55>.v214`(<DOMAIN_56>/release.v1), `<DOMAIN_55>.v215`(<DOMAIN_56>/release.v1), `<DOMAIN_55>.v216`(<DOMAIN_56>/release.v1), `<DOMAIN_55>.v217`(<DOMAIN_56>/release.v1), `<DOMAIN_55>.v218`(<DOMAIN_56>/release.v1)


## Namespace `cattle-global-data`

**ConfigMaps:** `<DOMAIN_7>`(1 keys)


## Namespace `cattle-impersonation-system`

**ConfigMaps:** `<DOMAIN_7>`(1 keys)

**Secrets:** `cattle-impersonation-u-b4qkhsnliz-token-cf7rg`(<DOMAIN_43>/service-account-token), `cattle-impersonation-u-mo773yttt4-token-bnb8m`(<DOMAIN_43>/service-account-token)


## Namespace `cattle-local-user-passwords`

**ConfigMaps:** `<DOMAIN_7>`(1 keys)

**Secrets:** `user-7qttr`(Opaque)


## Namespace `cattle-system`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | rancher | 3 | rancher/rancher:v2.14.2 |
| Deployment | rancher-webhook | 1 | rancher/rancher-webhook:v0.10.6 |

| Service | Type | Ports |
|---|---|---|
| imperative-api-extension | ClusterIP | 6666 |
| rancher | ClusterIP | 80, 443 |
| rancher-internal | ClusterIP | 443 |
| rancher-webhook | ClusterIP | 443 |

**ConfigMaps:** `ad-guid-migration`(2 keys), `admincreated`(2 keys), `forcelocalprojectcreation`(1 keys), `forcesystemnamespaceassignment`(1 keys), `forceupgradelogout`(1 keys), `<DOMAIN_7>`(1 keys), `managementnodecleanupmigration`(1 keys), `migratedynamicschematomachinepools`(1 keys), `migrateencryptionkeyrotationleadertostatus`(1 keys), `migratefrommachinetoplanesecret`(1 keys), `migrateimportedclustermanagedfields`(1 keys), `migratesystemagentvardirtodatadirectory`(1 keys), `rancher-charts-0-adf4953c-3b35-48b2-8bc2-689b7966d1b0`(0 keys), `rancher-charts-1-adf4953c-3b35-48b2-8bc2-689b7966d1b0`(0 keys), `rancher-config`(1 keys), `rancher-partner-charts-0-52e33908-b298-4c6e-b4e0-483e2ebd7be7`(0 keys), `rancher-partner-charts-1-52e33908-b298-4c6e-b4e0-483e2ebd7be7`(0 keys), `rancher-partner-charts-2-52e33908-b298-4c6e-b4e0-483e2ebd7be7`(0 keys), `rancher-rke2-charts-0-070d08b7-4052-4d4d-92a1-050c2fc4ee5b`(0 keys), `rkecleanupmigration`(1 keys)

**Secrets:** `bootstrap-secret`(Opaque), `cattle-webhook-ca`(<DOMAIN_43>/tls), `cattle-webhook-tls`(<DOMAIN_43>/tls), `imperative-api-sni-provider-cert-ca`(Opaque), `rancher-token-xnx5b`(<DOMAIN_43>/service-account-token), `serving-cert`(<DOMAIN_43>/tls), `<DOMAIN_59>-webhook.v13`(<DOMAIN_56>/release.v1), `<DOMAIN_59>-webhook.v14`(<DOMAIN_56>/release.v1), `<DOMAIN_59>-webhook.v15`(<DOMAIN_56>/release.v1), `<DOMAIN_59>-webhook.v16`(<DOMAIN_56>/release.v1), `<DOMAIN_59>-webhook.v17`(<DOMAIN_56>/release.v1), `<DOMAIN_59>.v1`(<DOMAIN_56>/release.v1), `tls-rancher`(<DOMAIN_43>/tls), `tls-rancher-internal`(<DOMAIN_43>/tls), `tls-rancher-internal-ca`(<DOMAIN_43>/tls)


## Namespace `cattle-tokens`

**ConfigMaps:** `<DOMAIN_7>`(1 keys), `kubeconfig-hdnzf`(7 keys)


## Namespace `cattle-turtles-system`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | rancher-turtles-controller-manager | 1 | rancher/turtles:v0.26.2 |

**ConfigMaps:** `cluster-api-operator-resources-cleanup-script`(1 keys), `clusterctl-config`(1 keys), `<DOMAIN_7>`(1 keys)

**Secrets:** `<DOMAIN_59>-turtles.v223`(<DOMAIN_56>/release.v1), `<DOMAIN_59>-turtles.v224`(<DOMAIN_56>/release.v1), `<DOMAIN_59>-turtles.v225`(<DOMAIN_56>/release.v1), `<DOMAIN_59>-turtles.v226`(<DOMAIN_56>/release.v1), `<DOMAIN_59>-turtles.v227`(<DOMAIN_56>/release.v1)


## Namespace `cattle-ui-plugin-system`

**ConfigMaps:** `<DOMAIN_7>`(1 keys)


## Namespace `cluster-fleet-local-local-1a3d67d0a899`

**ConfigMaps:** `<DOMAIN_7>`(1 keys)

**Secrets:** `request-9hwln-7eae5c5c-a101-4f02-92d4-63748c9c22fd-token`(<DOMAIN_43>/service-account-token)


## Namespace `default`

| Service | Type | Ports |
|---|---|---|
| kubernetes | ClusterIP | 443 |

**ConfigMaps:** `<DOMAIN_7>`(1 keys)

**PVCs:** `postgres-pvc`(1Gi,rook-ceph-block), `postgres-storage-postgres-0`(10Gi,rook-ceph-block)


## Namespace `fleet-default`

**ConfigMaps:** `<DOMAIN_7>`(1 keys)

**Secrets:** `auth-wzv72`(<DOMAIN_43>/basic-auth)


## Namespace `fleet-local`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| CronJob | rke2-machineconfig-cleanup-cronjob | None | rancher/rancher-agent:v2.14.2 |
| Job | rke2-machineconfig-cleanup-cronjob-29734565 | None | rancher/rancher-agent:v2.14.2 |
| Job | rke2-machineconfig-cleanup-cronjob-29736005 | None | rancher/rancher-agent:v2.14.2 |
| Job | rke2-machineconfig-cleanup-cronjob-29737445 | None | rancher/rancher-agent:v2.14.2 |

**ConfigMaps:** `<DOMAIN_7>`(1 keys), `rke2-machineconfig-cleanup-script`(1 keys), `shift-handover-config-7a1b46446d5d`(0 keys)

**Secrets:** `auth-dmplt`(<DOMAIN_43>/basic-auth), `local-kubeconfig`(Opaque)


## Namespace `harbor`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | harbor-core | 1 | docker.io/goharbor/harbor-core:v2.15.1 |
| Deployment | harbor-jobservice | 1 | docker.io/goharbor/harbor-jobservice:v2.15.1 |
| Deployment | harbor-nginx | 1 | docker.io/goharbor/nginx-photon:v2.15.1 |
| Deployment | harbor-portal | 1 | docker.io/goharbor/harbor-portal:v2.15.1 |
| Deployment | harbor-registry | 1 | docker.io/goharbor/registry-photon:v2.15.1, docker.io/goharbor/harbor-registryctl:v2.15.1 |
| StatefulSet | harbor-database | 1 | docker.io/goharbor/harbor-db:v2.15.1, docker.io/goharbor/harbor-db:v2.15.1 |
| StatefulSet | harbor-redis | 1 | docker.io/goharbor/redis-photon:v2.15.1 |
| StatefulSet | harbor-trivy | 1 | docker.io/goharbor/trivy-adapter-photon:v2.15.1 |

| Service | Type | Ports |
|---|---|---|
| harbor | ClusterIP | 80 |
| harbor-core | ClusterIP | 80 |
| harbor-database | ClusterIP | 5432 |
| harbor-jobservice | ClusterIP | 80 |
| harbor-portal | ClusterIP | 80 |
| harbor-redis | ClusterIP | 6379 |
| harbor-registry | ClusterIP | 5000, 8080 |
| harbor-trivy | ClusterIP | 8080 |

**ConfigMaps:** `harbor-core`(33 keys), `harbor-jobservice`(1 keys), `harbor-jobservice-env`(12 keys), `harbor-nginx`(1 keys), `harbor-portal`(1 keys), `harbor-registry`(2 keys), `harbor-registryctl`(0 keys), `<DOMAIN_7>`(1 keys)

**Secrets:** `harbor-core`(Opaque), `harbor-database`(Opaque), `harbor-jobservice`(Opaque), `harbor-registry`(Opaque), `harbor-registry-htpasswd`(Opaque), `harbor-registryctl`(Opaque), `harbor-trivy`(Opaque), `<DOMAIN_60>.v1`(<DOMAIN_56>/release.v1)

**PVCs:** `data-harbor-redis-0`(5Gi,rook-ceph-block), `data-harbor-trivy-0`(5Gi,rook-ceph-block), `database-data-harbor-database-0`(20Gi,rook-ceph-block), `harbor-jobservice`(1Gi,rook-ceph-block), `harbor-registry`(1500Gi,rook-ceph-block)


## Namespace `keycloak`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | postgres | 1 | <DOMAIN_30>.<COMPANY_DOMAIN>/postgres/postgres:17 |
| StatefulSet | keycloak | 2 | <DOMAIN_30>.<COMPANY_DOMAIN>/keycloak/keycloak:26.7.0 |

| Service | Type | Ports |
|---|---|---|
| keycloak | ClusterIP | 8080 |
| keycloak-discovery | ClusterIP |  |
| postgres | ClusterIP | 5432 |

**ConfigMaps:** `<DOMAIN_7>`(1 keys)


## Namespace `kube-node-lease` _(system)_

**ConfigMaps:** `<DOMAIN_7>`(1 keys)


## Namespace `kube-public` _(system)_

**ConfigMaps:** `cluster-info`(1 keys), `<DOMAIN_7>`(1 keys)


## Namespace `kube-system` _(system)_

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| DaemonSet | calico-node | None | quay.io/calico/node:v3.31.4, quay.io/calico/cni:v3.31.4, quay.io/calico/cni:v3.31.4, quay.io/calico/node:v3.31.4 |
| DaemonSet | kube-proxy | None | registry.k8s.io/kube-proxy:v1.35.1 |
| Deployment | calico-kube-controllers | 1 | quay.io/calico/kube-controllers:v3.31.4 |
| Deployment | coredns | 2 | registry.k8s.io/coredns/coredns:v1.13.1 |
| Deployment | metrics-server | 1 | registry.k8s.io/metrics-server/metrics-server:v0.8.1 |

| Service | Type | Ports |
|---|---|---|
| kube-dns | ClusterIP | 53, 53, 9153 |
| metrics-server | ClusterIP | 443 |

**ConfigMaps:** `calico-config`(4 keys), `coredns`(1 keys), `extension-apiserver-authentication`(6 keys), `kube-apiserver-legacy-service-account-token-tracking`(1 keys), `kube-proxy`(2 keys), `<DOMAIN_7>`(1 keys), `kubeadm-config`(1 keys), `kubelet-config`(1 keys)


## Namespace `local`

**ConfigMaps:** `<DOMAIN_7>`(1 keys)


## Namespace `otm`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | otm-be | 1 | <DOMAIN_30>.<COMPANY_DOMAIN>/otm/prd/be:22 |
| Deployment | otm-fe | 1 | <DOMAIN_30>.<COMPANY_DOMAIN>/otm/stg/fe:60 |
| StatefulSet | mysql | 1 | <DOMAIN_30>.<COMPANY_DOMAIN>/otm/db/mysql:5.6, <DOMAIN_30>.<COMPANY_DOMAIN>/otm/prd/xtrabackup:1.0, <DOMAIN_30>.<COMPANY_DOMAIN>/otm/db/mysql:5.6, <DOMAIN_30>.<COMPANY_DOMAIN>/otm/prd/xtrabackup:1.0 |
| Job | create-mysql-database | None | <DOMAIN_30>.<COMPANY_DOMAIN>/otm/db/mysql:5.6 |

| Service | Type | Ports |
|---|---|---|
| mysql-prd | ClusterIP | 3306 |
| otm-be | ClusterIP | 1080 |
| otm-fe | ClusterIP | 8080 |

**ConfigMaps:** `be-env-vars`(10 keys), `<DOMAIN_7>`(1 keys), `mysql`(2 keys)

**Secrets:** `harbor-registry-secret`(<DOMAIN_43>/dockerconfigjson), `mysql-root-pass`(Opaque), `otm-prd-be-secret`(Opaque)

**PVCs:** `otm-mysql-0`(30Gi,rook-ceph-block)


## Namespace `p-d874n`

**ConfigMaps:** `<DOMAIN_7>`(1 keys)


## Namespace `p-j78jh`

**ConfigMaps:** `<DOMAIN_7>`(1 keys)


## Namespace `passbolt`

**ConfigMaps:** `<DOMAIN_7>`(1 keys)


## Namespace `rook-ceph` _(system)_

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| DaemonSet | <DOMAIN_69>-nodeplugin | None | quay.io/cephcsi/cephcsi:v3.16.1, registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.15.0 |
| DaemonSet | <DOMAIN_52>-nodeplugin | None | quay.io/cephcsi/cephcsi:v3.16.1, registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.15.0 |
| Deployment | ceph-csi-controller-manager | 1 | quay.io/cephcsi/ceph-csi-operator:v0.5.0 |
| Deployment | rook-ceph-crashcollector-svim-53-123 | 1 | quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3 |
| Deployment | rook-ceph-crashcollector-svim-53-213 | 1 | quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3 |
| Deployment | rook-ceph-crashcollector-svim-53-230 | 1 | quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3 |
| Deployment | rook-ceph-exporter-svim-53-123 | 1 | quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3 |
| Deployment | rook-ceph-exporter-svim-53-213 | 1 | quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3 |
| Deployment | rook-ceph-exporter-svim-53-230 | 1 | quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3 |
| Deployment | rook-ceph-mgr-a | 1 | quay.io/ceph/ceph:v19.2.3, docker.io/rook/ceph:v1.19.2, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3 |
| Deployment | rook-ceph-mgr-b | 1 | quay.io/ceph/ceph:v19.2.3, docker.io/rook/ceph:v1.19.2, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3 |
| Deployment | rook-ceph-mon-a | 1 | quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3 |
| Deployment | rook-ceph-mon-b | 1 | quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3 |
| Deployment | rook-ceph-mon-c | 1 | quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3 |
| Deployment | rook-ceph-operator | 1 | docker.io/rook/ceph:v1.19.2 |
| Deployment | rook-ceph-osd-0 | 1 | quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3 |
| Deployment | rook-ceph-osd-1 | 1 | quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3, quay.io/ceph/ceph:v19.2.3 |
| Deployment | <DOMAIN_69>-ctrlplugin | 2 | quay.io/cephcsi/cephcsi:v3.16.1, registry.k8s.io/sig-storage/csi-provisioner:v6.0.0, registry.k8s.io/sig-storage/csi-resizer:v2.0.0, registry.k8s.io/sig-storage/csi-attacher:v4.10.0, registry.k8s.io/sig-storage/csi-snapshotter:v8.4.0 |
| Deployment | <DOMAIN_52>-ctrlplugin | 2 | quay.io/cephcsi/cephcsi:v3.16.1, registry.k8s.io/sig-storage/csi-provisioner:v6.0.0, registry.k8s.io/sig-storage/csi-resizer:v2.0.0, registry.k8s.io/sig-storage/csi-attacher:v4.10.0, registry.k8s.io/sig-storage/csi-snapshotter:v8.4.0 |
| Job | rook-ceph-osd-prepare-ceph-osd-set-data-0rxxds | None | quay.io/ceph/ceph:v19.2.3, docker.io/rook/ceph:v1.19.2, quay.io/ceph/ceph:v19.2.3 |
| Job | rook-ceph-osd-prepare-ceph-osd-set-data-1hvqrb | None | quay.io/ceph/ceph:v19.2.3, docker.io/rook/ceph:v1.19.2, quay.io/ceph/ceph:v19.2.3 |
| Job | rook-ceph-osd-prepare-svim-53-123 | None | quay.io/ceph/ceph:v19.2.3, docker.io/rook/ceph:v1.19.2 |
| Job | rook-ceph-osd-prepare-svim-53-213 | None | quay.io/ceph/ceph:v19.2.3, docker.io/rook/ceph:v1.19.2 |
| Job | rook-ceph-osd-prepare-svim-53-230 | None | quay.io/ceph/ceph:v19.2.3, docker.io/rook/ceph:v1.19.2 |

| Service | Type | Ports |
|---|---|---|
| rook-ceph-exporter | ClusterIP | 9926 |
| rook-ceph-mgr | ClusterIP | 9283 |
| rook-ceph-mgr-dashboard | ClusterIP | 8443 |
| rook-ceph-mon-a | ClusterIP | 6789, 3300 |
| rook-ceph-mon-b | ClusterIP | 6789, 3300 |
| rook-ceph-mon-c | ClusterIP | 6789, 3300 |

**ConfigMaps:** `ceph-csi-config`(1 keys), `<DOMAIN_7>`(1 keys), `rook-ceph-csi-mapping-config`(1 keys), `rook-ceph-mon-endpoints`(6 keys), `rook-ceph-operator-config`(36 keys), `rook-ceph-pdbstatemap`(3 keys), `rook-config-override`(1 keys), `rook-csi-operator-image-set-configmap`(7 keys)

**Secrets:** `cluster-peer-token-rook-ceph`(<DOMAIN_43>/rook), `pool-peer-token-replicapool`(<DOMAIN_43>/rook), `rook-ceph-admin-keyring`(<DOMAIN_43>/rook), `rook-ceph-config`(<DOMAIN_43>/rook), `rook-ceph-crash-collector-keyring`(<DOMAIN_43>/rook), `rook-ceph-dashboard-password`(<DOMAIN_43>/rook), `rook-ceph-exporter-keyring`(<DOMAIN_43>/rook), `rook-ceph-mgr-a-keyring`(<DOMAIN_43>/rook), `rook-ceph-mgr-b-keyring`(<DOMAIN_43>/rook), `rook-ceph-mon`(<DOMAIN_43>/rook), `rook-ceph-mons-keyring`(<DOMAIN_43>/rook), `rook-csi-cephfs-node`(<DOMAIN_43>/rook), `rook-csi-cephfs-provisioner`(<DOMAIN_43>/rook), `rook-csi-rbd-node`(<DOMAIN_43>/rook), `rook-csi-rbd-provisioner`(<DOMAIN_43>/rook)

**PVCs:** `ceph-osd-set-data-0rxxds`(2500Gi,local-blk), `ceph-osd-set-data-1hvqrb`(2500Gi,local-blk)


## Namespace `shift-handover`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | shift-handover-frontend | 1 | <DOMAIN_30>.<COMPANY_DOMAIN>/shift-handover/frontend/main:8 |
| StatefulSet | shift-handover-backend | 1 | <DOMAIN_30>.<COMPANY_DOMAIN>/shift-handover/backend/main:10 |
| StatefulSet | shift-handover-mongo | 1 | <DOMAIN_30>.<COMPANY_DOMAIN>/shift-handover/mongodb:6.0.5 |

| Service | Type | Ports |
|---|---|---|
| frontend | ClusterIP | 80 |
| mongodb | ClusterIP | 27017 |
| shift-handover-backend | ClusterIP | 3000 |

**ConfigMaps:** `<DOMAIN_7>`(1 keys), `mongodb-config`(1 keys)

**Secrets:** `be-secret`(Opaque), `fe-secret`(Opaque), `mongo-secret`(Opaque), `<DOMAIN_61>-handover.v28`(<DOMAIN_56>/release.v1), `<DOMAIN_61>-handover.v29`(<DOMAIN_56>/release.v1)

**PVCs:** `shift-handover-image-shift-handover-backend-0`(30Gi,rook-ceph-block), `shift-handover-storage-shift-handover-mongo-0`(30Gi,rook-ceph-block)


## Namespace `traefik` _(system)_

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| DaemonSet | traefik | None | docker.io/traefik:v3.7.6 |

| Service | Type | Ports |
|---|---|---|
| traefik | LoadBalancer | 80, 443 |

**ConfigMaps:** `<DOMAIN_7>`(1 keys)

**Secrets:** `dashboard-auth-secret`(<DOMAIN_43>/basic-auth), `local-selfsigned-tls`(<DOMAIN_43>/tls), `<DOMAIN_62>.v1`(<DOMAIN_56>/release.v1), `<DOMAIN_62>.v2`(<DOMAIN_56>/release.v1), `<COMPANY>-selfsigned-tls`(<DOMAIN_43>/tls)


## Namespace `user-7qttr`

**ConfigMaps:** `<DOMAIN_7>`(1 keys)
