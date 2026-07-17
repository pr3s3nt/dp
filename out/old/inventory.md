# Inventory cụm `old`

- Kubernetes: `1.19`
- Số namespace: 122
- Tổng resource trích xuất: 1977

> Thông tin nhạy cảm và định danh công ty đã được che. Tra ngược placeholder ở `redaction-map.json` (không chia sẻ file này).


## Namespace `_cluster`



## Namespace `acs`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | acs-backend | 0 | <COMPANY>-<DOMAIN_607>/anticovid/<COMPANY>/backend:2143 |
| Deployment | acs-fe | 0 | <COMPANY>-<DOMAIN_607>/anticovid/<COMPANY>/frontend:327 |
| StatefulSet | acs-arangodb | 0 | <COMPANY>-<DOMAIN_607>/anticovid/base-images/arangodb:3.7.12 |
| StatefulSet | acs-redis | 0 | <COMPANY>-<DOMAIN_607>/anticovid/base-images/redis:4.0.9 |

| Service | Type | Ports |
|---|---|---|
| acs-arangodb-expose | ClusterIP | 19094 |
| acs-arangodb-service | ClusterIP | 8529 |
| acs-backend-expose | ClusterIP | 19095 |
| acs-backend-service | ClusterIP | 8080 |
| acs-fe-expose | ClusterIP | 80 |
| acs-redis-service | ClusterIP | 6379 |

**ConfigMaps:** `acs-frontend-conf`(1 keys)

**Secrets:** `default-token-mdsbg`(<DOMAIN_138>/service-account-token), `password-secret`(Opaque), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson)

**PVCs:** `acs-arangodb-data-acs-arangodb-0`(10Gi,ceph-block-replica-2)


## Namespace `actions-runner`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | runner-dap | 0 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/<COMPANY>-actions-runner:2.328.0 |
| Deployment | runner-feedback360 | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/<COMPANY>-actions-runner:2.328.0 |
| Deployment | runner-superset | 0 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/<COMPANY>-actions-runner:2.328.0 |
| Deployment | survey-doe-runner | 0 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/<COMPANY>-actions-runner:2.328.0 |


**Secrets:** `actions-runner-secret`(Opaque), `default-token-sdpck`(<DOMAIN_138>/service-account-token), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson), `runner-account-token-5f2hv`(<DOMAIN_138>/service-account-token), `secret-registry-image`(<DOMAIN_138>/dockerconfigjson)


## Namespace `argo-rollouts`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | argo-rollouts | 1 | <COMPANY>-<DOMAIN_607>/argocd/argo-rollouts:v1.2.0 |

| Service | Type | Ports |
|---|---|---|
| argo-rollouts-metrics | ClusterIP | 8090 |


**Secrets:** `argo-rollouts-notification-secret`(Opaque), `argo-rollouts-token-xk9pf`(<DOMAIN_138>/service-account-token), `default-token-zncbn`(<DOMAIN_138>/service-account-token), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson)


## Namespace `argocd` _(system)_

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | argocd-applicationset-controller | 1 | <COMPANY>-<DOMAIN_607>/argocd/argocd-applicationset:v0.4.1 |
| Deployment | argocd-dex-server | 1 | <COMPANY>-<DOMAIN_607>/argocd/dex:v2.30.2, <COMPANY>-<DOMAIN_607>/argocd/argocd:v2.3.1 |
| Deployment | argocd-notifications-controller | 1 | <COMPANY>-<DOMAIN_607>/argocd/argocd:v2.3.1 |
| Deployment | argocd-redis | 1 | <COMPANY>-<DOMAIN_607>/argocd/redis:6.2.6-alpine |
| Deployment | argocd-repo-server | 1 | <COMPANY>-<DOMAIN_607>/argocd/argocd:v2.3.1, <COMPANY>-<DOMAIN_607>/argocd/argocd:v2.3.1 |
| Deployment | argocd-server | 1 | <COMPANY>-<DOMAIN_607>/argocd/argocd:v2.3.1 |
| StatefulSet | argocd-application-controller | 1 | <COMPANY>-<DOMAIN_607>/argocd/argocd:v2.3.1 |

| Service | Type | Ports |
|---|---|---|
| argo-server | ClusterIP | 12746 |
| argocd-applicationset-controller | ClusterIP | 7000 |
| argocd-dex-server | ClusterIP | 5556, 5557, 5558 |
| argocd-metrics | ClusterIP | 8082 |
| argocd-notifications-controller-metrics | ClusterIP | 9001 |
| argocd-redis | ClusterIP | 6379 |
| argocd-repo-server | ClusterIP | 8081, 8084 |
| argocd-server | ClusterIP | 16443 |
| argocd-server-metrics | ClusterIP | 8083 |

| Ingress | Hosts | Paths |
|---|---|---|
| argocd-ingress | argocd.<COMPANY><DOMAIN_14> | / |
| argocd-ingress | argocd.<COMPANY><DOMAIN_14> | / |

**ConfigMaps:** `argocd-cm`(9 keys), `argocd-cmd-params-cm`(0 keys), `argocd-gpg-keys-cm`(0 keys), `argocd-notifications-cm`(0 keys), `argocd-rbac-cm`(1 keys), `argocd-ssh-known-hosts-cm`(1 keys), `argocd-tls-certs-cm`(0 keys), `artifact-repositories`(3 keys), `workflow-controller-configmap`(8 keys)

**Secrets:** `argo-postgres-config`(Opaque), `argo-server-sso`(Opaque), `argo-server-token-l24n6`(<DOMAIN_138>/service-account-token), `argo-token-jwnb9`(<DOMAIN_138>/service-account-token), `argo-workflows-webhook-clients`(Opaque), `argocd-application-controller-token-mwkg4`(<DOMAIN_138>/service-account-token), `argocd-applicationset-controller-token-nlxnl`(<DOMAIN_138>/service-account-token), `argocd-dex-server-token-vsdg4`(<DOMAIN_138>/service-account-token), `argocd-initial-admin-secret`(Opaque), `argocd-notifications-controller-token-958v6`(<DOMAIN_138>/service-account-token), `argocd-notifications-secret`(Opaque), `argocd-redis-token-8r6xp`(<DOMAIN_138>/service-account-token), `argocd-secret`(Opaque), `argocd-server-token-v8dtg`(<DOMAIN_138>/service-account-token), `<DOMAIN_548>-3396314289`(Opaque), `default-token-7dxrf`(<DOMAIN_138>/service-account-token), `github-sec`(Opaque), `<DOMAIN_16>-token-qsphr`(<DOMAIN_138>/service-account-token), `my-minio-cred`(Opaque), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson), `repo-248672320`(Opaque), `repo-3221240478`(Opaque), `repo-3780588281`(Opaque), `repo-429832155`(Opaque)

**PVCs:** `ci-example-tbgbc-workdir`(1Gi,None)


## Namespace `artifactory`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| StatefulSet | jfrog-container-registry-artifactory | 1 | <COMPANY>-<DOMAIN_607>/jfrog/artifactory-jcr:7.41.4, <COMPANY>-<DOMAIN_607>/jfrog/ubi-minimal:8.5-204, <COMPANY>-<DOMAIN_607>/jfrog/ubi-minimal:8.5-204, <COMPANY>-<DOMAIN_607>/jfrog/ubi-minimal:8.5-204, <COMPANY>-<DOMAIN_607>/jfrog/ubi-minimal:8.5-204, <COMPANY>-<DOMAIN_607>/jfrog/artifactory-jcr:7.41.4 |
| StatefulSet | jfrog-container-registry-postgresql | 1 | <COMPANY>-<DOMAIN_607>/jfrog/postgresql:13.4.0-debian-10-r39 |

| Service | Type | Ports |
|---|---|---|
| jfrog-container-registry-artifactory | ClusterIP | 8082, 8081 |
| jfrog-container-registry-expose | NodePort | 8082, 8081 |
| jfrog-container-registry-postgresql | ClusterIP | 5432 |
| jfrog-container-registry-postgresql-headless | ClusterIP | 5432 |

| Ingress | Hosts | Paths |
|---|---|---|
| jfrog-container-registry-artifactory | artifactory.<COMPANY><DOMAIN_14> | /, /artifactory |
| jfrog-container-registry-artifactory | artifactory.<COMPANY><DOMAIN_14> | /, /artifactory |

**ConfigMaps:** `jfrog-container-registry-artifactory-installer-info`(1 keys), `jfrog-container-registry-artifactory-migration-scripts`(3 keys), `jfrog-container-registry-postgresql-extended-configuration`(1 keys)

**Secrets:** `default-token-kvg5c`(<DOMAIN_138>/service-account-token), `jfrog-container-registry-artifactory`(Opaque), `jfrog-container-registry-artifactory-access-config`(Opaque), `jfrog-container-registry-artifactory-binarystore`(Opaque), `jfrog-container-registry-artifactory-systemyaml`(Opaque), `jfrog-container-registry-postgresql`(Opaque), `tls-artifactory`(<DOMAIN_138>/tls)

**PVCs:** `artifactory-volume-jfrog-container-registry-artifactory-0`(1Ti,ceph-block-replica-2), `data-jfrog-container-registry-postgresql-0`(500Gi,ceph-block-replica-2)


## Namespace `c-6tfcq`


**Secrets:** `default-token-lzkbx`(<DOMAIN_138>/service-account-token)


## Namespace `c-m-hqttxk4d`


**Secrets:** `default-token-4csx6`(<DOMAIN_138>/service-account-token)


## Namespace `cattle-fleet-clusters-system`


**Secrets:** `default-token-jtfwk`(<DOMAIN_138>/service-account-token)


## Namespace `cattle-fleet-local-system`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | fleet-agent | 1 | rancher/fleet-agent:v0.3.9 |

**ConfigMaps:** `fleet-agent`(1 keys), `fleet-agent-lock`(0 keys)

**Secrets:** `default-token-kq7pz`(<DOMAIN_138>/service-account-token), `fleet-agent`(Opaque), `fleet-agent-token-b9n4l`(<DOMAIN_138>/service-account-token), `<DOMAIN_550>-agent-local.v22`(<DOMAIN_152>/release.v1), `<DOMAIN_550>-agent-local.v23`(<DOMAIN_152>/release.v1), `<DOMAIN_550>-agent-local.v24`(<DOMAIN_152>/release.v1), `<DOMAIN_550>-agent-local.v25`(<DOMAIN_152>/release.v1), `<DOMAIN_550>-agent-local.v26`(<DOMAIN_152>/release.v1), `<DOMAIN_550>-agent-local.v27`(<DOMAIN_152>/release.v1), `<DOMAIN_550>-agent-local.v28`(<DOMAIN_152>/release.v1), `<DOMAIN_550>-agent-local.v29`(<DOMAIN_152>/release.v1), `<DOMAIN_550>-agent-local.v30`(<DOMAIN_152>/release.v1), `<DOMAIN_550>-agent-local.v31`(<DOMAIN_152>/release.v1)


## Namespace `cattle-fleet-system`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | fleet-controller | 1 | rancher/fleet:v0.3.9 |
| Deployment | gitjob | 1 | rancher/gitjob:v0.1.26 |

| Service | Type | Ports |
|---|---|---|
| gitjob | ClusterIP | 80 |

**ConfigMaps:** `fleet-controller`(1 keys), `fleet-controller-lock`(0 keys), `gitjob`(0 keys)

**Secrets:** `default-token-c47b2`(<DOMAIN_138>/service-account-token), `fleet-controller-bootstrap-token-9cf2t`(<DOMAIN_138>/service-account-token), `fleet-controller-token-bl9h5`(<DOMAIN_138>/service-account-token), `gitjob-token-tl2sz`(<DOMAIN_138>/service-account-token), `<DOMAIN_550>-crd.v1`(<DOMAIN_152>/release.v1), `<DOMAIN_550>-crd.v2`(<DOMAIN_152>/release.v1), `<DOMAIN_550>.v1`(<DOMAIN_152>/release.v1), `stv-aggregation`(Opaque)


## Namespace `cattle-global-data`


**Secrets:** `default-token-flzvt`(<DOMAIN_138>/service-account-token), `githubconfig-clientsecret`(Opaque)


## Namespace `cattle-global-nt`


**Secrets:** `default-token-9t84r`(<DOMAIN_138>/service-account-token)


## Namespace `cattle-impersonation-system`


**Secrets:** `cattle-impersonation-u-72uggsypy6-token-xvt6x`(<DOMAIN_138>/service-account-token), `cattle-impersonation-u-75yktoly4h-token-zdc78`(<DOMAIN_138>/service-account-token), `cattle-impersonation-u-b4qkhsnliz-token-t7bns`(<DOMAIN_138>/service-account-token), `cattle-impersonation-u-ef76duapmo-token-s44pw`(<DOMAIN_138>/service-account-token), `cattle-impersonation-u-f7c5naq566-token-x25bl`(<DOMAIN_138>/service-account-token), `cattle-impersonation-u-hybao3vlgk-token-vgkr2`(<DOMAIN_138>/service-account-token), `cattle-impersonation-u-mo773yttt4-token-d9l9n`(<DOMAIN_138>/service-account-token), `cattle-impersonation-u-muss3v2lek-token-7r8c8`(<DOMAIN_138>/service-account-token), `cattle-impersonation-u-nw4dme3klr-token-2nqs5`(<DOMAIN_138>/service-account-token), `cattle-impersonation-u-opuz4wfoda-token-zllvg`(<DOMAIN_138>/service-account-token), `cattle-impersonation-u-p7vaiakhge-token-fxww6`(<DOMAIN_138>/service-account-token), `cattle-impersonation-u-pdq5vm372s-token-lz4p7`(<DOMAIN_138>/service-account-token), `cattle-impersonation-u-pg7qxfe7lh-token-lflzp`(<DOMAIN_138>/service-account-token), `cattle-impersonation-user-9h9cp-token-qnfpn`(<DOMAIN_138>/service-account-token), `default-token-wl7tn`(<DOMAIN_138>/service-account-token)


## Namespace `cattle-logging`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| DaemonSet | rancher-logging-fluentd-linux | None | rancher/fluentd:v0.1.19, rancher/configmap-reload:v0.3.0-rancher2 |
| DaemonSet | rancher-logging-log-aggregator-linux | None | rancher/log-aggregator:v0.1.6 |

| Service | Type | Ports |
|---|---|---|
| rancher-logging-fluentd | ClusterIP | 24231 |

**ConfigMaps:** `rancher-logging.v1`(1 keys), `rancher-logging.v2`(1 keys), `rancher-logging.v3`(1 keys)

**Secrets:** `default-token-9ltnr`(<DOMAIN_138>/service-account-token), `rancher-logging-fluentd`(Opaque), `rancher-logging-fluentd-entry`(Opaque), `rancher-logging-fluentd-ssl`(Opaque), `rancher-logging-fluentd-token-w47zr`(<DOMAIN_138>/service-account-token), `rancher-logging-log-aggregator-token-wmjbf`(<DOMAIN_138>/service-account-token)


## Namespace `cattle-logging-system`


**Secrets:** `default-token-sjn8q`(<DOMAIN_138>/service-account-token), `rancher-logging-fluentd-output`(Opaque)


## Namespace `cattle-prometheus`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| DaemonSet | exporter-node-cluster-monitoring | None | rancher/prom-node-exporter:v1.0.1 |
| Deployment | exporter-kube-state-cluster-monitoring | 1 | rancher/coreos-kube-state-metrics:v1.9.7 |
| Deployment | grafana-cluster-monitoring | 1 | rancher/grafana-grafana:7.1.5, rancher/library-nginx:1.19.2-alpine, rancher/grafana-grafana:7.1.5, rancher/prometheus-auth:v0.2.0 |
| Deployment | prometheus-operator-monitoring-operator | 1 | rancher/coreos-prometheus-operator:v0.38.1 |
| StatefulSet | prometheus-cluster-monitoring | 1 | rancher/prom-prometheus:v2.18.2, rancher/coreos-prometheus-config-reloader:v0.38.1, rancher/jimmidyson-configmap-reload:v0.3.0, rancher/library-nginx:1.19.2-alpine, rancher/prometheus-auth:v0.2.0 |

| Service | Type | Ports |
|---|---|---|
| access-grafana | ClusterIP | 80 |
| access-prometheus | ClusterIP | 80 |
| expose-grafana-metrics | ClusterIP | 3000 |
| expose-kubelets-metrics | ClusterIP | 10250, 10255, 4194 |
| expose-kubernetes-metrics | ClusterIP | 8080, 8081 |
| expose-node-metrics | ClusterIP | 9796 |
| expose-operator-metrics | ClusterIP | 47323 |
| expose-prometheus-metrics | ClusterIP | 9090 |
| prometheus-operated | ClusterIP | 9090 |

**ConfigMaps:** `cluster-monitoring.v1`(1 keys), `cluster-monitoring.v2`(1 keys), `cluster-monitoring.v3`(1 keys), `cluster-monitoring.v4`(1 keys), `cluster-monitoring.v5`(1 keys), `grafana-cluster-monitoring-dashboards`(10 keys), `grafana-cluster-monitoring-nginx`(3 keys), `grafana-cluster-monitoring-provisionings`(2 keys), `grafana-istio-cluster-monitoring-dashboards`(8 keys), `monitoring-operator.v1`(1 keys), `monitoring-operator.v2`(1 keys), `monitoring-operator.v3`(1 keys), `monitoring-operator.v4`(1 keys), `operator-init-cluster-monitoring`(6 keys), `operator-init-monitoring-operator`(6 keys), `prometheus-cluster-monitoring-nginx`(2 keys), `prometheus-cluster-monitoring-rulefiles-0`(2 keys)

**Secrets:** `cluster-monitoring-token-t7xxs`(<DOMAIN_138>/service-account-token), `default-token-9gmjv`(<DOMAIN_138>/service-account-token), `exporter-kube-state-cluster-monitoring-token-gjn9f`(<DOMAIN_138>/service-account-token), `exporter-node-cluster-monitoring-token-s4drh`(<DOMAIN_138>/service-account-token), `operator-init-cluster-monitoring-token-gmcnd`(<DOMAIN_138>/service-account-token), `operator-init-monitoring-operator-token-b2gbg`(<DOMAIN_138>/service-account-token), `prometheus-cluster-monitoring`(Opaque), `prometheus-cluster-monitoring-additional-alertmanager-configs`(Opaque), `prometheus-cluster-monitoring-additional-scrape-configs`(Opaque), `prometheus-cluster-monitoring-tls-assets`(Opaque), `prometheus-operator-monitoring-operator-token-rrcl2`(<DOMAIN_138>/service-account-token)

**PVCs:** `grafana-cluster-monitoring`(1Gi,ceph-block-replica-2), `prometheus-cluster-monitoring-db-prometheus-cluster-monitoring-0`(100Gi,ceph-block-replica-2)


## Namespace `cattle-system`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | rancher | 1 | rancher/rancher:v2.5.0 |

| Service | Type | Ports |
|---|---|---|
| rancher | ClusterIP | 80 |
| rancher-expose | ClusterIP | 443 |

**ConfigMaps:** `admincreated`(0 keys)

**Secrets:** `cattle-credentials-a1d76e1`(Opaque), `cattle-token-5gdbj`(<DOMAIN_138>/service-account-token), `default-token-qskgj`(<DOMAIN_138>/service-account-token), `rancher-token-r84zj`(<DOMAIN_138>/service-account-token), `serving-cert`(<DOMAIN_138>/tls), `tls-rancher`(<DOMAIN_138>/tls), `u-2utyphfdjm-secret`(Opaque), `u-4mbr2dwdo7-secret`(Opaque), `u-5q56sn4em6-secret`(Opaque), `u-67ijcr2wgu-secret`(Opaque), `u-6gbwzee5vh-secret`(Opaque), `u-6xpr6cw7mr-secret`(Opaque), `u-72uggsypy6-secret`(Opaque), `u-75yktoly4h-secret`(Opaque), `u-7gfxvb5zzi-secret`(Opaque), `u-calvtkx4f6-secret`(Opaque), `u-e3fjjkktdf-secret`(Opaque), `u-ef76duapmo-secret`(Opaque), `u-flixo7vavq-secret`(Opaque), `u-fxdujzgdcg-secret`(Opaque), `u-h64k5dfghy-secret`(Opaque), `u-h6bzv6cz5c-secret`(Opaque), `u-hmcqfl44jz-secret`(Opaque), `u-ijvvl25jhe-secret`(Opaque), `u-jyof2tttrj-secret`(Opaque), `u-kgbnnz5oqk-secret`(Opaque), `u-ljehyqzo2v-secret`(Opaque), `u-lwl5hdrmbn-secret`(Opaque), `u-m6qmoqpsah-secret`(Opaque), `u-o2yezawj4t-secret`(Opaque), `u-o37she4kvi-secret`(Opaque), `u-pdq5vm372s-secret`(Opaque), `u-plobij3yiy-secret`(Opaque), `u-qigr7prtrk-secret`(Opaque), `u-qtpdcaqajg-secret`(Opaque), `u-rpo3xkrljc-secret`(Opaque), `u-rrfx36crkm-secret`(Opaque), `u-s3wceu2qkb-secret`(Opaque), `u-st5m57w3sg-secret`(Opaque), `u-taswvbmwbk-secret`(Opaque), `u-ulqmnp7jyh-secret`(Opaque), `u-v4ccd-secret`(Opaque), `u-wujwy735wz-secret`(Opaque), `u-wwwzr4dilo-secret`(Opaque), `u-xdqo56ujck-secret`(Opaque), `user-9h9cp-secret`(Opaque)


## Namespace `ceph`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | rook-ceph-crashcollector-svim-53-114 | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-crashcollector-svim-53-119 | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-crashcollector-svim-53-193 | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-crashcollector-svim-53-201 | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-mds-ceph-cephfs-a | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-mds-ceph-cephfs-b | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-mgr-a | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-mon-ai | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-mon-aj | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-mon-av | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-mon-w | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-mon-y | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-osd-0 | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-osd-1 | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-osd-2 | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-osd-3 | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-osd-4 | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-osd-5 | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-rgw-ceph-obj-store-1-a | 1 | ceph/ceph:v15.2.4, ceph/ceph:v15.2.4 |
| Deployment | rook-ceph-tools | 1 | rook/ceph:v1.4.2 |
| Job | rook-ceph-osd-prepare-svim-53-114 | None | ceph/ceph:v15.2.4, rook/ceph:v1.4.2 |
| Job | rook-ceph-osd-prepare-svim-53-119 | None | ceph/ceph:v15.2.4, rook/ceph:v1.4.2 |
| Job | rook-ceph-osd-prepare-svim-53-193 | None | ceph/ceph:v15.2.4, rook/ceph:v1.4.2 |
| Job | rook-ceph-osd-prepare-svim-53-201 | None | ceph/ceph:v15.2.4, rook/ceph:v1.4.2 |
| Job | rook-ceph-osd-prepare-svim-53-210 | None | ceph/ceph:v15.2.4, rook/ceph:v1.4.2 |

| Service | Type | Ports |
|---|---|---|
| rook-ceph-mgr | ClusterIP | 9283 |
| rook-ceph-mgr-dashboard | ClusterIP | 8443 |
| rook-ceph-mon-ai | ClusterIP | 6789, 3300 |
| rook-ceph-mon-aj | ClusterIP | 6789, 3300 |
| rook-ceph-mon-av | ClusterIP | 6789, 3300 |
| rook-ceph-mon-w | ClusterIP | 6789, 3300 |
| rook-ceph-mon-y | ClusterIP | 6789, 3300 |
| rook-ceph-rgw-ceph-obj-store-1 | ClusterIP | 80 |

**ConfigMaps:** `rook-ceph-csi-config`(1 keys), `rook-ceph-mon-endpoints`(4 keys), `rook-ceph-rgw-ceph-obj-store-1-mime-types`(1 keys), `rook-config-override`(1 keys)

**Secrets:** `default-token-j5h9n`(<DOMAIN_138>/service-account-token), `rook-ceph-admin-keyring`(<DOMAIN_138>/rook), `rook-ceph-cmd-reporter-token-gx4t8`(<DOMAIN_138>/service-account-token), `rook-ceph-config`(<DOMAIN_138>/rook), `rook-ceph-crash-collector-keyring`(<DOMAIN_138>/rook), `rook-ceph-dashboard-password`(<DOMAIN_138>/rook), `rook-ceph-mds-ceph-cephfs-a-keyring`(<DOMAIN_138>/rook), `rook-ceph-mds-ceph-cephfs-b-keyring`(<DOMAIN_138>/rook), `rook-ceph-mgr-a-keyring`(<DOMAIN_138>/rook), `rook-ceph-mgr-token-nm2sq`(<DOMAIN_138>/service-account-token), `rook-ceph-mon`(<DOMAIN_138>/rook), `rook-ceph-mons-keyring`(<DOMAIN_138>/rook), `rook-ceph-object-user-ceph-obj-store-1-spinnaker`(<DOMAIN_138>/rook), `rook-ceph-osd-0-keyring`(<DOMAIN_138>/rook), `rook-ceph-osd-1-keyring`(<DOMAIN_138>/rook), `rook-ceph-osd-2-keyring`(<DOMAIN_138>/rook), `rook-ceph-osd-3-keyring`(<DOMAIN_138>/rook), `rook-ceph-osd-4-keyring`(<DOMAIN_138>/rook), `rook-ceph-osd-5-keyring`(<DOMAIN_138>/rook), `rook-ceph-osd-token-bxl4c`(<DOMAIN_138>/service-account-token), `rook-ceph-rgw-ceph-obj-store-1-a-keyring`(<DOMAIN_138>/rook), `rook-csi-cephfs-node`(<DOMAIN_138>/rook), `rook-csi-cephfs-provisioner`(<DOMAIN_138>/rook), `rook-csi-rbd-node`(<DOMAIN_138>/rook), `rook-csi-rbd-provisioner`(<DOMAIN_138>/rook)


## Namespace `cert-manager` _(system)_


**Secrets:** `default-token-cwgvm`(<DOMAIN_138>/service-account-token)


## Namespace `cluster-fleet-local-local-1a3d67d0a899`


**Secrets:** `default-token-hq8vk`(<DOMAIN_138>/service-account-token), `request-d9t9m-887f6417-a513-4fe1-928a-0f9fb5bd65a2-token-lsrzt`(<DOMAIN_138>/service-account-token), `request-mnk27-30497d6a-97fb-4ab4-b365-f13413bdf125-token-hl668`(<DOMAIN_138>/service-account-token)


## Namespace `dap`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | dap | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/dap/prd/dap:c14adb2 |

| Service | Type | Ports |
|---|---|---|
| dap | ClusterIP | 4200, 3000 |

| Ingress | Hosts | Paths |
|---|---|---|
| dap-ingress | <DOMAIN_554>.<COMPANY><DOMAIN_14> | / |
| dap-ingress | <DOMAIN_554>.<COMPANY><DOMAIN_14> | / |


**Secrets:** `dap`(Opaque), `default-token-zvp2z`(<DOMAIN_138>/service-account-token), `postgres-secret`(Opaque), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson)

**PVCs:** `dap-prd-pvc`(10Gi,ceph-block-replica-2)


## Namespace `default`

| Service | Type | Ports |
|---|---|---|
| kubernetes | ClusterIP | 443 |

**ConfigMaps:** `fio-job-config`(1 keys), `fio-job-config-write`(1 keys)

**Secrets:** `default-token-qlr4g`(<DOMAIN_138>/service-account-token), `demo-token-sc527`(<DOMAIN_138>/service-account-token)

**PVCs:** `data-mysql-0`(30Gi,ceph-block-replica-2)


## Namespace `elk`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| DaemonSet | filebeat | None | <COMPANY>-<DOMAIN_607>/elk/filebeat:7.16.2 |
| Deployment | logstash | 1 | <COMPANY>-<DOMAIN_607>/elk/logstash:7.16.2 |
| StatefulSet | els | 1 | <COMPANY>-<DOMAIN_607>/elk/elasticsearch:7.16.2, <COMPANY>-<DOMAIN_607>/elk/elasticsearch:7.16.2 |
| StatefulSet | kibana | 1 | <COMPANY>-<DOMAIN_607>/elk/kibana:7.16.2 |

| Service | Type | Ports |
|---|---|---|
| els | ClusterIP | 9200 |
| kibana | ClusterIP | 5601 |
| logstash-service | ClusterIP | 25826, 5044, 9600 |

**ConfigMaps:** `els-conf`(1 keys), `filebeat-config`(1 keys), `kibana-conf`(1 keys), `logstash-configmap`(2 keys)

**Secrets:** `default-token-ckhjk`(<DOMAIN_138>/service-account-token), `els-password`(Opaque), `els-tls`(Opaque), `filebeat-token-gsdrk`(<DOMAIN_138>/service-account-token), `kibana-tls`(Opaque), `kibana-useraccess`(Opaque), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson)

**PVCs:** `elasticsearch-pvc-els-0`(100Gi,ceph-block-replica-2)


## Namespace `event-management`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | event-manage-be | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/event-management/backend:14 |
| Deployment | event-manage-fe | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/event-management/frontend:13 |
| StatefulSet | event-manage-db | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/mysql:5.6 |

| Service | Type | Ports |
|---|---|---|
| event-manage-be | ClusterIP | 5000 |
| event-manage-fe | ClusterIP | 80 |
| event-management-mysql-service | ClusterIP | 3306 |

| Ingress | Hosts | Paths |
|---|---|---|
| event-manage-ingress | event-management.<COMPANY><DOMAIN_14>, <DOMAIN_555>.<COMPANY><DOMAIN_14> | /, / |
| event-manage-ingress | event-management.<COMPANY><DOMAIN_14>, <DOMAIN_555>.<COMPANY><DOMAIN_14> | /, / |


**Secrets:** `be-secret`(Opaque), `default-token-rhfw2`(<DOMAIN_138>/service-account-token), `mysql-event-management-root-password`(Opaque), `secret-registry-image`(<DOMAIN_138>/dockerconfigjson)

**PVCs:** `event-manage-db-data-event-manage-db-0`(10Gi,ceph-block-replica-2)


## Namespace `face-reco`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | face-reco-ai | 0 | <COMPANY>-<DOMAIN_690>/face_reco/prod_<COMPANY>/face_reco_ai:v1.0.3-<COMPANY>, <COMPANY>-<DOMAIN_690>/face_reco/prod_<COMPANY>/face_reco_ai:v1.0.3-<COMPANY> |
| Deployment | face-reco-be | 0 | <COMPANY>-<DOMAIN_607>/face_reco/prod_<COMPANY>/face_reco_be:v1.0.5.0-<COMPANY> |
| Deployment | face-reco-fe | 0 | <COMPANY>-<DOMAIN_607>/face_reco/prod_<COMPANY>/face_reco_fe:v1.0.5.0-<COMPANY> |
| Deployment | mysql | 0 | <COMPANY>-<DOMAIN_690>/face_reco/mysql:5.7.35 |

| Service | Type | Ports |
|---|---|---|
| face-reco-be-svc | ClusterIP | 39061 |
| face-reco-fe-svc | ClusterIP | 39060 |
| mysql-service | ClusterIP | 3306 |

**ConfigMaps:** `face-reco-ai-cm`(12 keys), `face-reco-fe-cm`(1 keys), `mysql-cm`(2 keys)

**Secrets:** `default-token-ld2ts`(<DOMAIN_138>/service-account-token), `face-reco-be-secret`(Opaque), `mysql-secret`(Opaque), `regcred`(<DOMAIN_138>/dockerconfigjson), `regcred-bart`(<DOMAIN_138>/dockerconfigjson)


## Namespace `feedback360`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | feedback360-backend | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/feedback360/backend/backend_9:latest |
| Deployment | feedback360-frontend | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/feedback360/frontend/frontend_4:latest |
| StatefulSet | postgresql | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/postgres:16 |

| Service | Type | Ports |
|---|---|---|
| feedback360-be-service | ClusterIP | 8000 |
| feedback360-fe-service | ClusterIP | 80 |
| postgresql-service | ClusterIP | 5432 |

| Ingress | Hosts | Paths |
|---|---|---|
| feedback360 | feedback360.<COMPANY_DOMAIN>, <DOMAIN_556>.<COMPANY_DOMAIN> | /, / |
| feedback360 | feedback360.<COMPANY_DOMAIN>, <DOMAIN_556>.<COMPANY_DOMAIN> | /, / |

**ConfigMaps:** `mongodb-config`(1 keys)

**Secrets:** `be-secret`(Opaque), `default-token-tfw94`(<DOMAIN_138>/service-account-token), `jfrog-registry-secret`(<DOMAIN_138>/dockerconfigjson), `mongodb-secret`(Opaque), `postgres-secret`(Opaque), `registry-key-secret`(<DOMAIN_138>/dockerconfigjson)

**PVCs:** `feedback360-db-postgresql-0`(5Gi,ceph-block-replica-2), `mongodb-persistent-storage-feedback360-mongo-0`(5Gi,ceph-block-replica-2)


## Namespace `fem`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| StatefulSet | fem-prd-web | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fem/prd/fem:10 |

| Service | Type | Ports |
|---|---|---|
| fem-prd-web-expose | ClusterIP | 49200 |

| Ingress | Hosts | Paths |
|---|---|---|
| fem-ingress | fem.<COMPANY_DOMAIN> | / |
| fem-ingress | fem.<COMPANY_DOMAIN> | / |


**Secrets:** `default-token-frjwv`(<DOMAIN_138>/service-account-token), `fem-prd-secret`(Opaque), `regcred-bart`(<DOMAIN_138>/dockerconfigjson), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson)

**PVCs:** `fem-prd-pvc`(10Gi,ceph-block-replica-2), `fem-prd-pvc-2025-fem-prd-web-2025-0`(10Gi,ceph-cephfs)


## Namespace `fleet-default`


**Secrets:** `default-token-gd8nx`(<DOMAIN_138>/service-account-token)


## Namespace `fleet-local`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Job | ml-ops-4f56c | None | rancher/tekton-utils:v0.1.5, rancher/fleet-agent:v0.3.9, rancher/tekton-utils:v0.1.5, rancher/tekton-utils:v0.1.5 |

**ConfigMaps:** `ml-ops-config-f36a358183a8`(0 keys)

**Secrets:** `default-token-8jl6c`(<DOMAIN_138>/service-account-token), `git-ml-ops-token-t56g5`(<DOMAIN_138>/service-account-token), `local-cluster`(Opaque), `local-kubeconfig`(Opaque), `ml-ops`(<DOMAIN_138>/basic-auth)


## Namespace `fleet-system`


**Secrets:** `default-token-th775`(<DOMAIN_138>/service-account-token)


## Namespace `ingress-nginx` _(system)_

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | ingress-nginx-controller | 1 | registry.k8s.io/ingress-nginx/controller:v1.2.1@sha256:5516d103a9c2ecc4f026efbd4b40662ce22dc1f824fb129ed121460aaa5c47f8 |
| Job | ingress-nginx-admission-create | None | registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.1.1@sha256:64d8c73dca984af206adf9d6d7e46aa550362b1d7a01f3a0a91b20cc67868660 |
| Job | ingress-nginx-admission-patch | None | registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.1.1@sha256:64d8c73dca984af206adf9d6d7e46aa550362b1d7a01f3a0a91b20cc67868660 |

| Service | Type | Ports |
|---|---|---|
| ingress-nginx-controller | ClusterIP | 80, 443 |
| ingress-nginx-controller-admission | ClusterIP | 443 |
| ingress-nginx-controller-expose | ClusterIP | 80 |

**ConfigMaps:** `ingress-controller-leader`(0 keys), `ingress-nginx-controller`(1 keys)

**Secrets:** `default-token-pz6ft`(<DOMAIN_138>/service-account-token), `ingress-nginx-admission`(Opaque), `ingress-nginx-admission-token-5cs7n`(<DOMAIN_138>/service-account-token), `ingress-nginx-token-6jswp`(<DOMAIN_138>/service-account-token)


## Namespace `keycloak`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | orgchart | 0 | <COMPANY>-<DOMAIN_690>/passbolt/mysql:5.6 |
| StatefulSet | keycloak | 1 | <COMPANY>-<DOMAIN_607>/keycloak/keycloak:11.0.3 |
| StatefulSet | mysql-keycloak | 1 | <COMPANY>-<DOMAIN_607>/keycloak/mysql:5.6 |

| Service | Type | Ports |
|---|---|---|
| keycloak | ClusterIP | 48080, 18443 |
| keycloak-external | ClusterIP | 19097 |
| mysql-keycloak-svc | ClusterIP | 13306 |


**Secrets:** `default-token-f66fv`(<DOMAIN_138>/service-account-token), `keycloak-admin`(Opaque), `keycloak-database`(Opaque), `mysql-keycloak`(Opaque), `mysql-root-password`(Opaque), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson), `vault-auth`(<DOMAIN_138>/service-account-token), `vault-auth-token-zbqxm`(<DOMAIN_138>/service-account-token)

**PVCs:** `mysql-keycloak-mysql-keycloak-0`(10Gi,ceph-block-replica-2), `plugin-keycloak-keycloak-0`(20Gi,ceph-block-replica-2)


## Namespace `knox2fem`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | knox2fem | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/knox2fem/stg:18 |


**Secrets:** `default-token-279d9`(<DOMAIN_138>/service-account-token), `knox2fem-secret`(Opaque), `secret-registry-image`(<DOMAIN_138>/dockerconfigjson)


## Namespace `kube-node-lease` _(system)_


**Secrets:** `default-token-4ld55`(<DOMAIN_138>/service-account-token)


## Namespace `kube-public` _(system)_

**ConfigMaps:** `cluster-info`(1 keys)

**Secrets:** `default-token-mqtls`(<DOMAIN_138>/service-account-token)


## Namespace `kube-system` _(system)_

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| DaemonSet | calico-node | None | calico/node:v3.16.0, calico/cni:v3.16.0, calico/cni:v3.16.0, calico/pod2daemon-flexvol:v3.16.0 |
| DaemonSet | kube-proxy | None | k8s.gcr.io/kube-proxy:v1.19.0 |
| Deployment | calico-kube-controllers | 1 | calico/kube-controllers:v3.16.0 |
| Deployment | coredns | 2 | k8s.gcr.io/coredns:1.7.0 |
| StatefulSet | cerebro | 1 | <COMPANY>-<DOMAIN_690>/cerebro:0.9.2 |

| Service | Type | Ports |
|---|---|---|
| apm-server | ClusterIP | 8200 |
| cerebro | ClusterIP | 19000 |
| kube-dns | ClusterIP | 53, 53, 9153 |
| kubelet | ClusterIP | 10250, 10255, 4194 |

**ConfigMaps:** `calico-config`(4 keys), `cattle-agent-controllers`(0 keys), `cattle-controllers`(0 keys), `cerebro-conf`(2 keys), `coredns`(1 keys), `extension-apiserver-authentication`(6 keys), `kube-proxy`(2 keys), `kubeadm-config`(2 keys), `kubelet-config-1.19`(1 keys), `rancher-controller-lock`(0 keys)

**Secrets:** `argocd-manager-token-48bs6`(<DOMAIN_138>/service-account-token), `attachdetach-controller-token-674fd`(<DOMAIN_138>/service-account-token), `bootstrap-signer-token-l4kjq`(<DOMAIN_138>/service-account-token), `calico-kube-controllers-token-d7jqd`(<DOMAIN_138>/service-account-token), `calico-node-token-s8m4r`(<DOMAIN_138>/service-account-token), `certificate-controller-token-99h99`(<DOMAIN_138>/service-account-token), `clusterrole-aggregation-controller-token-jdnzh`(<DOMAIN_138>/service-account-token), `coredns-token-hx9xp`(<DOMAIN_138>/service-account-token), `cronjob-controller-token-9lv25`(<DOMAIN_138>/service-account-token), `daemon-set-controller-token-94w6c`(<DOMAIN_138>/service-account-token), `default-token-qwlbn`(<DOMAIN_138>/service-account-token), `deployment-controller-token-zrqtm`(<DOMAIN_138>/service-account-token), `disruption-controller-token-6z6g5`(<DOMAIN_138>/service-account-token), `elasticsearch-client-token-7mgkg`(<DOMAIN_138>/service-account-token), `elasticsearch-data-token-ln7g7`(<DOMAIN_138>/service-account-token), `elasticsearch-master-token-w88s4`(<DOMAIN_138>/service-account-token), `endpoint-controller-token-l2fct`(<DOMAIN_138>/service-account-token), `endpointslice-controller-token-gst5k`(<DOMAIN_138>/service-account-token), `endpointslicemirroring-controller-token-lfp86`(<DOMAIN_138>/service-account-token), `expand-controller-token-99qnp`(<DOMAIN_138>/service-account-token), `generic-garbage-collector-token-kbqwk`(<DOMAIN_138>/service-account-token), `horizontal-pod-autoscaler-token-sxnwn`(<DOMAIN_138>/service-account-token), `job-controller-token-26dvw`(<DOMAIN_138>/service-account-token), `kube-proxy-token-6d5v2`(<DOMAIN_138>/service-account-token), `namespace-controller-token-dncb2`(<DOMAIN_138>/service-account-token), `node-controller-token-gx6nt`(<DOMAIN_138>/service-account-token), `persistent-volume-binder-token-vx5wr`(<DOMAIN_138>/service-account-token), `pod-garbage-collector-token-jwdft`(<DOMAIN_138>/service-account-token), `pv-protection-controller-token-7k8xm`(<DOMAIN_138>/service-account-token), `pvc-protection-controller-token-d9rzj`(<DOMAIN_138>/service-account-token), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson), `replicaset-controller-token-zq9kq`(<DOMAIN_138>/service-account-token), `replication-controller-token-h27sp`(<DOMAIN_138>/service-account-token), `resourcequota-controller-token-zz4wg`(<DOMAIN_138>/service-account-token), `service-account-controller-token-bcmmc`(<DOMAIN_138>/service-account-token), `service-controller-token-qw2px`(<DOMAIN_138>/service-account-token), `statefulset-controller-token-sxjbv`(<DOMAIN_138>/service-account-token), `token-cleaner-token-7j7p9`(<DOMAIN_138>/service-account-token), `ttl-controller-token-4dg26`(<DOMAIN_138>/service-account-token)

**PVCs:** `elasticsearch-pvc-els-0`(100Gi,ceph-block-replica-2)


## Namespace `local`


**Secrets:** `default-token-glgrz`(<DOMAIN_138>/service-account-token)


## Namespace `moodle`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | moodle | 0 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/moodle:3.10.0-debian-10-r5 |
| Deployment | ubuntu | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/ubuntu:mantic-20230712 |

| Service | Type | Ports |
|---|---|---|
| moodle-expose-http | ClusterIP | 8080 |
| moodle-mariadb | ClusterIP | 3306 |

**ConfigMaps:** `moodle-mariadb`(1 keys)

**Secrets:** `default-token-652n5`(<DOMAIN_138>/service-account-token), `moodle`(Opaque), `moodle-mariadb`(Opaque), `moodle-mariadb-token-zsz9t`(<DOMAIN_138>/service-account-token), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson)

**PVCs:** `data-moodle-mariadb-0`(10Gi,ceph-block-replica-2), `moodle-moodle`(8Gi,ceph-block-replica-2)


## Namespace `moodle-v2`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | moodle | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/moodle:3.10.0-debian-10-r5 |
| Deployment | moodle-debug | 0 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/ubuntu:latest |
| StatefulSet | moodle-mariadb | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/moodle/mariadb:10.5.8-debian-10-r0 |

| Service | Type | Ports |
|---|---|---|
| moodle-expose-http | ClusterIP | 8080 |
| moodle-mariadb | ClusterIP | 3306 |

| Ingress | Hosts | Paths |
|---|---|---|
| moodle-ingress | training.<COMPANY_DOMAIN> | / |
| moodle-ingress | training.<COMPANY_DOMAIN> | / |

**ConfigMaps:** `moodle-mariadb`(1 keys)

**Secrets:** `default-token-ltksm`(<DOMAIN_138>/service-account-token), `moodle`(Opaque), `moodle-mariadb`(Opaque), `moodle-mariadb-token-n488z`(<DOMAIN_138>/service-account-token), `secret-registry-image`(<DOMAIN_138>/dockerconfigjson)

**PVCs:** `data-moodle-mariadb-0`(100Gi,ceph-block-replica-2), `moodle-moodle`(8Gi,ceph-block-replica-2)


## Namespace `okr`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | okr-backend | 1 | <COMPANY>-<DOMAIN_607>/okr/backend/okr_backend:37 |
| Deployment | okr-frontend | 1 | <COMPANY>-<DOMAIN_607>/okr/frontend/okr_frontend:28 |
| StatefulSet | okr-mysql | 1 | <COMPANY>-<DOMAIN_607>/okr/base-images/mysql:8.0.25 |
| StatefulSet | okr-redis | 1 | <COMPANY>-<DOMAIN_607>/okr/base-images/redis:6.2.4 |

| Service | Type | Ports |
|---|---|---|
| okr-be-expose | ClusterIP | 49206 |
| okr-fe-expose | ClusterIP | 49222 |
| okr-mysql-service | ClusterIP | 3306 |
| okr-nginx-expose | ClusterIP | 80 |
| okr-redis-service | ClusterIP | 6379 |

| Ingress | Hosts | Paths |
|---|---|---|
| okr-ingress | okr-old.<COMPANY_DOMAIN> | / |
| okr-ingress | okr-old.<COMPANY_DOMAIN> | / |

**ConfigMaps:** `mysql-conf`(1 keys), `okr-frontend-conf`(1 keys), `okr-nginx-conf`(1 keys)

**Secrets:** `default-token-k98ks`(<DOMAIN_138>/service-account-token), `mysql-root-password`(Opaque), `okr-be-secret`(Opaque), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson)

**PVCs:** `okr-mysql-data-okr-mysql-0`(10Gi,ceph-block-replica-2)


## Namespace `okr-dep`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | okr-backend | 1 | <COMPANY>-<DOMAIN_607>/okr/backend/okr_backend:16 |
| Deployment | okr-frontend | 1 | <COMPANY>-<DOMAIN_607>/okr/frontend/okr_frontend:193 |
| StatefulSet | okr-mysql | 1 | <COMPANY>-<DOMAIN_607>/okr/base-images/mysql:8.0.25 |
| StatefulSet | okr-redis | 1 | <COMPANY>-<DOMAIN_607>/okr/base-images/redis:6.2.4 |

| Service | Type | Ports |
|---|---|---|
| okr-be-expose | ClusterIP | 8080 |
| okr-fe-expose | ClusterIP | 80 |
| okr-mysql-service | ClusterIP | 3306 |
| okr-redis-service | ClusterIP | 6379 |

| Ingress | Hosts | Paths |
|---|---|---|
| okr-ingress | okr.<COMPANY_DOMAIN> | / |
| okr-ingress | okr.<COMPANY_DOMAIN> | / |

**ConfigMaps:** `mysql-conf`(1 keys), `okr-frontend-conf`(1 keys)

**Secrets:** `default-token-bkdmg`(<DOMAIN_138>/service-account-token), `mysql-root-password`(Opaque), `okr-be-secret`(Opaque), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson)

**PVCs:** `okr-mysql-data-okr-mysql-0`(5Gi,ceph-block-replica-2)


## Namespace `opn`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | opn | 0 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/opn/stg:34 |


**Secrets:** `default-token-5mjb7`(<DOMAIN_138>/service-account-token), `opn-secret`(Opaque), `secret-registry-image`(<DOMAIN_138>/dockerconfigjson)


## Namespace `otm`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | otm-be | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/otm/prd/be:22 |
| Deployment | otm-fe | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/otm/stg/fe:60 |
| StatefulSet | mysql | 1 | <COMPANY>-<DOMAIN_607>/otm/base-images/mysql:5.6, <COMPANY>-<DOMAIN_607>/otm/base-images/gcr.io/google-samples/xtrabackup:1.0, <COMPANY>-<DOMAIN_607>/otm/base-images/mysql:5.6, <COMPANY>-<DOMAIN_607>/otm/base-images/gcr.io/google-samples/xtrabackup:1.0 |

| Service | Type | Ports |
|---|---|---|
| mysql-prd | ClusterIP | 3306 |
| mysql-read | ClusterIP | 3306 |
| otm-be | NodePort | 1080 |
| otm-fe | NodePort | 8080 |

| Ingress | Hosts | Paths |
|---|---|---|
| otm-be | otmbe.<COMPANY_DOMAIN> | / |
| otm-ingress | otm.<COMPANY_DOMAIN> | / |
| otm-be | otmbe.<COMPANY_DOMAIN> | / |
| otm-ingress | otm.<COMPANY_DOMAIN> | / |

**ConfigMaps:** `be-env-vars`(10 keys), `be-env-vars-v000`(8 keys), `be-env-vars-v001`(10 keys), `mysql`(2 keys)

**Secrets:** `default-token-8w5xv`(<DOMAIN_138>/service-account-token), `mysql-root-pass`(Opaque), `otm-prd-be-secret`(Opaque), `otm-prd-be-secret-v000`(Opaque), `otm-pull-image`(<DOMAIN_138>/dockerconfigjson), `registry-secret`(<DOMAIN_138>/dockerconfigjson), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson), `secret-registry-image`(<DOMAIN_138>/dockerconfigjson)

**PVCs:** `data-2-mysql-0`(30Gi,ceph-block-replica-2), `data-3-mysql-0`(30Gi,ceph-block-replica-2), `data-mysql-0`(30Gi,ceph-block-replica-2)


## Namespace `p-67wv8`


**Secrets:** `default-token-wst89`(<DOMAIN_138>/service-account-token)


## Namespace `p-c6t6q`


**Secrets:** `default-token-cvm8l`(<DOMAIN_138>/service-account-token)


## Namespace `p-mjh6x`


**Secrets:** `default-token-gs9k2`(<DOMAIN_138>/service-account-token)


## Namespace `p-t2pmj`


**Secrets:** `default-token-twg4b`(<DOMAIN_138>/service-account-token)


## Namespace `p-v75v8`


**Secrets:** `default-token-2b2lk`(<DOMAIN_138>/service-account-token)


## Namespace `p-wnc8s`


**Secrets:** `default-token-rh4fl`(<DOMAIN_138>/service-account-token)


## Namespace `passbolt`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| StatefulSet | mysql | 1 | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| StatefulSet | passbolt | 1 | <COMPANY>-<DOMAIN_607>/passbolt/passbolt_v2_12:20200709 |
| StatefulSet | passbolt-client | 1 | <COMPANY>-<DOMAIN_607>/passbolt/passbolt-client:v2 |

| Service | Type | Ports |
|---|---|---|
| mysql | ClusterIP | 3306 |
| passbolt-svc | ClusterIP | 1386 |


**Secrets:** `default-token-44c5b`(<DOMAIN_138>/service-account-token), `mysql-passbolt-password`(Opaque), `mysql-root-password`(Opaque), `passbolt-key-fingerprint`(Opaque), `passbolt-token-bqvvl`(<DOMAIN_138>/service-account-token), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson)

**PVCs:** `mysql-pv-mysql-0`(50Gi,ceph-block-replica-2), `passbolt-pv-passbolt-0`(2Gi,ceph-block-replica-2)


## Namespace `passbolt-v4`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| StatefulSet | mysql | 1 | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| StatefulSet | passbolt | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/passbolt/prd:1 |
| Job | passbolt-mysql-auto-backup-1782470400 | None | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| Job | passbolt-mysql-auto-backup-1782470520 | None | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| Job | passbolt-mysql-auto-backup-1784052000 | None | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| Job | passbolt-mysql-auto-backup-1784138400 | None | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| Job | passbolt-mysql-auto-backup-1784224800 | None | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| Job | passbolt-mysql-cleanup-backup-1784055600 | None | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| Job | passbolt-mysql-cleanup-backup-1784142000 | None | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| Job | passbolt-mysql-cleanup-backup-1784228400 | None | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| CronJob | passbolt-mysql-auto-backup | None | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| CronJob | passbolt-mysql-cleanup-backup | None | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |

| Service | Type | Ports |
|---|---|---|
| mysql | ClusterIP | 3306 |
| passbolt-svc | ClusterIP | 6831 |

| Ingress | Hosts | Paths |
|---|---|---|
| passbolt-v4-ingress | passboltv4.<COMPANY><DOMAIN_14> | / |
| passbolt-v4-ingress | passboltv4.<COMPANY><DOMAIN_14> | / |


**Secrets:** `default-token-s5nrv`(<DOMAIN_138>/service-account-token), `mysql-passbolt-password`(Opaque), `mysql-root-password`(Opaque), `passbolt-key-fingerprint`(Opaque), `passbolt-token-plffr`(<DOMAIN_138>/service-account-token), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson), `secret-registry-image`(<DOMAIN_138>/dockerconfigjson)

**PVCs:** `mysql-pv-mysql-0`(50Gi,ceph-block-replica-2), `mysql-pv-mysql-1`(50Gi,ceph-block-replica-2), `passbolt-mysql-backup-pvc`(1Gi,None), `passbolt-pv-passbolt-0`(2Gi,ceph-block-replica-2)


## Namespace `portal`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | portal | 1 | <COMPANY>-<DOMAIN_607>/portal/<COMPANY>-devops-portal:v5 |

| Service | Type | Ports |
|---|---|---|
| portal-expose | ClusterIP | 12380 |

| Ingress | Hosts | Paths |
|---|---|---|
| portal-ingress | portal.<COMPANY><DOMAIN_14> | / |
| portal-ingress | portal.<COMPANY><DOMAIN_14> | / |


**Secrets:** `default-token-fzlfx`(<DOMAIN_138>/service-account-token), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson)


## Namespace `rancher-operator-system`


**Secrets:** `default-token-79576`(<DOMAIN_138>/service-account-token)


## Namespace `rook-ceph` _(system)_

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| DaemonSet | csi-cephfsplugin | None | quay.io/k8scsi/csi-node-driver-registrar:v1.2.0, quay.io/cephcsi/cephcsi:v3.1.0, quay.io/cephcsi/cephcsi:v3.1.0 |
| DaemonSet | csi-rbdplugin | None | quay.io/k8scsi/csi-node-driver-registrar:v1.2.0, quay.io/cephcsi/cephcsi:v3.1.0, quay.io/cephcsi/cephcsi:v3.1.0 |
| DaemonSet | rook-ceph-agent | None | rook/ceph:v1.4.2 |
| DaemonSet | rook-discover | None | rook/ceph:v1.4.2 |
| Deployment | csi-cephfsplugin-provisioner | 2 | quay.io/k8scsi/csi-attacher:v2.1.0, quay.io/k8scsi/csi-snapshotter:v2.1.1, quay.io/k8scsi/csi-resizer:v0.4.0, quay.io/k8scsi/csi-provisioner:v1.6.0, quay.io/cephcsi/cephcsi:v3.1.0, quay.io/cephcsi/cephcsi:v3.1.0 |
| Deployment | csi-rbdplugin-provisioner | 2 | quay.io/k8scsi/csi-provisioner:v1.6.0, quay.io/k8scsi/csi-resizer:v0.4.0, quay.io/k8scsi/csi-attacher:v2.1.0, quay.io/k8scsi/csi-snapshotter:v2.1.1, quay.io/cephcsi/cephcsi:v3.1.0, quay.io/cephcsi/cephcsi:v3.1.0 |
| Deployment | rook-ceph-operator | 1 | rook/ceph:v1.4.2 |

| Service | Type | Ports |
|---|---|---|
| csi-cephfsplugin-metrics | ClusterIP | 8080, 8081 |
| csi-rbdplugin-metrics | ClusterIP | 8080, 8081 |

**ConfigMaps:** `local-device-svim-53-114`(1 keys), `local-device-svim-53-119`(1 keys), `local-device-svim-53-193`(1 keys), `local-device-svim-53-201`(1 keys), `rook-ceph-csi-config`(1 keys), `rook-ceph-operator-config`(6 keys)

**Secrets:** `default-token-gpsfp`(<DOMAIN_138>/service-account-token), `rook-ceph-admission-controller-token-wsbnm`(<DOMAIN_138>/service-account-token), `rook-ceph-system-token-bd65q`(<DOMAIN_138>/service-account-token), `rook-csi-cephfs-plugin-sa-token-5988v`(<DOMAIN_138>/service-account-token), `rook-csi-cephfs-provisioner-sa-token-htlg2`(<DOMAIN_138>/service-account-token), `rook-csi-rbd-plugin-sa-token-vjz8f`(<DOMAIN_138>/service-account-token), `rook-csi-rbd-provisioner-sa-token-shpbp`(<DOMAIN_138>/service-account-token)


## Namespace `security-cloud`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | cloud-security-load | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/cloud-security-load/prd:26 |
| Deployment | devops-security-dashboard | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/devops-security-dashboard/prd:26 |
| StatefulSet | sec-dashboard-mongo | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |

| Service | Type | Ports |
|---|---|---|
| dsd-service | ClusterIP | 8080 |
| sec-mongodb-service | ClusterIP | 27017 |

| Ingress | Hosts | Paths |
|---|---|---|
| sec-dashboard-ingress | security-dashboard.<COMPANY><DOMAIN_14> | / |
| sec-dashboard-ingress | security-dashboard.<COMPANY><DOMAIN_14> | / |

**ConfigMaps:** `mongodb-config`(1 keys)

**Secrets:** `default-token-m5cmn`(<DOMAIN_138>/service-account-token), `dsd-secret`(Opaque), `secret-registry-image`(<DOMAIN_138>/dockerconfigjson), `spl-secret`(Opaque)

**PVCs:** `sec-dashboard-storage-sec-dashboard-mongo-0`(30Gi,ceph-block-replica-2)


## Namespace `service-portal`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | service-portal | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/service-portal/prd/service-portal_eb2d1d5 |

| Service | Type | Ports |
|---|---|---|
| service-portal | ClusterIP | 80 |

| Ingress | Hosts | Paths |
|---|---|---|
| service-portal-ingress | service-portal.<COMPANY_DOMAIN> | / |
| service-portal-ingress | service-portal.<COMPANY_DOMAIN> | / |


**Secrets:** `default-token-bcm8x`(<DOMAIN_138>/service-account-token), `secret-registry-image`(<DOMAIN_138>/dockerconfigjson)


## Namespace `shift-handover`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | shift-handover-frontend | 2 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/shift-handover/frontend/main:8 |
| StatefulSet | shift-handover-backend | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/shift-handover/backend/main:10 |
| StatefulSet | shift-handover-mongo | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| Job | mongodb-auto-backup-1784052000 | None | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| Job | mongodb-auto-backup-1784138400 | None | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| Job | mongodb-auto-backup-1784224800 | None | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| Job | mongodb-cleanup-backup-1784055600 | None | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| Job | mongodb-cleanup-backup-1784142000 | None | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| Job | mongodb-cleanup-backup-1784228400 | None | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| CronJob | mongodb-auto-backup | None | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| CronJob | mongodb-cleanup-backup | None | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |

| Service | Type | Ports |
|---|---|---|
| backend | ClusterIP | 5000 |
| frontend | ClusterIP | 80 |
| mongodb | ClusterIP | 27017 |

| Ingress | Hosts | Paths |
|---|---|---|
| shift-handover-ingress | shift-handover.<COMPANY_DOMAIN>, <DOMAIN_557>.<COMPANY_DOMAIN> | /, / |
| shift-handover-ingress | shift-handover.<COMPANY_DOMAIN>, <DOMAIN_557>.<COMPANY_DOMAIN> | /, / |

**ConfigMaps:** `mongodb-config`(1 keys), `shift-handover-nginx-conf`(1 keys)

**Secrets:** `be-secret`(Opaque), `default-token-tk7ml`(<DOMAIN_138>/service-account-token), `fe-secret`(Opaque), `mongo-secret`(Opaque), `secret-registry-image`(<DOMAIN_138>/dockerconfigjson)

**PVCs:** `mongodb-backup-pvc`(20Gi,None), `shift-handover-image-shift-handover-backend-0`(30Gi,ceph-block-replica-2), `shift-handover-storage-shift-handover-mongo-0`(30Gi,ceph-block-replica-2)


## Namespace `spinnaker`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | spin-clouddriver | 1 | <COMPANY>-<DOMAIN_607>/spinnaker/clouddriver:6.10.0-20200625140019 |
| Deployment | spin-deck | 1 | <COMPANY>-<DOMAIN_607>/spinnaker/deck:3.2.0-20200625152925 |
| Deployment | spin-echo | 1 | <COMPANY>-<DOMAIN_607>/spinnaker/echo:2.13.0-20200625152925 |
| Deployment | spin-fiat | 1 | <COMPANY>-<DOMAIN_607>/spinnaker/fiat:1.12.0-20200625140019 |
| Deployment | spin-front50 | 1 | <COMPANY>-<DOMAIN_607>/spinnaker/front50:0.24.0-20200625140019 |
| Deployment | spin-gate | 1 | <COMPANY>-<DOMAIN_607>/spinnaker/gate:1.17.0-20200625140019 |
| Deployment | spin-igor | 1 | <COMPANY>-<DOMAIN_607>/spinnaker/igor:1.11.1-20200721201355 |
| Deployment | spin-orca | 1 | <COMPANY>-<DOMAIN_607>/spinnaker/orca:2.15.2-20200806164929 |
| Deployment | spin-redis | 1 | <COMPANY>-<DOMAIN_607>/spinnaker/redis-cluster:v2 |
| StatefulSet | spinnaker-hal | 1 | <COMPANY>-<DOMAIN_607>/spinnaker/halyard:stable |

| Service | Type | Ports |
|---|---|---|
| spin-clouddriver | ClusterIP | 7002 |
| spin-deck | ClusterIP | 9000 |
| spin-echo | ClusterIP | 8089 |
| spin-fiat | ClusterIP | 7003 |
| spin-front50 | ClusterIP | 8080 |
| spin-gate | ClusterIP | 8084 |
| spin-igor | ClusterIP | 8088 |
| spin-orca | ClusterIP | 8083 |
| spin-redis | ClusterIP | 6379 |

| Ingress | Hosts | Paths |
|---|---|---|
| spinnaker-ingress | spinnaker.<COMPANY><DOMAIN_14>, spinnaker-gate.<COMPANY><DOMAIN_14> | /, / |
| spinnaker-ingress | spinnaker.<COMPANY><DOMAIN_14>, spinnaker-gate.<COMPANY><DOMAIN_14> | /, / |

**ConfigMaps:** `halyard-read-bom`(1 keys)

**Secrets:** `default-token-6f745`(<DOMAIN_138>/service-account-token), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson), `spin-clouddriver-files-1146685058`(Opaque), `spin-clouddriver-files-1349487436`(Opaque), `spin-clouddriver-files-1392047910`(Opaque), `spin-clouddriver-files-1426522175`(Opaque), `spin-clouddriver-files-1555694734`(Opaque), `spin-clouddriver-files-1570312515`(Opaque), `spin-clouddriver-files-1598479460`(Opaque), `spin-clouddriver-files-1619698436`(Opaque), `spin-clouddriver-files-1642134358`(Opaque), `spin-clouddriver-files-1642135900`(Opaque), `spin-clouddriver-files-1733003122`(Opaque), `spin-clouddriver-files-1771422661`(Opaque), `spin-clouddriver-files-1789819702`(Opaque), `spin-clouddriver-files-1838110461`(Opaque), `spin-clouddriver-files-183949529`(Opaque), `spin-clouddriver-files-1927688934`(Opaque), `spin-clouddriver-files-196409797`(Opaque), `spin-clouddriver-files-1980381829`(Opaque), `spin-clouddriver-files-2105729323`(Opaque), `spin-clouddriver-files-254937115`(Opaque), `spin-clouddriver-files-33536558`(Opaque), `spin-clouddriver-files-341335144`(Opaque), `spin-clouddriver-files-34462496`(Opaque), `spin-clouddriver-files-39042023`(Opaque), `spin-clouddriver-files-395658492`(Opaque), `spin-clouddriver-files-39992150`(Opaque), `spin-clouddriver-files-446004451`(Opaque), `spin-clouddriver-files-65728674`(Opaque), `spin-clouddriver-files-676416594`(Opaque), `spin-clouddriver-files-782073584`(Opaque), `spin-clouddriver-files-85873820`(Opaque), `spin-clouddriver-files-922449972`(Opaque), `spin-deck-files-1067527873`(Opaque), `spin-deck-files-1262545222`(Opaque), `spin-deck-files-1346984691`(Opaque), `spin-deck-files-1513259485`(Opaque), `spin-deck-files-536304579`(Opaque), `spin-echo-files-1006773462`(Opaque), `spin-echo-files-1049213583`(Opaque), `spin-echo-files-1273023090`(Opaque), `spin-echo-files-1576312999`(Opaque), `spin-echo-files-1659981592`(Opaque), `spin-echo-files-1857113672`(Opaque), `spin-echo-files-2081213837`(Opaque), `spin-echo-files-402997620`(Opaque), `spin-echo-files-429998905`(Opaque), `spin-fiat-files-1288296009`(Opaque), `spin-fiat-files-138795236`(Opaque), `spin-fiat-files-1993005329`(Opaque), `spin-fiat-files-326864628`(Opaque), `spin-fiat-files-763022642`(Opaque), `spin-fiat-files-783243827`(Opaque), `spin-fiat-files-998856010`(Opaque), `spin-front50-files-1026806357`(Opaque), `spin-front50-files-1178117478`(Opaque), `spin-front50-files-1253799442`(Opaque), `spin-front50-files-145025925`(Opaque), `spin-front50-files-1822566069`(Opaque), `spin-front50-files-2038178252`(Opaque), `spin-front50-files-2078674544`(Opaque), `spin-front50-files-424513612`(Opaque), `spin-front50-files-627354575`(Opaque), `spin-gate-files-1461200713`(Opaque), `spin-gate-files-1689744660`(Opaque), `spin-gate-files-1745161862`(Opaque), `spin-gate-files-1905356843`(Opaque), `spin-gate-files-459761973`(Opaque), `spin-gate-files-762499756`(Opaque), `spin-igor-files-1160202567`(Opaque), `spin-igor-files-1358383376`(Opaque), `spin-igor-files-143008808`(Opaque), `spin-igor-files-1788617933`(Opaque), `spin-igor-files-1804651158`(Opaque), `spin-igor-files-292867571`(Opaque), `spin-igor-files-834845389`(Opaque), `spin-igor-files-944590384`(Opaque), `spin-igor-files-976770838`(Opaque), `spin-orca-files-127183345`(Opaque), `spin-orca-files-1647687269`(Opaque), `spin-orca-files-2077740490`(Opaque), `spin-orca-files-423579558`(Opaque), `spin-orca-files-771631936`(Opaque), `spin-orca-files-795629369`(Opaque), `spin-orca-files-987244119`(Opaque)

**PVCs:** `halyard-storage`(2Gi,ceph-block-replica-2), `kube-storage`(1Gi,ceph-block-replica-2)


## Namespace `survey-doe`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| Deployment | survey-doe | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/survey_doe/survey:38 |
| Deployment | survey-v2 | 1 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/survey-aqei/survey:43 |

| Service | Type | Ports |
|---|---|---|
| survey-doe-service | ClusterIP | 8080 |
| survey-v2-service | ClusterIP | 8080 |

| Ingress | Hosts | Paths |
|---|---|---|
| survey-doe-ingress | jp.<COMPANY_DOMAIN> | / |
| survey-v2-ingress | survey-aqei.<COMPANY_DOMAIN> | / |
| survey-doe-ingress | jp.<COMPANY_DOMAIN> | / |
| survey-v2-ingress | survey-aqei.<COMPANY_DOMAIN> | / |


**Secrets:** `default-token-lfwt4`(<DOMAIN_138>/service-account-token), `jfrog-registry-secret`(<DOMAIN_138>/dockerconfigjson)

**PVCs:** `survey-aqei-pvc`(5Gi,survey-aqei-storage), `survey-pvc`(3Gi,manual)


## Namespace `svms`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| StatefulSet | alertmanager | 1 | <COMPANY>-<DOMAIN_607>/svms/alertmanager:0.19.0 |
| StatefulSet | grafana | 1 | <COMPANY>-<DOMAIN_607>/svms/grafana:6.4.3 |
| StatefulSet | mysql-grafana | 1 | <COMPANY>-<DOMAIN_607>/svms/mysql:5.6, <COMPANY>-<DOMAIN_607>/svms/mysqld-exporter:dev |
| StatefulSet | percona | 1 | <COMPANY>-<DOMAIN_607>/percona/pmm-server:2.26.0 |
| StatefulSet | prometheus-server | 1 | <COMPANY>-<DOMAIN_607>/svms/prometheus:2.13.1, <COMPANY>-<DOMAIN_607>/svms/ubuntu:dev_v1 |

| Service | Type | Ports |
|---|---|---|
| alertmanager-svc | ClusterIP | 19093 |
| grafana-svc | ClusterIP | 13000 |
| mysql-grafana-svc | ClusterIP | 13306, 9104 |
| percona-service | ClusterIP | 23443 |
| prometheus-server-svc | ClusterIP | 19090 |

| Ingress | Hosts | Paths |
|---|---|---|
| svms-ingress | svms.<COMPANY><DOMAIN_14> | / |
| svms-ingress | svms.<COMPANY><DOMAIN_14> | / |

**ConfigMaps:** `alertmanager-config`(1 keys), `grafana-ini`(1 keys), `loki-conf`(1 keys), `prometheus-server-conf`(59 keys)

**Secrets:** `default-token-fkqln`(<DOMAIN_138>/service-account-token), `influxdb2-auth`(Opaque), `influxdb2-token-s2fdm`(<DOMAIN_138>/service-account-token), `loki-token-2t49n`(<DOMAIN_138>/service-account-token), `mysql-exporter-password`(Opaque), `mysql-grafana-password`(Opaque), `mysql-root-password`(Opaque), `prometheus-user-token-4g9xr`(<DOMAIN_138>/service-account-token), `promtail`(Opaque), `promtail-token-vq5ph`(<DOMAIN_138>/service-account-token), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson), `svms-token-gb59j`(<DOMAIN_138>/service-account-token)

**PVCs:** `alertmanager-data-alertmanager-0`(10Gi,ceph-block-replica-2), `data-influxdb2-0`(10Gi,ceph-block-replica-2), `loki-storage-loki-0`(50Gi,ceph-block-replica-2), `mysql-grafana-mysql-grafana-0`(10Gi,ceph-block-replica-2), `plugin-volume-grafana-0`(10Gi,ceph-block-replica-2), `pmmdata-percona-0`(200Gi,ceph-block-replica-2), `prometheus-storage-volume-prometheus-server-0`(500Gi,ceph-block-replica-2)


## Namespace `u-2qhhp`


**Secrets:** `default-token-7dtgf`(<DOMAIN_138>/service-account-token)


## Namespace `u-2utyphfdjm`


**Secrets:** `default-token-27659`(<DOMAIN_138>/service-account-token)


## Namespace `u-3vqqwywgyb`


**Secrets:** `default-token-ztttv`(<DOMAIN_138>/service-account-token)


## Namespace `u-4mbr2dwdo7`


**Secrets:** `default-token-lrxpw`(<DOMAIN_138>/service-account-token)


## Namespace `u-56pgs`


**Secrets:** `default-token-6d9zw`(<DOMAIN_138>/service-account-token)


## Namespace `u-5mgnijhvg6`


**Secrets:** `default-token-bbpqv`(<DOMAIN_138>/service-account-token)


## Namespace `u-5q56sn4em6`


**Secrets:** `default-token-cjnrt`(<DOMAIN_138>/service-account-token)


## Namespace `u-67ijcr2wgu`


**Secrets:** `default-token-z5pcf`(<DOMAIN_138>/service-account-token)


## Namespace `u-6gbwzee5vh`


**Secrets:** `default-token-gc6z2`(<DOMAIN_138>/service-account-token)


## Namespace `u-6xpr6cw7mr`


**Secrets:** `default-token-ppn48`(<DOMAIN_138>/service-account-token)


## Namespace `u-72uggsypy6`


**Secrets:** `default-token-snfbd`(<DOMAIN_138>/service-account-token)


## Namespace `u-75yktoly4h`


**Secrets:** `default-token-9wndm`(<DOMAIN_138>/service-account-token)


## Namespace `u-7gfxvb5zzi`


**Secrets:** `default-token-dfl88`(<DOMAIN_138>/service-account-token)


## Namespace `u-c5tqm`


**Secrets:** `default-token-6px8m`(<DOMAIN_138>/service-account-token)


## Namespace `u-calvtkx4f6`


**Secrets:** `default-token-6gdqm`(<DOMAIN_138>/service-account-token)


## Namespace `u-cw62c`


**Secrets:** `default-token-fn2xk`(<DOMAIN_138>/service-account-token)


## Namespace `u-e3fjjkktdf`


**Secrets:** `default-token-dnhtf`(<DOMAIN_138>/service-account-token)


## Namespace `u-ef76duapmo`


**Secrets:** `default-token-l8w67`(<DOMAIN_138>/service-account-token)


## Namespace `u-flixo7vavq`


**Secrets:** `default-token-287dx`(<DOMAIN_138>/service-account-token)


## Namespace `u-fxdujzgdcg`


**Secrets:** `default-token-7xg4b`(<DOMAIN_138>/service-account-token)


## Namespace `u-fyxwtz3lez`


**Secrets:** `default-token-6qxbg`(<DOMAIN_138>/service-account-token)


## Namespace `u-fzbdx`


**Secrets:** `default-token-6pmkm`(<DOMAIN_138>/service-account-token)


## Namespace `u-h64k5dfghy`


**Secrets:** `default-token-wqppq`(<DOMAIN_138>/service-account-token)


## Namespace `u-h6bzv6cz5c`


**Secrets:** `default-token-zwqc4`(<DOMAIN_138>/service-account-token)


## Namespace `u-hmcqfl44jz`


**Secrets:** `default-token-w7cq2`(<DOMAIN_138>/service-account-token)


## Namespace `u-ijvvl25jhe`


**Secrets:** `default-token-fh7v7`(<DOMAIN_138>/service-account-token)


## Namespace `u-jyof2tttrj`


**Secrets:** `default-token-28w5r`(<DOMAIN_138>/service-account-token)


## Namespace `u-kgbnnz5oqk`


**Secrets:** `default-token-6qg2b`(<DOMAIN_138>/service-account-token)


## Namespace `u-l7q8v`


**Secrets:** `default-token-xwh6r`(<DOMAIN_138>/service-account-token)


## Namespace `u-ljehyqzo2v`


**Secrets:** `default-token-nh2h5`(<DOMAIN_138>/service-account-token)


## Namespace `u-lwl5hdrmbn`


**Secrets:** `default-token-8pv5r`(<DOMAIN_138>/service-account-token)


## Namespace `u-m6qmoqpsah`


**Secrets:** `default-token-nvqnl`(<DOMAIN_138>/service-account-token)


## Namespace `u-mrzfr`


**Secrets:** `default-token-fg9vs`(<DOMAIN_138>/service-account-token)


## Namespace `u-mwcbm`


**Secrets:** `default-token-wccq8`(<DOMAIN_138>/service-account-token)


## Namespace `u-o2yezawj4t`


**Secrets:** `default-token-vq5gd`(<DOMAIN_138>/service-account-token)


## Namespace `u-o37she4kvi`


**Secrets:** `default-token-5mlhd`(<DOMAIN_138>/service-account-token)


## Namespace `u-opuz4wfoda`


**Secrets:** `default-token-tjdc5`(<DOMAIN_138>/service-account-token)


## Namespace `u-p7vaiakhge`


**Secrets:** `default-token-kq9vn`(<DOMAIN_138>/service-account-token)


## Namespace `u-pdq5vm372s`


**Secrets:** `default-token-s884d`(<DOMAIN_138>/service-account-token)


## Namespace `u-q79r7`


**Secrets:** `default-token-vlh7p`(<DOMAIN_138>/service-account-token)


## Namespace `u-q7mkj`


**Secrets:** `default-token-pdpcn`(<DOMAIN_138>/service-account-token)


## Namespace `u-qigr7prtrk`


**Secrets:** `default-token-l7mdl`(<DOMAIN_138>/service-account-token)


## Namespace `u-qtpdcaqajg`


**Secrets:** `default-token-2n9j6`(<DOMAIN_138>/service-account-token)


## Namespace `u-qwn9b`


**Secrets:** `default-token-fz27k`(<DOMAIN_138>/service-account-token)


## Namespace `u-qzbn6m3mqd`


**Secrets:** `default-token-77lv2`(<DOMAIN_138>/service-account-token)


## Namespace `u-rpo3xkrljc`


**Secrets:** `default-token-pcls8`(<DOMAIN_138>/service-account-token)


## Namespace `u-s3wceu2qkb`


**Secrets:** `default-token-6ljgq`(<DOMAIN_138>/service-account-token)


## Namespace `u-scmg9`


**Secrets:** `default-token-gp5nz`(<DOMAIN_138>/service-account-token)


## Namespace `u-st5m57w3sg`


**Secrets:** `default-token-kwck7`(<DOMAIN_138>/service-account-token)


## Namespace `u-szrv4`


**Secrets:** `default-token-8f54t`(<DOMAIN_138>/service-account-token)


## Namespace `u-taswvbmwbk`


**Secrets:** `default-token-nczcl`(<DOMAIN_138>/service-account-token)


## Namespace `u-ulqmnp7jyh`


**Secrets:** `default-token-2h7m6`(<DOMAIN_138>/service-account-token)


## Namespace `u-v4ccd`


**Secrets:** `default-token-r2q6t`(<DOMAIN_138>/service-account-token)


## Namespace `u-vhxck`


**Secrets:** `default-token-5n4jp`(<DOMAIN_138>/service-account-token)


## Namespace `u-w6k48`


**Secrets:** `default-token-pm7t5`(<DOMAIN_138>/service-account-token)


## Namespace `u-wujwy735wz`


**Secrets:** `default-token-lvrn4`(<DOMAIN_138>/service-account-token)


## Namespace `u-wwwzr4dilo`


**Secrets:** `default-token-fxk6l`(<DOMAIN_138>/service-account-token)


## Namespace `u-xdqo56ujck`


**Secrets:** `default-token-vzq9f`(<DOMAIN_138>/service-account-token)


## Namespace `u-ymbjie6od7`


**Secrets:** `default-token-zpfjj`(<DOMAIN_138>/service-account-token)


## Namespace `u-zoriiln52e`


**Secrets:** `default-token-hjngn`(<DOMAIN_138>/service-account-token)


## Namespace `user-9h9cp`


**Secrets:** `default-token-w29zw`(<DOMAIN_138>/service-account-token)


## Namespace `vault`

| Kind | Tên | Replicas | Image |
|---|---|---|---|
| StatefulSet | vault | 1 | <COMPANY>-<DOMAIN_690>/vault:1.7.0 |

| Service | Type | Ports |
|---|---|---|
| vault | ClusterIP | 8200, 8201 |
| vault-agent-injector-svc | ClusterIP | 443 |
| vault-internal | ClusterIP | 8200, 8201 |
| vault-ui | ClusterIP | 18200 |

| Ingress | Hosts | Paths |
|---|---|---|
| vault-ingress | vault.<COMPANY><DOMAIN_14> | / |
| vault-ingress | vault.<COMPANY><DOMAIN_14> | / |

**ConfigMaps:** `vault-config`(1 keys)

**Secrets:** `default-token-nsrjj`(<DOMAIN_138>/service-account-token), `registrypullsecret`(<DOMAIN_138>/dockerconfigjson), `<DOMAIN_552>.v1`(<DOMAIN_152>/release.v1), `vault-agent-injector-token-jzf8w`(<DOMAIN_138>/service-account-token), `vault-token-lt6pv`(<DOMAIN_138>/service-account-token)

**PVCs:** `data-vault-0`(10Gi,ceph-block-replica-2)
