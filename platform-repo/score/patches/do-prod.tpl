{{/*
  PATCH TEMPLATE — DIGITALOCEAN / PROD
  Nhiều replica hơn + resource lớn hơn staging. Chỉ platform sửa file này.
  Quy tắc giống do-staging.tpl: bỏ qua datastore, resources chỉ set khi container
  chưa có, pull secret DOCR cấu hình ở $pullSecret (tiêm cả CronJob).

  LƯU Ý cụm test 1 node (s-2vcpu-4gb): prod để replicas=2 (không phải 3 như EKS)
  để vừa 1 node mà vẫn khác staging (chứng minh phân tách môi trường). Cụm nhiều
  node hơn thì nâng lên 3.
*/}}
{{ $pullSecret := "registry-idp-notes-thanhnt" }}{{/* <-- Secret DOCR (env prod) */}}
{{ range $i, $m := .Manifests }}
{{- $component := "" }}
{{- if $m.metadata }}{{ if $m.metadata.labels }}{{ with index $m.metadata.labels "app.kubernetes.io/component" }}{{ $component = . }}{{ end }}{{ end }}{{ end }}
{{ if and (eq $m.kind "Deployment") (ne $component "datastore") }}
- op: set
  path: {{ $i }}.spec.replicas
  value: 2
- op: set
  path: {{ $i }}.metadata.labels.env
  value: prod
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
