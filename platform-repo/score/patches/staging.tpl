{{/*
  PATCH TEMPLATE — STAGING
  Áp lên toàn bộ manifest do score-k8s sinh ra (score-k8s init --patch-templates ...).
  Đây là nơi DUY NHẤT chứa khác biệt theo môi trường — dev không đụng vào.
  Thay thế vai trò của Kustomize overlay.
*/}}
{{ range $i, $m := .Manifests }}
{{ if eq $m.kind "Deployment" }}
- op: set
  path: {{ $i }}.spec.replicas
  value: 1
- op: set
  path: {{ $i }}.metadata.labels.env
  value: staging
{{ range $ci, $c := $m.spec.template.spec.containers }}
- op: set
  path: {{ $i }}.spec.template.spec.containers.{{ $ci }}.resources
  value:
    requests: { cpu: 50m, memory: 64Mi }
    limits: { memory: 256Mi }
{{ end }}
{{ end }}
{{/* Harbor là registry private -> platform tự tiêm pull secret vào mọi workload.
     Secret 'harbor-pull' do orchestrator/deploy-local tạo sẵn trong namespace. */}}
{{ if or (eq $m.kind "Deployment") (eq $m.kind "StatefulSet") }}
- op: set
  path: {{ $i }}.spec.template.spec.imagePullSecrets
  value:
    - name: harbor-pull
  description: Pull image từ Harbor private registry
{{ end }}
{{ end }}
