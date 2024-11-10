{{- define "service.base.tpl" -}}
{{- $values := .Values.service | default dict -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "name" . | quote }}
  labels:
    {{- include "labels" . | nindent 4 }}
    {{- if $values.labels }}
    {{- $values.labels | toYaml | nindent 4 }}
    {{- end }}
  annotations:
    {{- include "annotations" . | nindent 4 }}
    {{- if $values.annotations }}
    {{- $values.annotations | toYaml | nindent 4 }}
    {{- end }}
spec:
  {{- if $values.ports }}
  ports:
    {{- range $port := $values.ports }}
    - name: {{ $port.name | default (include "svcName" .) | quote }}
      {{- if $port.port }}
      port: {{ $port.port }}
      {{- end }}
      protocol: {{ $port.protocol | default "TCP" }}
      targetPort: {{ $port.targetPort | default (include "svcName" $) | quote }}
    {{- end }}
  {{- end }}
  selector:
    app: {{ include "name" . | quote }}
  type: {{ $values.type | default "ClusterIP" }}
{{- end -}}

{{- define "service.tpl" -}}
{{- /* -- Checking types -- */ -}}
{{- if ne 2 (len .) -}}{{- printf "[service.tpl] Argument should be a list with only two values (curr: %d)" (len .) | fail -}}{{- end -}}
{{- $values := first . -}}{{- $overlay := last . -}}
{{- if not (kindIs "map" $values) -}}{{- printf ("[service.tpl] First item must be a `map` (%s)") (toString $values) | fail -}}{{- end -}}
{{- if not (kindIs "string" $overlay) -}}{{- printf ("[service.tpl] Second item must be a `string` (%s)") (toString $overlay) | fail -}}{{- end -}}
{{- /* -- Merge & Return -- */ -}}
{{- $base := include "service.base.tpl" $values | fromYaml -}}{{- $over := include $overlay $values | fromYaml -}}
{{- include "merge.deep" (list $over $base) | nindent 0 -}}
{{- end -}}