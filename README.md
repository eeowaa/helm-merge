# Helm Merge

Helm library chart for merging dictionaries. Provides templates to
supplement Helm's built-in [dictionary functions](https://helm.sh/docs/chart_template_guide/function_list/#dictionaries-and-dict-functions).

## Installation

To use this library in a Helm chart, perform the following steps from within
your local chart directory, adjusting paths and versions as necessary:

1. Clone the git repository for Helm Merge:

    ```sh
    git clone --depth 1 -b 0.1.0 https://github.com/eeowaa/helm-merge.git ../helm-merge
    ```

2. Add a library chart dependency to your chart's `Chart.yaml`:

    ```yaml
    dependencies:
      - name: merge
        version: 0.1.0
        repository: file://../helm-merge
    ```

3. Copy the Helm Merge library chart into your `charts/` directory:

    ```sh
    helm dependency update
    ```

For more information about Helm dependencies and library charts, see the
official Helm documentation:

- <https://helm.sh/docs/helm/helm_dependency/>
- <https://helm.sh/docs/topics/library_charts/>

## Usage

This chart currently provides one template in its public interface named
`merge.concat`. This template performs a deep merge of zero-to-many
dictionaries, concatenating list values. It accepts a list of dictionaries
and/or YAML strings and returns a YAML string.

To demonstrate how `merge.concat` works, consider the following `values.yaml`
(using YAML anchors for brevity):

```yaml
---
__1: &1
  a: hello
  b: world
  c: foo
  e: [1, 2]
one:
  <<: *1
  f:
    <<: *1
__2: &2
  a: goodbye
  b: {n: 0}
  d: bar
  e: [3, 4]
two:
  <<: *2
  f:
    <<: *2
...
```

To generate a YAML string by merging `.Values.one` and `.Values.two`, giving
higher precedence to `.Values.one`, you could do this:

```
{{ include "merge.concat" (list .Values.one .Values.two) }}
```

Here is the resulting YAML, with comments added for illustrative purposes
(i.e., no comments in the actual output):

```yaml
a: hello    # .Values.one.a and .Values.two.a are both scalars ------> .Values.one.a
b: world    # .Values.one.b and .Values.two.b have different types --> .Values.one.b
c: foo      # .Values.two.c does not exist --------------------------> .Values.one.c
d: bar      # .Values.one.d does not exist --------------------------> .Values.two.d
e:          # .Values.one.e and .Values.two.e are both lists
- 3         # -------------------------------> {{ concat .Values.two.e .Values.one.e }}
- 4
- 1
- 2
f:          # .Values.one.f and .Values.two.f are both dictionaries
  a: hello  # -------------------------> {{ merge.concat .Values.one.f .Values.two.f }}
  b: world
  c: foo
  d: bar
  e:
  - 3
  - 4
  - 1
  - 2
```

**Note the following**:

1. When it matters (e.g., for container `env` lists), Kubernetes effectively
   gives higher precedence to elements appearing later in lists, allowing them
   to override previous elements, which is why the elements of `.Values.one.e`
   appear **after** the elements of `.Values.two.e` in the merged value of `e`.

2. When two corresponding key/value pairs are both dictionaries, `merge.concat`
   is effectively called recursively on the two values. (The technical details
   are a bit more complex, but the idea is the same.) The same precedence rules
   apply in each recursive call. There is no limit to the depth of recursion.

3. Remember that `merge.concat` does not necessarily require a 2-element list
   for its context (i.e., function input). Passing a list consisting of 0, 1,
   or greater than 2 elements is perfectly valid. This fact makes `merge.concat`
   suitable for working with unknown/user-controlled inputs. When the input
   contains more than 2 elements, dictionaries are iteratively merged from left
   to right with the same application of precedence rules at each step.

4. Also remember that `merge.concat` can take YAML strings as input elements
   rather than (or in addition to) dictionaries. For example, the following
   all work exactly the same and produce the same result:

   - `{{ include "merge.concat" (list .Values.one .Values.two) }}`
   - `{{ include "merge.concat" (list (toYaml .Values.one) .Values.two)) }}`
   - `{{ include "merge.concat" (list .Values.one (toYaml .Values.two)) }}`
