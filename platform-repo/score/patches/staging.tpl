{{/*
  PATCH TEMPLATE — STAGING
  Áp lên toàn bộ manifest do score-k8s sinh ra (score-k8s init --patch-templates ...).
  Đây là nơi DUY NHẤT chứa khác biệt theo môi trường — dev không đụng vào.
  Thay thế vai trò của Kustomize overlay.

  QUY TẮC:
  - Manifest có label app.kubernetes.io/component=datastore (do provisioner sinh:
    mysql/mongo/redis/backup...) -> KHÔNG đụng replicas/resources — datastore tự
    khai nhu cầu của nó ngay trong catalog provisioner.
  - resources chỉ set cho container CHƯA có resources -> provisioner/dev đã khai thì giữ.
  - imagePullSecrets tiêm cho MỌI pod template (Deployment/StatefulSet/CronJob);
    tên secret cấu hình 1 chỗ ở biến $pullSecret dưới đây, theo TỪNG env
    (staging.tpl / prod.tpl là 2 file riêng). Secret do orchestrator tạo
    create-if-missing trong từng namespace.
*/}}
{{ $pullSecret := "harbor-pull" }}{{/* <-- CẤU HÌNH: tên pull secret của env staging */}}
{{ range $i, $m := .Manifests }}
{{- $component := "" }}
{{- if $m.metadata }}{{ if $m.metadata.labels }}{{ with index $m.metadata.labels "app.kubernetes.io/component" }}{{ $component = . }}{{ end }}{{ end }}{{ end }}
{{ if and (eq $m.kind "Deployment") (ne $component "datastore") }}
- op: set
  path: {{ $i }}.spec.replicas
  value: 1
- op: set
  path: {{ $i }}.metadata.labels.env
  value: staging
{{/* Khuôn công ty (Rancher): rolling update không downtime */}}
- op: set
  path: {{ $i }}.spec.strategy
  value:
    type: RollingUpdate
    rollingUpdate: { maxSurge: 1, maxUnavailable: 0 }
{{ range $ci, $c := $m.spec.template.spec.containers }}
{{- if not $c.resources }}
- op: set
  path: {{ $i }}.spec.template.spec.containers.{{ $ci }}.resources
  value:
    requests: { cpu: 50m, memory: 64Mi }
    limits: { memory: 256Mi }
{{- end }}
{{ end }}
{{ end }}
{{/* Registry private -> platform tự tiêm pull secret vào mọi pod template. */}}
{{ if or (eq $m.kind "Deployment") (eq $m.kind "StatefulSet") }}
- op: set
  path: {{ $i }}.spec.template.spec.imagePullSecrets
  value:
    - name: {{ $pullSecret }}
  description: Pull image từ registry private ({{ $pullSecret }})
{{ end }}
{{ if eq $m.kind "CronJob" }}
- op: set
  path: {{ $i }}.spec.jobTemplate.spec.template.spec.imagePullSecrets
  value:
    - name: {{ $pullSecret }}
  description: Pull image từ registry private ({{ $pullSecret }}) cho CronJob
{{ end }}
{{ end }}
