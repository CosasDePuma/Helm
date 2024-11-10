{{- define "deployment.base.tpl" -}}
{{- $values := .Values.deployment | default dict -}}
apiVersion: apps/v1
kind: Deployment
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
  replicas: {{ $values.replicas | default 1 }}
  selector:
    matchLabels:
      app: {{ include "name" . | quote }}
  template:
    metadata:
      labels:
        {{- include "labels" . | nindent 8 }}
        {{- if $values.labels }}
        {{- $values.labels | toYaml | nindent 8 }}
        {{- end }}
      annotations:
        {{- include "annotations" . | nindent 8 }}
        {{- if $values.annotations }}
        {{- $values.annotations | toYaml | nindent 8 }}
        {{- end }}
    spec:
      {{- range $container := $values.containers | default (list (dict "foo" "bar")) }}
      containers:
        - name: {{ $container.name | default (include "name" $) | quote }}
          {{- $image := $container.image | default dict }}
          image: "{{ $image.repository | default "busybox" }}:{{ $image.tag | default "latest" }}"
          imagePullPolicy: {{ $container.pullPolicy | default "IfNotPresent" | quote }}
          {{- if $container.env }}
          env:
          {{- $container.env | toYaml | nindent 4 }}
          {{- end }}
          {{- if $container.envFrom }}
          envFrom:
          {{- $container.envFrom | toYaml | nindent 4 }}
          {{- end }}
          {{- if $container.ports }}
          ports:
          {{- range $port := $container.ports }}
          - containerPort: {{ $port.port }}
              protocol: {{ $port.protocol | default "TCP" | quote }}
              {{- if $port.name }}
              name: {{ $port.name | quote }}
              {{- end }}
          {{- end }}
          {{- end }}
          {{- $resources := $container.resources | default dict }}
          resources:
            {{- $requests := $resources.requests | default dict }}
            requests:
              cpu: {{ $requests.cpu | default "0m" | quote }}
              memory: {{ $requests.memory | default "12Mi" | quote }}
            {{- $limits := $resources.limits | default dict }}
            limits:
              cpu: {{ $limits.cpu | default "10m" | quote }}
              memory: {{ $limits.memory | default "128Mi" | quote }}
          {{- if $container.volumeMounts }}
          volumeMounts:
            {{- range $mount := $container.volumeMounts }}
            - name: {{ $mount.name }}
              mountPath: {{ $mount.mountPath }}
              {{- if $mount.subPath }}
              subPath: {{ $mount.subPath }}
              {{- end }}
              readOnly: {{ $mount.readOnly | default false }}
            {{- end }}
          {{- end }}
      {{- end }}
      {{- if $values.volumes }}
      volumes:
        {{- range $volume := $values.volumes }}
        - name: {{ $volume.name }}
          {{- if $volume.secret }}
          secret:
            secretName: {{ $volume.secret }}
          {{- end }}
          {{- if $volume.configmap }}
          configmap:
            name: {{ $volume.configmap }}
          {{- end }}
        {{- end }}
      {{- end }}
{{- end -}}

{{- define "deployment.tpl" -}}
{{- /* -- Checking types -- */ -}}
{{- if ne 2 (len .) -}}{{- printf "[deployment.tpl] Argument should be a list with only two values (curr: %d)" (len .) | fail -}}{{- end -}}
{{- $values := first . -}}{{- $overlay := last . -}}
{{- if not (kindIs "map" $values) -}}{{- printf ("[deployment.tpl] First item must be a `map` (%s)") (toString $values) | fail -}}{{- end -}}
{{- if not (kindIs "string" $overlay) -}}{{- printf ("[deployment.tpl] Second item must be a `string` (%s)") (toString $overlay) | fail -}}{{- end -}}
{{- /* -- Merge & Return -- */ -}}
{{- $base := include "deployment.base.tpl" $values | fromYaml -}}{{- $over := include $overlay $values | fromYaml -}}
{{- include "merge.deep" (list $over $base) | nindent 0 -}}
{{- end -}}