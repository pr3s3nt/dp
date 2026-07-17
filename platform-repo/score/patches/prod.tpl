{{/*
  PATCH TEMPLATE — PROD
  Nhiều replica hơn, resource lớn hơn. Chỉ platform sửa file này.
  Quy tắc giống staging.tpl: bỏ qua datastore, resources chỉ set khi container chưa có,
  pull secret cấu hình ở biến $pullSecret (tiêm cả CronJob).
*/}}
{{ $pullSecret := "harbor-pull" }}{{/* <-- CẤU HÌNH: tên pull secret của env prod */}}
{{ range $i, $m := .Manifests }}
{{- $component := "" }}
{{- if $m.metadata }}{{ if $m.metadata.labels }}{{ with index $m.metadata.labels "app.kubernetes.io/component" }}{{ $component = . }}{{ end }}{{ end }}{{ end }}
{{ if and (eq $m.kind "Deployment") (ne $component "datastore") }}
- op: set
  path: {{ $i }}.spec.replicas
  value: 3
- op: set
  path: {{ $i }}.metadata.labels.env
  value: prod
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
    requests: { cpu: 100m, memory: 128Mi }
    limits: { memory: 512Mi }
{{- end }}
{{ end }}
{{ end }}
{{/* Pull secret — giống staging, tên cấu hình riêng cho prod ở $pullSecret */}}
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
