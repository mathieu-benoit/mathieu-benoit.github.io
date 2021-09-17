---
title: container scanning
date: 2021-09-16
tags: [gcp, container, security]
description: let's see how to scan your containers with gcp
aliases:
    - /container-scanning/
---
[Container scanning](https://cloud.google.com/container-analysis/docs/container-scanning-overview) on both [Container Registry]() or [Artifact Registry]() is a very important feature to enable in order to improve your security posture when dealing with containers.

> Software vulnerabilities are weaknesses that can either cause an accidental system failure or be intentionally exploited.

> Container Analysis provides automated and manual vulnerability scanning for containers in Artifact Registry and Container Registry.

# Automated scanning

Automated scanning scans new images when they're uploaded, and it's really easy to enable that feature:
```
gcloud services enable containerscanning.googleapis.com
```

The important feature included is the Continuous analysis. After the initial scan, the metadata for scanned images are continuously monitors for new vulnerabilities. As Container Analysis receives new and updated vulnerability information from vulnerability sources, it updates the metadata of the scanned images to keep it up-to-date, creating new vulnerability occurrences for new notes and deleting vulnerability occurrences that are no longer valid.

_Important: Container Analysis only updates the vulnerability metadata for images that were pulled in the last 30 days. If you pull an image after this 30-day window, it can take additional time for Container Analysis to update the vulnerability occurrences._

# Manual scanning

Manual (on-demand) scanning is a great way to scan your containers from your local environment or during your Continuous Integration (CI) pipeline in order to shift-left your security checkpoints.

Let's see in actions how it works:
```
# Install the required gcloud's component
gcloud components install local-extract

# Enable the on-demand scanning feature
gcloud services enable ondemandscanning.googleapis.com

# Actually scan a given container image locally
imageName=FIXME
gcloud artifacts docker images scan --format='value(response.scan)' $imageName > scan_id.txt
# You could add the --remote parameter if your image is not present locally but is in Container Registry or Artifact Registry.

# Display the list of vulnerabilities found
gcloud artifacts docker images list-vulnerabilities $(cat scan_id.txt) --format='table(vulnerability.effectiveSeverity, vulnerability.cvssScore, noteName, vulnerability.packageIssue[0].affectedPackage, vulnerability.packageIssue[0].affectedVersion.name, vulnerability.packageIssue[0].fixedVersion.name)'

# If you want to integrate a failure in a bash script, here is an example of how to do it
severity=CRITICAL
gcloud artifacts docker images list-vulnerabilities $(cat scan_id.txt) \
    --format='value(vulnerability.effectiveSeverity)' | if grep -Fxq $severity; \
    then echo 'Failed vulnerability check' && exit 1; else exit 0; fi
```

And that's it, that's how simple it is to scan your container images on-demand.

# Manual scanning in CI

Based on what we just saw, let's see if there is anything else we should do to integrate this part either in Cloud Build pipelines or GitHub actions.

First, you need to make sure the service account used by your CI tool has the proper role:
```
projectId=FIXME
cloudBuildSa=FIXME
gcloud projects add-iam-policy-binding $projectId \
    --member=serviceAccount:$cloudBuildSa \
    --role=roles/ondemandscanning.admin
```

## Cloud Build

Nothing special to do, here is the associated step you should include between your `docker build` and `docker push` steps:
```
- id: gcloud scan
  name: gcr.io/cloud-builders/gcloud
  entrypoint: /bin/bash
  args:
  - -c
  - |
    gcloud artifacts docker images scan '${_IMAGE_NAME}:$SHORT_SHA' --format='value(response.scan)' > scan_id.txt
    gcloud artifacts docker images list-vulnerabilities $(cat scan_id.txt) --format='table(vulnerability.effectiveSeverity, vulnerability.cvssScore, noteName, vulnerability.packageIssue[0].affectedPackage, vulnerability.packageIssue[0].affectedVersion.name, vulnerability.packageIssue[0].fixedVersion.name)'
    gcloud artifacts docker images list-vulnerabilities $(cat scan_id.txt) --format='value(vulnerability.effectiveSeverity)' | if grep -Fxq ${_SEVERITY}; then echo 'Failed vulnerability check' && exit 1; else exit 0; fi
```

## GitHub actions

At the beginning of your pipeline, you need to use the `GoogleCloudPlatform/github-actions/setup-gcloud` action right after the `actions/checkout` one:

```
- uses: actions/checkout@v2.3.4
- uses: GoogleCloudPlatform/github-actions/setup-gcloud@v0.2.1
  with:
    project_id: ${{ secrets.CONTAINER_REGISTRY_PROJECT_ID }}
    service_account_key: ${{ secrets.CONTAINER_REGISTRY_PUSH_PRIVATE_KEY }}
```
This `GoogleCloudPlatform/github-actions/setup-gcloud` is necessary in order to be able to successfully run the following `gcloud components install local-extract` command.

And then here is the associated step you should include between your `docker build` and `docker push` steps:
```
- name: gcloud scan
  run: |
    gcloud components install local-extract --quiet
    gcloud artifacts docker images scan ${IMAGE_NAME} --format='value(response.scan)' > scan_id.txt
    gcloud artifacts docker images list-vulnerabilities $(cat scan_id.txt) --format='table(vulnerability.effectiveSeverity, vulnerability.cvssScore, noteName, vulnerability.packageIssue[0].affectedPackage, vulnerability.packageIssue[0].affectedVersion.name, vulnerability.packageIssue[0].fixedVersion.name)'
    gcloud artifacts docker images list-vulnerabilities $(cat scan_id.txt) --format='value(vulnerability.effectiveSeverity)' | if grep -Fxq ${{ env.SEVERITY }}; then echo 'Failed vulnerability check' && exit 1; else exit 0; fi
```

# Further and complementary resources

- [Vulnerabilities sources](https://cloud.google.com/container-analysis/docs/container-scanning-overview#sources)
- [Pricing](https://cloud.google.com/container-analysis/pricing#vulnz)

Hope you enjoyed that one, stay safe out there! ;)