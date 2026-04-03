{{/*
Common template helpers for fishkube (manager & agent)
*/}}

{{/*
Resolve the app name based on mode.
  mode=manager → fishkube-manager
  mode=agent   → fishkube-agent
*/}}
{{- define "fishkube.appName" -}}
{{- if eq (.Values.mode | default "manager") "agent" -}}
fishkube-agent
{{- else -}}
fishkube-manager
{{- end -}}
{{- end -}}

{{- define "fishkube.name" -}}
{{- default (include "fishkube.appName" .) .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "fishkube.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default (include "fishkube.appName" .) .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "fishkube.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{- define "fishkube.labels" -}}
app.kubernetes.io/name: {{ include "fishkube.name" . }}
helm.sh/chart: {{ include "fishkube.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "fishkube.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fishkube.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "fishkube.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "fishkube.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Container port: 8080 for manager, 8081 for agent
*/}}
{{- define "fishkube.containerPort" -}}
{{- if eq (.Values.mode | default "manager") "agent" -}}
8081
{{- else -}}
8080
{{- end -}}
{{- end -}}

{{/*
Health check path
*/}}
{{- define "fishkube.healthPath" -}}
{{- if eq (.Values.mode | default "manager") "agent" -}}
/health
{{- else -}}
/
{{- end -}}
{{- end -}}
