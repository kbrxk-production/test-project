# Gitlab Common Build pipeline

Con el fin de reutilizar codigo, estos pipelines deben ser llamados con include desde
el pipeline del proyecto segun el compilador necesario:

```yaml
---
include:
  - project: devops/ci-cd/build/common-build
    file: default-jdk{jdk_version}-{build_tool}{build_tool_version}[-{extras}]-build.yml
```

Ejemplo:

```yaml
---
include:
  - project: devops/ci-cd/build/common-build
    file: default-jdk8-maven3-quarkus-build.yml
```
