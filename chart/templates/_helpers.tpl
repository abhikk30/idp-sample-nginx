{{- define "sample-nginx.name" -}}sample-nginx{{- end -}}
{{- define "sample-nginx.labels" -}}
app.kubernetes.io/name: {{ include "sample-nginx.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: helm
{{- end -}}
