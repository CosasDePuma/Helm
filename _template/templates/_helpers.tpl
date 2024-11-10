---
# =================================================
#   Names
# =================================================

# --- | name
# Helper function that returns the name of the chart.
# It uses the `name` value if it is set, otherwise it uses `Release.name`.
# It truncates the name to 63 characters and removes any trailing hyphens.
{{- define "name" -}}
{{- $metadata := .Values.metadata | default (dict ) -}}
{{- $metadata.name | default .Release.Name | trunc 63 | trimSuffix "-" | lower }}
{{- end -}}

# --- | svcName
# Helper function that returns the name of the chart being valid for a service name.
# It uses the `name` value if it is set, otherwise it uses `Chart.name`.
# It truncates the name to 10 characters and removes any trailing hyphens.
{{- define "svcName" -}}
{{- include "name" . | trunc 10 | trimSuffix "-" }}
{{- end -}}

# =================================================
#   Labels / Annotations
# =================================================

# --- | labels
# Helper function that returns common labels for the chart.
# It includes the following labels:
# - app: The name of the chart.
# - infrastructure: The infrastructure where the chart is deployed.
# - helm.sh/chart: The name and version of the chart.
# - app.kubernetes.io/name: The name of the chart.
# - app.kubernetes.io/version: The version of the chart.
# - app.kubernetes.io/instance: The name of the release.
# - app.kubernetes.io/managed-by: The name of the release service (Helm).
# It also includes any additional labels defined as the `labels` value.
{{- define "labels" -}}
{{- $metadata := .Values.metadata | default (dict ) -}}
{{- merge (include "labels_defaults" . | fromYaml) ($metadata.labels | default (dict )) | toYaml | nindent 0 }}
{{- end -}}
{{- define "labels_defaults" -}}
app: {{ include "name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/managed-by: {{ .Release.Name | quote }}
app.kubernetes.io/name: {{ include "name" . | quote }}
app.kubernetes.io/part-of: {{ .Chart.Name | quote }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
wtf.kike/repository: "https://github.com/cosasdepuma/helm"
{{- end -}}

# --- | annotations
# Helper function that returns common annotations for the chart.
# It includes any additional annotations defined as the `annotations` value.
{{- define "annotations" -}}
{{- $metadata := .Values.metadata | default (dict ) -}}
{{- if $metadata.annotations }}
{{ $metadata.annotations | toYaml | nindent 0 }}
{{- end }}
{{- end -}}

# --- | merge: deep
# Merge two or more maps deeply. The values from the first argument (overlays) take precedence in case of conflicts.
# This function handles all kind of values, ensuring proper merging of nested structures.
{{- define "merge.deep" -}}
{{- /* -- Check types -- */ -}}
{{- if ne 2 (len .) -}}{{- printf "[merge.deep] Argument should be a list with only two values (curr: %d)" (len .) | fail -}}{{- end -}}
{{- $base := last . -}}{{- $over := first . -}}{{- $kind := kindOf $base -}}
{{- if ne $kind (kindOf $over) -}}{{- printf "[merge.deep] Both values must be of the same type (%s != %s)" (kindOf $over) $kind | fail -}}{{- end -}}
{{- /* -- Merge & Return -- */ -}}
{{- has $kind (list "map" "slice") | ternary (include (printf "_merge.deep.%s" $kind) (list $over $base)) $over -}}
{{- end -}}

{{- define "_merge.deep.map" -}}
{{- /* -- Check types -- */ -}}
{{- if ne 2 (len .) -}}{{- printf "[_merge.deep.map] Argument should be a list with only two values (curr: %d)" (len .) | fail -}}{{- end -}}
{{- $base := last . -}}{{- $over := first . -}}
{{- if not (kindIs "map" $over) -}}{{- printf ("[_merge.deep.map] First item must be a `map` (%s)") (toString $over) | fail -}}{{- end -}}
{{- if not (kindIs "map" $base) -}}{{- printf ("[_merge.deep.map] Second item must be a `map` (%s)") (toString $base) | fail -}}{{- end -}}
{{- /* -- Merge -- */ -}}
{{- range $key, $old := $base -}}
  {{- if not (hasKey $over $key) -}}{{- $over := set $over $key $old -}}
  {{- else -}}{{- $new := index $over $key -}}{{ $kind := kindOf $new -}}
    {{- if eq $kind (kindOf $old) -}}
      {{- if has $kind (list "map" "slice") -}}
        {{- $res := include (printf "_merge.deep.%s" $kind) (list $new $old) -}}
        {{- $over = set $over $key (eq "map" $kind | ternary (fromYaml $res) (fromYamlArray $res)) -}}
      {{- else -}}{{- $over = set $over $key $new -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- /* -- Return -- */ -}}
{{- toYaml $over | nindent 0 -}}
{{- end -}}

{{- define "_merge.deep.slice" -}}
{{- /* -- Checking types -- */ -}}
{{- if ne 2 (len .) -}}{{- printf "[_merge.deep.slice] Argument should be a list with only two values (curr: %d)" (len .) | fail -}}{{- end -}}
{{- $base := last . -}}{{- $over := first . -}}{{- $acc := list -}}
{{- if not (kindIs "slice" $over) -}}{{- printf ("[_merge.deep.slice] First item must be a `slice` (%s)") (toString $over) | fail -}}{{- end -}}
{{- if not (kindIs "slice" $base) -}}{{- printf ("[_merge.deep.slice] Second item must be a `slice` (%s)") (toString $base) | fail -}}{{- end -}}
{{- /* -- Merge -- */ -}}
{{- range $idx, $new := $over -}}
  {{- if lt (len $base) $idx -}}{{- $acc = append $acc $new -}}
  {{- else -}}{{- $old := index $base $idx -}}{{- $kind := kindOf $new -}}
    {{- if and (eq $kind (kindOf $old)) (has $kind (list "map" "slice")) -}}
      {{- $res := include (printf "_merge.deep.%s" $kind) (list $new $old) -}}
      {{- $acc = append $acc (eq "map" $kind | ternary (fromYaml $res) (fromYamlArray $res)) -}}
    {{- else -}}{{- $acc = append $acc $new -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- /* -- Add the rest of the old data */ -}}
{{- if gt (len $base) (len $over) -}}{{- $acc = concat $acc (slice $base (len $over)) -}}{{- end -}}
{{- /* -- Return -- */ -}}
{{- toYaml $acc | nindent 0 -}}
{{- end -}}

{{- define "map2slice" -}}
{{- /* -- Check types -- */ -}}
{{- if not (kindIs "map" .) -}}{{- printf "[map2slice] Argument should be a map (curr: %s)" (. | toString) | fail -}}{{- end -}}
{{- /* -- Convert -- */ -}}
{{- $acc := list -}}
{{- range $_, $value := . -}}{{- $acc = append $acc $value -}}{{- end -}}
{{- toYaml $acc | nindent 0 -}}
{{- end -}}
...
