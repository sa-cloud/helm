{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "minioendpoint" -}}
http://{{ template "minio.fullname" (dict "Chart" (dict "Name" "minio") "Values" (index .Values "minio") "Release" .Release "Capabilities" .Capabilities) }}:9000
{{- end -}}

{{/*
this is a way to run minio subchart's template and pass it minio's scope (.Values.minio). 
The .Values.minio itself is not sub-scope of the current chart, need to create the dict so it looks like a scope.
*/}}
{{- define "miniofullname" -}}
{{ template "minio.fullname" (dict "Chart" (dict "Name" "minio") "Values" (index .Values "minio") "Release" .Release "Capabilities" .Capabilities) }}
{{- end -}}

