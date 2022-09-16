---
title: ci/gitops with helm and github, part 3 - advanced ci setup
date: 2022-09-15
tags: [gcp, helm, containers, kubernetes, gitops]
description: let's see how to improve the ci/gitops workflow for helm charts with an advanced setup for the ci part
draft: true
aliases:
    - /helm-github-registry-config-sync/
---

## Add advanced checks and tests in the GitHub actions pipeline

+ nomos
+ kpt eval
+ kpt gatekeeper
+ kind

```
name: ci
permissions:
  packages: write
  contents: read
on:
  push:
    branches:
      - main
  pull_request:
env:
  CHART_NAME: my-chart
  IMAGE_TAG: 0.1.0
jobs:
  job:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: helm lint
        run: |
          helm lint $CHART_NAME/
      - name: helm template
        run: |
          mkdir tmp/
          helm template $CHART_NAME $CHART_NAME --version $IMAGE_TAG --output-dir tmp/
      - name: nomos vet
        run: |
          nomos vet --no-api-server-check --path tmp/
      - name: kubeval
        run: |
          kpt fn eval tmp/ --results-dir results --image gcr.io/kpt-fn/kubeval:v0.2 -- strict=true ignore_missing_schemas=true
      - name: helm login
        run: |
          echo ${{ secrets.GITHUB_TOKEN }} | helm registry login ghcr.io -u $ --password-stdin
      - name: helm package
        run: |
          helm package $CHART_NAME --version $IMAGE_TAG
      - name: helm push
        if: ${{ github.event_name == 'push' }}
        run: |
          helm push $CHART_NAME-$IMAGE_TAG.tgz oci://ghcr.io/${{ github.repository_owner }}
```