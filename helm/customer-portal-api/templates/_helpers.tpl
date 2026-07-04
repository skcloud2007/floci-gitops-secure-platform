{{- define "customer-portal-api.name" -}}
customer-portal-api
{{- end }}

{{- define "customer-portal-api.fullname" -}}
{{ .Release.Name }}
{{- end }}

{{- define "customer-portal-api.labels" -}}
app.kubernetes.io/name: {{ include "customer-portal-api.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/part-of: "floci-gitops-secure-platform"
{{- end }}
