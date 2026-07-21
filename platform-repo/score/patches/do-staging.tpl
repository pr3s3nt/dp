{{/*
  PATCH TEMPLATE — DIGITALOCEAN / STAGING
  Áp lên toàn bộ manifest score-k8s sinh ra (score-k8s init --patch-templates ...).
  Nơi DUY NHẤT chứa khác biệt môi trường — dev không đụng vào.

  KHÁC onprem staging.tpl: $pullSecret = secret kéo image từ DOCR (DigitalOcean
  Container Registry), tạo bằng `doctl registry kubernetes-manifest` -> tên mặc
  định là "registry-<tên-registry>". Đổi tại biến bên dưới nếu registry khác tên.

  QUY TẮC (giống onprem):
  - Manifest label app.kubernetes.io/component=datastore -> KHÔNG đụng replicas/resources.
  - resources chỉ set cho container CHƯA có resources.
  - imagePullSecrets tiêm cho mọi pod template (Deployment/StatefulSet/CronJob).
*/}}
{{ $pullSecret := "registry-idp-notes-thanhnt" }}{{/* <-- Secret DOCR (env staging) */}}
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
{{/* DOCR private -> tiêm pull secret vào mọi pod template. */}}
{{ if or (eq $m.kind "Deployment") (eq $m.kind "StatefulSet") }}
- op: set
  path: {{ $i }}.spec.template.spec.imagePullSecrets
  value:
    - name: {{ $pullSecret }}
  description: Pull image từ DOCR ({{ $pullSecret }})
{{ end }}
{{ if eq $m.kind "CronJob" }}
- op: set
  path: {{ $i }}.spec.jobTemplate.spec.template.spec.imagePullSecrets
  value:
    - name: {{ $pullSecret }}
  description: Pull image từ DOCR ({{ $pullSecret }}) cho CronJob
{{ end }}
{{ end }}
