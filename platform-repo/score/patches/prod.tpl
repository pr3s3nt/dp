{{/*
  PATCH TEMPLATE — PROD
  Nhiều replica hơn, resource lớn hơn. Chỉ platform sửa file này.
*/}}
{{ range $i, $m := .Manifests }}
{{ if eq $m.kind "Deployment" }}
- op: set
  path: {{ $i }}.spec.replicas
  value: 3
- op: set
  path: {{ $i }}.metadata.labels.env
  value: prod
{{ range $ci, $c := $m.spec.template.spec.containers }}
- op: set
  path: {{ $i }}.spec.template.spec.containers.{{ $ci }}.resources
  value:
    requests: { cpu: 100m, memory: 128Mi }
    limits: { memory: 512Mi }
{{ end }}
{{ end }}
{{/* Pull secret Harbor — giống staging */}}
{{ if or (eq $m.kind "Deployment") (eq $m.kind "StatefulSet") }}
- op: set
  path: {{ $i }}.spec.template.spec.imagePullSecrets
  value:
    - name: harbor-pull
  description: Pull image từ Harbor private registry
{{ end }}
{{ end }}
