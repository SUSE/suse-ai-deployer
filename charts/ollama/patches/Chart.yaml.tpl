# SPDX-License-Identifier: MIT
#!BuildTag: charts/ollama:${VERSION}-%RELEASE%
#!BuildTag: charts/ollama:${VERSION}
annotations:
  helm.sh/images: |
    - image: ${CONTAINER_REGISTRY}/containers/ollama:${APP_VERSION}
      name: ollama
    - image: ${CONTAINER_REGISTRY}/containers/bci-busybox:15.5
      name: bci-busybox
apiVersion: v2
appVersion: ${APP_VERSION}
description: Get up and running with large language models locally.
home: https://apps.rancher.io/applications/ollama
icon: https://ollama.ai/public/ollama.png
keywords:
- ai
- llm
- llama
- mistral
kubeVersion: ^1.16.0-0
maintainers:
- url: https://www.suse.com
  name: SUSE LLC
name: ollama
sources:
- https://github.com/ollama/ollama
type: application
version: ${VERSION}
