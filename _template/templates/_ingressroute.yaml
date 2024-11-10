{{- /* -------------- IngressRouteTCP ------------- */ -}}

{{- define "ingressroutetcp.base.tpl" -}}
{{- $ctx := . -}}{{- $values := .Values.ingressroutetcp | default dict -}}
apiVersion: traefik.io/v1alpha1
kind: IngressRouteTCP
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
  entryPoints:
    {{- $values.entrypoints | default (list "tcp") | toYaml | nindent 4 }}
  routes:
    {{- range $route := ($values.routes | default (list dict)) }}
    - match: {{ $route.match | default "HostSNI(`*`)" | quote }}
      services:
        {{- range $service := ($route.services | default (list dict)) }}
        - name: {{ $service.name | default (include "svcName" $ctx) | quote }}
          port: {{ $service.port | default (include "svcName" $ctx) | quote }}
        {{- end }}
    {{- end }}
{{- end -}}

{{- define "ingressroutetcp.tpl" -}}
{{- /* -- Checking types -- */ -}}
{{- if ne 2 (len .) -}}{{- printf "[ingressroutetcp.tpl] Argument should be a list with only two values (curr: %d)" (len .) | fail -}}{{- end -}}
{{- $values := first . -}}{{- $overlay := last . -}}
{{- if not (kindIs "map" $values) -}}{{- printf ("[ingressroutetcp.tpl] First item must be a `map` (%s)") (toString $values) | fail -}}{{- end -}}
{{- if not (kindIs "string" $overlay) -}}{{- printf ("[ingressroutetcp.tpl] Second item must be a `string` (%s)") (toString $overlay) | fail -}}{{- end -}}
{{- /* -- Merge & Return -- */ -}}
{{- $base := include "ingressroutetcp.base.tpl" $values | fromYaml -}}{{- $over := include $overlay $values | fromYaml -}}
{{- include "merge.deep" (list $over $base) | nindent 0 -}}
{{- end -}}


{{- /* -------------- IngressRouteUDP ------------- */ -}}

{{- define "ingressrouteudp.base.tpl" -}}
{{- $values := .Values.ingressrouteudp | default dict -}}
kind: IngressRouteUDP
spec:
  entryPoints:
    {{- $values.entrypoints | default (list "udp") | toYaml | nindent 4 }}
{{- end -}}

{{- define "ingressrouteudp.tpl" -}}
{{- /* -- Checking types -- */ -}}
{{- if ne 2 (len .) -}}{{- printf "[ingressrouteudp.tpl] Argument should be a list with only two values (curr: %d)" (len .) | fail -}}{{- end -}}
{{- $values := first . -}}{{- $overlay := last . -}}
{{- if not (kindIs "map" $values) -}}{{- printf ("[ingressrouteudp.tpl] First item must be a `map` (%s)") (toString $values) | fail -}}{{- end -}}
{{- if not (kindIs "string" $overlay) -}}{{- printf ("[ingressrouteudp.tpl] Second item must be a `string` (%s)") (toString $overlay) | fail -}}{{- end -}}
{{- /* -- Merge & Return -- */ -}}
{{- $ctx := set $values "ingressroutetcp" ($values.ingressrouteudp | default dict) -}}
{{- $udptpl := include "ingressroutetcp.tpl" (list $ctx "ingressrouteudp.base.tpl") -}}
{{- $base := $udptpl | fromYaml -}}{{- $over := include $overlay $values | fromYaml -}}
{{- include "merge.deep" (list $over $base) | nindent 0 -}}
{{- end -}}

{{- /* -------------- IngressRoute ------------- */ -}}

{{- define "ingressroute.base.tpl" -}}
{{- $values := .Values.ingressroute | default dict -}}
kind: IngressRoute
spec:
  entryPoints:
    {{- $values.entrypoints | default (list "websecure") | toYaml | nindent 4 }}
  routes:
    - kind: Rule
{{- end -}}

{{- define "ingressroute.tpl" -}}
{{- /* -- Checking types -- */ -}}
{{- if ne 2 (len .) -}}{{- printf "[ingressroute.tpl] Argument should be a list with only two values (curr: %d)" (len .) | fail -}}{{- end -}}
{{- $values := first . -}}{{- $overlay := last . -}}
{{- if not (kindIs "map" $values) -}}{{- printf ("[ingressroute.tpl] First item must be a `map` (%s)") (toString $values) | fail -}}{{- end -}}
{{- if not (kindIs "string" $overlay) -}}{{- printf ("[ingressroute.tpl] Second item must be a `string` (%s)") (toString $overlay) | fail -}}{{- end -}}
{{- /* -- Merge & Return -- */ -}}
{{- $ctx := set $values "ingressroutetcp" ($values.ingressroute | default dict) -}}
{{- $tpl := include "ingressroutetcp.tpl" (list $ctx "ingressroute.base.tpl") -}}
{{- $base := $tpl | fromYaml -}}{{- $over := include $overlay $values | fromYaml -}}
{{- include "merge.deep" (list $over $base) | nindent 0 -}}
{{- end -}}