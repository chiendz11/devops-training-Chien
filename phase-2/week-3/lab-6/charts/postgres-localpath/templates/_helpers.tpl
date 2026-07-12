{{/*
Expand the name of the chart.
*/}}
{{- define "postgres-localpath.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "postgres-localpath.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "postgres-localpath.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "postgres-localpath.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "postgres-localpath.selectorLabels" -}}
app.kubernetes.io/name: {{ include "postgres-localpath.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Secret name.
*/}}
{{- define "postgres-localpath.secretName" -}}
{{- printf "%s-secret" (include "postgres-localpath.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
PVC name.
*/}}
{{- define "postgres-localpath.pvcName" -}}
{{- printf "%s-data" (include "postgres-localpath.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
