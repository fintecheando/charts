{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "fineract.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fineract.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Get the domain name of the chart - used for ingress rules
*/}}
{{- define "fineract.domain" -}}
{{- if .Values.mifos.develop.enabled -}}
{{- required "Please specify a develop domain at .Values.mifos.develop.devDomain" .Values.mifos.develop.devDomain | printf "%s.%s" ( include "fineract.fullname" .) -}}
{{- else -}}
{{- if not .Values.ingress.enabled -}}
no_domain_specified
{{- else -}}
{{- required "Please specify an ingress domain at .Values.ingress.domain" .Values.ingress.domain -}}
{{- end -}}
{{- end -}}
{{- end -}}
