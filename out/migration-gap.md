# Khoảng cách migrate: cụm cũ → cụm mới

- Cụm cũ: `v1.19.0` — 156 workload / 122 ns
- Cụm mới: `v1.35.1` — 60 workload / 29 ns

**Tóm tắt:** 140 workload CHƯA có trên cụm mới · 16 workload có nhưng KHÁC image · 0 workload đã khớp.

## Namespace chưa có trên cụm mới

- `acs`
- `actions-runner`
- `argo-rollouts`
- `argocd`
- `artifactory`
- `c-6tfcq`
- `c-m-hqttxk4d`
- `cattle-global-nt`
- `cattle-logging`
- `cattle-logging-system`
- `cattle-prometheus`
- `ceph`
- `cert-manager`
- `dap`
- `elk`
- `event-management`
- `face-reco`
- `feedback360`
- `fem`
- `fleet-system`
- `ingress-nginx`
- `knox2fem`
- `moodle`
- `moodle-v2`
- `okr`
- `okr-dep`
- `opn`
- `p-67wv8`
- `p-c6t6q`
- `p-mjh6x`
- `p-t2pmj`
- `p-v75v8`
- `p-wnc8s`
- `passbolt-v4`
- `portal`
- `rancher-operator-system`
- `security-cloud`
- `service-portal`
- `spinnaker`
- `survey-doe`
- `svms`
- `u-2qhhp`
- `u-2utyphfdjm`
- `u-3vqqwywgyb`
- `u-4mbr2dwdo7`
- `u-56pgs`
- `u-5mgnijhvg6`
- `u-5q56sn4em6`
- `u-67ijcr2wgu`
- `u-6gbwzee5vh`
- `u-6xpr6cw7mr`
- `u-72uggsypy6`
- `u-75yktoly4h`
- `u-7gfxvb5zzi`
- `u-c5tqm`
- `u-calvtkx4f6`
- `u-cw62c`
- `u-e3fjjkktdf`
- `u-ef76duapmo`
- `u-flixo7vavq`
- `u-fxdujzgdcg`
- `u-fyxwtz3lez`
- `u-fzbdx`
- `u-h64k5dfghy`
- `u-h6bzv6cz5c`
- `u-hmcqfl44jz`
- `u-ijvvl25jhe`
- `u-jyof2tttrj`
- `u-kgbnnz5oqk`
- `u-l7q8v`
- `u-ljehyqzo2v`
- `u-lwl5hdrmbn`
- `u-m6qmoqpsah`
- `u-mrzfr`
- `u-mwcbm`
- `u-o2yezawj4t`
- `u-o37she4kvi`
- `u-opuz4wfoda`
- `u-p7vaiakhge`
- `u-pdq5vm372s`
- `u-q79r7`
- `u-q7mkj`
- `u-qigr7prtrk`
- `u-qtpdcaqajg`
- `u-qwn9b`
- `u-qzbn6m3mqd`
- `u-rpo3xkrljc`
- `u-s3wceu2qkb`
- `u-scmg9`
- `u-st5m57w3sg`
- `u-szrv4`
- `u-taswvbmwbk`
- `u-ulqmnp7jyh`
- `u-v4ccd`
- `u-vhxck`
- `u-w6k48`
- `u-wujwy735wz`
- `u-wwwzr4dilo`
- `u-xdqo56ujck`
- `u-ymbjie6od7`
- `u-zoriiln52e`
- `user-9h9cp`
- `vault`

## Workload cần migrate (chỉ có ở cụm cũ)

| Namespace | Kind | Tên | Image |
|---|---|---|---|
| acs | Deployment | acs-backend | <COMPANY>-<DOMAIN_607>/anticovid/<COMPANY>/backend:2143 |
| acs | Deployment | acs-fe | <COMPANY>-<DOMAIN_607>/anticovid/<COMPANY>/frontend:327 |
| acs | StatefulSet | acs-arangodb | <COMPANY>-<DOMAIN_607>/anticovid/base-images/arangodb:3.7.12 |
| acs | StatefulSet | acs-redis | <COMPANY>-<DOMAIN_607>/anticovid/base-images/redis:4.0.9 |
| actions-runner | Deployment | runner-dap | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/<COMPANY>-actions-runner:2.328.0 |
| actions-runner | Deployment | runner-feedback360 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/<COMPANY>-actions-runner:2.328.0 |
| actions-runner | Deployment | runner-superset | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/<COMPANY>-actions-runner:2.328.0 |
| actions-runner | Deployment | survey-doe-runner | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/<COMPANY>-actions-runner:2.328.0 |
| argo-rollouts | Deployment | argo-rollouts | <COMPANY>-<DOMAIN_607>/argocd/argo-rollouts:v1.2.0 |
| argocd | Deployment | argocd-applicationset-controller | <COMPANY>-<DOMAIN_607>/argocd/argocd-applicationset:v0.4.1 |
| argocd | Deployment | argocd-dex-server | <COMPANY>-<DOMAIN_607>/argocd/argocd:v2.3.1, <COMPANY>-<DOMAIN_607>/argocd/dex:v2.30.2 |
| argocd | Deployment | argocd-notifications-controller | <COMPANY>-<DOMAIN_607>/argocd/argocd:v2.3.1 |
| argocd | Deployment | argocd-redis | <COMPANY>-<DOMAIN_607>/argocd/redis:6.2.6-alpine |
| argocd | Deployment | argocd-repo-server | <COMPANY>-<DOMAIN_607>/argocd/argocd:v2.3.1 |
| argocd | Deployment | argocd-server | <COMPANY>-<DOMAIN_607>/argocd/argocd:v2.3.1 |
| argocd | StatefulSet | argocd-application-controller | <COMPANY>-<DOMAIN_607>/argocd/argocd:v2.3.1 |
| artifactory | StatefulSet | jfrog-container-registry-artifactory | <COMPANY>-<DOMAIN_607>/jfrog/artifactory-jcr:7.41.4, <COMPANY>-<DOMAIN_607>/jfrog/ubi-minimal:8.5-204 |
| artifactory | StatefulSet | jfrog-container-registry-postgresql | <COMPANY>-<DOMAIN_607>/jfrog/postgresql:13.4.0-debian-10-r39 |
| cattle-logging | DaemonSet | rancher-logging-fluentd-linux | rancher/configmap-reload:v0.3.0-rancher2, rancher/fluentd:v0.1.19 |
| cattle-logging | DaemonSet | rancher-logging-log-aggregator-linux | rancher/log-aggregator:v0.1.6 |
| cattle-prometheus | DaemonSet | exporter-node-cluster-monitoring | rancher/prom-node-exporter:v1.0.1 |
| cattle-prometheus | Deployment | exporter-kube-state-cluster-monitoring | rancher/coreos-kube-state-metrics:v1.9.7 |
| cattle-prometheus | Deployment | grafana-cluster-monitoring | rancher/grafana-grafana:7.1.5, rancher/library-nginx:1.19.2-alpine, rancher/prometheus-auth:v0.2.0 |
| cattle-prometheus | Deployment | prometheus-operator-monitoring-operator | rancher/coreos-prometheus-operator:v0.38.1 |
| cattle-prometheus | StatefulSet | prometheus-cluster-monitoring | rancher/coreos-prometheus-config-reloader:v0.38.1, rancher/jimmidyson-configmap-reload:v0.3.0, rancher/library-nginx:1.19.2-alpine, rancher/prom-prometheus:v2.18.2, rancher/prometheus-auth:v0.2.0 |
| ceph | Deployment | rook-ceph-crashcollector-svim-53-114 | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-crashcollector-svim-53-119 | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-crashcollector-svim-53-193 | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-crashcollector-svim-53-201 | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-mds-ceph-cephfs-a | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-mds-ceph-cephfs-b | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-mgr-a | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-mon-ai | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-mon-aj | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-mon-av | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-mon-w | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-mon-y | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-osd-0 | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-osd-1 | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-osd-2 | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-osd-3 | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-osd-4 | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-osd-5 | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-rgw-ceph-obj-store-1-a | ceph/ceph:v15.2.4 |
| ceph | Deployment | rook-ceph-tools | rook/ceph:v1.4.2 |
| ceph | Job | rook-ceph-osd-prepare-svim-53-114 | ceph/ceph:v15.2.4, rook/ceph:v1.4.2 |
| ceph | Job | rook-ceph-osd-prepare-svim-53-119 | ceph/ceph:v15.2.4, rook/ceph:v1.4.2 |
| ceph | Job | rook-ceph-osd-prepare-svim-53-193 | ceph/ceph:v15.2.4, rook/ceph:v1.4.2 |
| ceph | Job | rook-ceph-osd-prepare-svim-53-201 | ceph/ceph:v15.2.4, rook/ceph:v1.4.2 |
| ceph | Job | rook-ceph-osd-prepare-svim-53-210 | ceph/ceph:v15.2.4, rook/ceph:v1.4.2 |
| dap | Deployment | dap | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/dap/prd/dap:c14adb2 |
| elk | DaemonSet | filebeat | <COMPANY>-<DOMAIN_607>/elk/filebeat:7.16.2 |
| elk | Deployment | logstash | <COMPANY>-<DOMAIN_607>/elk/logstash:7.16.2 |
| elk | StatefulSet | els | <COMPANY>-<DOMAIN_607>/elk/elasticsearch:7.16.2 |
| elk | StatefulSet | kibana | <COMPANY>-<DOMAIN_607>/elk/kibana:7.16.2 |
| event-management | Deployment | event-manage-be | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/event-management/backend:14 |
| event-management | Deployment | event-manage-fe | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/event-management/frontend:13 |
| event-management | StatefulSet | event-manage-db | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/mysql:5.6 |
| face-reco | Deployment | face-reco-ai | <COMPANY>-<DOMAIN_690>/face_reco/prod_<COMPANY>/face_reco_ai:v1.0.3-<COMPANY> |
| face-reco | Deployment | face-reco-be | <COMPANY>-<DOMAIN_607>/face_reco/prod_<COMPANY>/face_reco_be:v1.0.5.0-<COMPANY> |
| face-reco | Deployment | face-reco-fe | <COMPANY>-<DOMAIN_607>/face_reco/prod_<COMPANY>/face_reco_fe:v1.0.5.0-<COMPANY> |
| face-reco | Deployment | mysql | <COMPANY>-<DOMAIN_690>/face_reco/mysql:5.7.35 |
| feedback360 | Deployment | feedback360-backend | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/feedback360/backend/backend_9:latest |
| feedback360 | Deployment | feedback360-frontend | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/feedback360/frontend/frontend_4:latest |
| feedback360 | StatefulSet | postgresql | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/postgres:16 |
| fem | StatefulSet | fem-prd-web | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fem/prd/fem:10 |
| fleet-local | Job | ml-ops-4f56c | rancher/fleet-agent:v0.3.9, rancher/tekton-utils:v0.1.5 |
| ingress-nginx | Deployment | ingress-nginx-controller | registry.k8s.io/ingress-nginx/controller:v1.2.1@sha256:5516d103a9c2ecc4f026efbd4b40662ce22dc1f824fb129ed121460aaa5c47f8 |
| ingress-nginx | Job | ingress-nginx-admission-create | registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.1.1@sha256:64d8c73dca984af206adf9d6d7e46aa550362b1d7a01f3a0a91b20cc67868660 |
| ingress-nginx | Job | ingress-nginx-admission-patch | registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.1.1@sha256:64d8c73dca984af206adf9d6d7e46aa550362b1d7a01f3a0a91b20cc67868660 |
| keycloak | Deployment | orgchart | <COMPANY>-<DOMAIN_690>/passbolt/mysql:5.6 |
| keycloak | StatefulSet | mysql-keycloak | <COMPANY>-<DOMAIN_607>/keycloak/mysql:5.6 |
| knox2fem | Deployment | knox2fem | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/knox2fem/stg:18 |
| kube-system | StatefulSet | cerebro | <COMPANY>-<DOMAIN_690>/cerebro:0.9.2 |
| moodle | Deployment | moodle | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/moodle:3.10.0-debian-10-r5 |
| moodle | Deployment | ubuntu | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/ubuntu:mantic-20230712 |
| moodle-v2 | Deployment | moodle | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/moodle:3.10.0-debian-10-r5 |
| moodle-v2 | Deployment | moodle-debug | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/ubuntu:latest |
| moodle-v2 | StatefulSet | moodle-mariadb | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/moodle/mariadb:10.5.8-debian-10-r0 |
| okr | Deployment | okr-backend | <COMPANY>-<DOMAIN_607>/okr/backend/okr_backend:37 |
| okr | Deployment | okr-frontend | <COMPANY>-<DOMAIN_607>/okr/frontend/okr_frontend:28 |
| okr | StatefulSet | okr-mysql | <COMPANY>-<DOMAIN_607>/okr/base-images/mysql:8.0.25 |
| okr | StatefulSet | okr-redis | <COMPANY>-<DOMAIN_607>/okr/base-images/redis:6.2.4 |
| okr-dep | Deployment | okr-backend | <COMPANY>-<DOMAIN_607>/okr/backend/okr_backend:16 |
| okr-dep | Deployment | okr-frontend | <COMPANY>-<DOMAIN_607>/okr/frontend/okr_frontend:193 |
| okr-dep | StatefulSet | okr-mysql | <COMPANY>-<DOMAIN_607>/okr/base-images/mysql:8.0.25 |
| okr-dep | StatefulSet | okr-redis | <COMPANY>-<DOMAIN_607>/okr/base-images/redis:6.2.4 |
| opn | Deployment | opn | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/opn/stg:34 |
| passbolt | StatefulSet | mysql | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| passbolt | StatefulSet | passbolt | <COMPANY>-<DOMAIN_607>/passbolt/passbolt_v2_12:20200709 |
| passbolt | StatefulSet | passbolt-client | <COMPANY>-<DOMAIN_607>/passbolt/passbolt-client:v2 |
| passbolt-v4 | CronJob | passbolt-mysql-auto-backup | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| passbolt-v4 | CronJob | passbolt-mysql-cleanup-backup | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| passbolt-v4 | Job | passbolt-mysql-auto-backup-1782470400 | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| passbolt-v4 | Job | passbolt-mysql-auto-backup-1782470520 | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| passbolt-v4 | Job | passbolt-mysql-auto-backup-1784052000 | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| passbolt-v4 | Job | passbolt-mysql-auto-backup-1784138400 | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| passbolt-v4 | Job | passbolt-mysql-auto-backup-1784224800 | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| passbolt-v4 | Job | passbolt-mysql-cleanup-backup-1784055600 | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| passbolt-v4 | Job | passbolt-mysql-cleanup-backup-1784142000 | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| passbolt-v4 | Job | passbolt-mysql-cleanup-backup-1784228400 | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| passbolt-v4 | StatefulSet | mysql | <COMPANY>-<DOMAIN_607>/passbolt/mysql:5.6 |
| passbolt-v4 | StatefulSet | passbolt | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/passbolt/prd:1 |
| portal | Deployment | portal | <COMPANY>-<DOMAIN_607>/portal/<COMPANY>-devops-portal:v5 |
| rook-ceph | DaemonSet | csi-cephfsplugin | quay.io/cephcsi/cephcsi:v3.1.0, quay.io/k8scsi/csi-node-driver-registrar:v1.2.0 |
| rook-ceph | DaemonSet | csi-rbdplugin | quay.io/cephcsi/cephcsi:v3.1.0, quay.io/k8scsi/csi-node-driver-registrar:v1.2.0 |
| rook-ceph | DaemonSet | rook-ceph-agent | rook/ceph:v1.4.2 |
| rook-ceph | DaemonSet | rook-discover | rook/ceph:v1.4.2 |
| rook-ceph | Deployment | csi-cephfsplugin-provisioner | quay.io/cephcsi/cephcsi:v3.1.0, quay.io/k8scsi/csi-attacher:v2.1.0, quay.io/k8scsi/csi-provisioner:v1.6.0, quay.io/k8scsi/csi-resizer:v0.4.0, quay.io/k8scsi/csi-snapshotter:v2.1.1 |
| rook-ceph | Deployment | csi-rbdplugin-provisioner | quay.io/cephcsi/cephcsi:v3.1.0, quay.io/k8scsi/csi-attacher:v2.1.0, quay.io/k8scsi/csi-provisioner:v1.6.0, quay.io/k8scsi/csi-resizer:v0.4.0, quay.io/k8scsi/csi-snapshotter:v2.1.1 |
| security-cloud | Deployment | cloud-security-load | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/cloud-security-load/prd:26 |
| security-cloud | Deployment | devops-security-dashboard | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/devops-security-dashboard/prd:26 |
| security-cloud | StatefulSet | sec-dashboard-mongo | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| service-portal | Deployment | service-portal | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/service-portal/prd/service-portal_eb2d1d5 |
| shift-handover | CronJob | mongodb-auto-backup | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| shift-handover | CronJob | mongodb-cleanup-backup | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| shift-handover | Job | mongodb-auto-backup-1784052000 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| shift-handover | Job | mongodb-auto-backup-1784138400 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| shift-handover | Job | mongodb-auto-backup-1784224800 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| shift-handover | Job | mongodb-cleanup-backup-1784055600 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| shift-handover | Job | mongodb-cleanup-backup-1784142000 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| shift-handover | Job | mongodb-cleanup-backup-1784228400 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 |
| spinnaker | Deployment | spin-clouddriver | <COMPANY>-<DOMAIN_607>/spinnaker/clouddriver:6.10.0-20200625140019 |
| spinnaker | Deployment | spin-deck | <COMPANY>-<DOMAIN_607>/spinnaker/deck:3.2.0-20200625152925 |
| spinnaker | Deployment | spin-echo | <COMPANY>-<DOMAIN_607>/spinnaker/echo:2.13.0-20200625152925 |
| spinnaker | Deployment | spin-fiat | <COMPANY>-<DOMAIN_607>/spinnaker/fiat:1.12.0-20200625140019 |
| spinnaker | Deployment | spin-front50 | <COMPANY>-<DOMAIN_607>/spinnaker/front50:0.24.0-20200625140019 |
| spinnaker | Deployment | spin-gate | <COMPANY>-<DOMAIN_607>/spinnaker/gate:1.17.0-20200625140019 |
| spinnaker | Deployment | spin-igor | <COMPANY>-<DOMAIN_607>/spinnaker/igor:1.11.1-20200721201355 |
| spinnaker | Deployment | spin-orca | <COMPANY>-<DOMAIN_607>/spinnaker/orca:2.15.2-20200806164929 |
| spinnaker | Deployment | spin-redis | <COMPANY>-<DOMAIN_607>/spinnaker/redis-cluster:v2 |
| spinnaker | StatefulSet | spinnaker-hal | <COMPANY>-<DOMAIN_607>/spinnaker/halyard:stable |
| survey-doe | Deployment | survey-doe | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/survey_doe/survey:38 |
| survey-doe | Deployment | survey-v2 | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/survey-aqei/survey:43 |
| svms | StatefulSet | alertmanager | <COMPANY>-<DOMAIN_607>/svms/alertmanager:0.19.0 |
| svms | StatefulSet | grafana | <COMPANY>-<DOMAIN_607>/svms/grafana:6.4.3 |
| svms | StatefulSet | mysql-grafana | <COMPANY>-<DOMAIN_607>/svms/mysql:5.6, <COMPANY>-<DOMAIN_607>/svms/mysqld-exporter:dev |
| svms | StatefulSet | percona | <COMPANY>-<DOMAIN_607>/percona/pmm-server:2.26.0 |
| svms | StatefulSet | prometheus-server | <COMPANY>-<DOMAIN_607>/svms/prometheus:2.13.1, <COMPANY>-<DOMAIN_607>/svms/ubuntu:dev_v1 |
| vault | StatefulSet | vault | <COMPANY>-<DOMAIN_690>/vault:1.7.0 |

## Workload có ở cả hai nhưng KHÁC image (kiểm tra lệch phiên bản)

| Namespace | Kind | Tên | Image cũ | Image mới |
|---|---|---|---|---|
| cattle-fleet-local-system | Deployment | fleet-agent | rancher/fleet-agent:v0.3.9 | rancher/fleet-agent:v0.15.2 |
| cattle-fleet-system | Deployment | fleet-controller | rancher/fleet:v0.3.9 | rancher/fleet:v0.15.2 |
| cattle-fleet-system | Deployment | gitjob | rancher/gitjob:v0.1.26 | rancher/fleet:v0.15.2 |
| cattle-system | Deployment | rancher | rancher/rancher:v2.5.0 | rancher/rancher:v2.14.2 |
| keycloak | StatefulSet | keycloak | <COMPANY>-<DOMAIN_607>/keycloak/keycloak:11.0.3 | <DOMAIN_30>.<COMPANY_DOMAIN>/keycloak/keycloak:26.7.0 |
| kube-system | DaemonSet | calico-node | calico/cni:v3.16.0, calico/node:v3.16.0, calico/pod2daemon-flexvol:v3.16.0 | quay.io/calico/cni:v3.31.4, quay.io/calico/node:v3.31.4 |
| kube-system | DaemonSet | kube-proxy | k8s.gcr.io/kube-proxy:v1.19.0 | registry.k8s.io/kube-proxy:v1.35.1 |
| kube-system | Deployment | calico-kube-controllers | calico/kube-controllers:v3.16.0 | quay.io/calico/kube-controllers:v3.31.4 |
| kube-system | Deployment | coredns | k8s.gcr.io/coredns:1.7.0 | registry.k8s.io/coredns/coredns:v1.13.1 |
| otm | Deployment | otm-be | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/otm/prd/be:22 | <DOMAIN_30>.<COMPANY_DOMAIN>/otm/prd/be:22 |
| otm | Deployment | otm-fe | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/otm/stg/fe:60 | <DOMAIN_30>.<COMPANY_DOMAIN>/otm/stg/fe:60 |
| otm | StatefulSet | mysql | <COMPANY>-<DOMAIN_607>/otm/base-images/gcr.io/google-samples/xtrabackup:1.0, <COMPANY>-<DOMAIN_607>/otm/base-images/mysql:5.6 | <DOMAIN_30>.<COMPANY_DOMAIN>/otm/db/mysql:5.6, <DOMAIN_30>.<COMPANY_DOMAIN>/otm/prd/xtrabackup:1.0 |
| rook-ceph | Deployment | rook-ceph-operator | rook/ceph:v1.4.2 | docker.io/rook/ceph:v1.19.2 |
| shift-handover | Deployment | shift-handover-frontend | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/shift-handover/frontend/main:8 | <DOMAIN_30>.<COMPANY_DOMAIN>/shift-handover/frontend/main:8 |
| shift-handover | StatefulSet | shift-handover-backend | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/shift-handover/backend/main:10 | <DOMAIN_30>.<COMPANY_DOMAIN>/shift-handover/backend/main:10 |
| shift-handover | StatefulSet | shift-handover-mongo | artifactory.<COMPANY><DOMAIN_14>:30807/docker-local/fb360/base-images/mongo:6.0.5 | <DOMAIN_30>.<COMPANY_DOMAIN>/shift-handover/mongodb:6.0.5 |

## Workload đã khớp (đã migrate xong)

_Chưa có workload nào khớp._
