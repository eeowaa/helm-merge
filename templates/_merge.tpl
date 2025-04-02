{{/* Perform a deep merge of 2 dictionaries, concatenating list values.
     Returns a JSON string to enable recursive calls. Use "merge.concat" instead.
*/}}
{{- define "merge.concat.json.internal" }}
  {{- $a := first . }}
  {{- $b := last . }}
  {{- $result := dict }}
  {{- range uniq (keys $a $b) }}
    {{- if not (hasKey $a .) }}
      {{ $_ := set $result . (get $b .) }}
    {{- else if not (hasKey $b .) }}
      {{ $_ := set $result . (get $a .) }}
    {{- else }}
      {{- $a_value := get $a . }}
      {{- $b_value := get $b . }}
      {{- $a_kind := kindOf $a_value }}
      {{- $b_kind := kindOf $b_value }}
      {{- if ne $a_kind $b_kind }}
        {{- $_ := set $result . $a_value }}
      {{- else if eq "slice" $a_kind }}
        {{- $_ := set $result . (concat $b_value $a_value) }}
      {{- else if eq "map" $a_kind }}
        {{- $_ := set $result . (fromJson (include "merge.concat.json.internal" (list $a_value $b_value))) }}
      {{- else }}
        {{- $_ := set $result . $a_value }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- toJson $result }}
{{- end }}

{{/* Perform a deep merge of zero-to-many dictionaries, concatenating list values.
     Returns a JSON string to enable recursive calls. Use "merge.concat" instead.
*/}}
{{- define "merge.concat.json" }}
  {{- $length := len . }}
  {{- if eq $length 0 }}
    {{- "" }}
  {{- else if eq $length 1 }}
    {{- toJson (first .) }}
  {{- else if eq $length 2 }}
    {{- include "merge.concat.json.internal" (slice . 0 2) }}
  {{- else }}
    {{- $result := fromJson (include "merge.concat.json.internal" (slice . 0 2)) }}
    {{- include "merge.concat.json" (prepend (slice . 2) $result) }}
  {{- end }}
{{- end }}

{{/* Perform a deep merge of zero-to-many dictionaries, concatenating list values.
     Accepts a list of dictionaries and/or YAML strings. Returns a YAML string.
*/}}
{{- define "merge.concat" }}
  {{- $usage := "Usage: merge.concat DICTIONARY..." }}
  {{- if not (kindIs "slice" .) }}
    {{- fail $usage }}
  {{- end }}
  {{- $args := list }}
  {{- range . }}
    {{- if kindIs "string" . }}
      {{- $args = append $args (fromYaml .) }}
    {{- else }}
      {{- $args = append $args . }}
    {{- end }}
    {{- if not (kindIs "map" (last $args)) }}
      {{- fail "merge.concat: type error" }}
    {{- end }}
  {{- end }}
  {{- toYaml (fromJson (default "{}" (include "merge.concat.json" $args))) }}
{{- end }}
