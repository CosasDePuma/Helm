{{- define "configmap.base.tpl" -}}
{{- $values := .Values.configmap | default dict -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "name" . | quote }}
  labels:
    {{- include "labels" . | nindent 4 }}
    {{- if $values.labels | default dict }}
    {{- $values.labels | toYaml | nindent 4 }}
    {{- end }}
  annotations:
    {{- include "annotations" . | nindent 4 }}
    {{- if $values.annotations | default dict }}
    {{- $values.annotations | toYaml | nindent 4 }}
    {{- end }}
{{- if $values.binaryData | default dict }}
binaryData:
  {{- range $name, $contents := $values.binaryData }}
  {{- $name | nindent 2 }}: |-
    {{- $contents | toYaml | nindent 4 }}
  {{- end }}
{{- end }}
{{- if $values.data | default dict }}
data:
  {{- range $name, $contents := $values.data }}
  {{- $name | nindent 2 }}: |-
    {{- $contents | toYaml | nindent 4 }}
  {{- end }}
{{- end }}
immutable: {{ $values.immutable | default "false" }}
{{- end -}}

{{- define "configmap.tpl" -}}
{{- /* -- Checking types -- */ -}}
{{- if ne 2 (len .) -}}{{- printf "[configmap.tpl] Argument should be a list with only two values (curr: %d)" (len .) | fail -}}{{- end -}}
{{- $values := first . -}}{{- $overlay := last . -}}
{{- if not (kindIs "map" $values) -}}{{- printf ("[configmap.tpl] First item must be a `map` (%s)") (toString $values) | fail -}}{{- end -}}
{{- if not (kindIs "string" $overlay) -}}{{- printf ("[configmap.tpl] Second item must be a `string` (%s)") (toString $overlay) | fail -}}{{- end -}}
{{- /* -- Merge & Return -- */ -}}
{{- $base := include "configmap.base.tpl" $values | fromYaml -}}{{- $over := include $overlay $values | fromYaml -}}
{{- include "merge.deep" (list $over $base) | nindent 0 -}}
{{- end -}}