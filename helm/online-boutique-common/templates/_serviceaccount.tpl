{{- define "common.serviceaccount" -}}
{{- if .Values.serviceAccount.create }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ .Values.serviceAccount.name }}
  namespace: {{ .Release.Namespace }}
  iam.gke.io/gcp-service-account: {{ .Values.global.gcp.serviceAccountEmail }}
{{- end }}
{{- end }}

