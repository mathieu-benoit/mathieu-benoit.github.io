---
title: gcr cleaner
date: 2020-10-07
tags: [gcp, containers]
description: let's see how to cleanup your gcr by deleting old container images.
aliases:
    - /gcr-cleaner/
---
I recently found out that [Google Container Registry (GCR) doesn't have yet a retention nor a cleanup feature](https://b.corp.google.com/issues/113559510). I automatically found two great open source contributions to accomplish this initiated by two Googlers:
- [gcr-cleaner](https://github.com/sethvargo/gcr-cleaner)
    - A containerized Golang app hosted on Cloud Run and triggered by Cloud Scheduler to delete untagged images.
- [gcrgc.sh](https://gist.github.com/ahmetb/7ce6d741bd5baa194a3fac6b1fec8bb7)
    - A bash script which will delete images before a specific date for a given container image.

Why I would like to cleanup my GCR? Good question. Different reasons actually, for example let's imagine I have a lot of repositories and images in GCR, it may imply some costs even if [GCR is not that expensive](https://cloud.google.com/container-registry/pricing). Another reason is I would like to prevent someone to be able to pull and run a previous and old version of my container. Even worst, this old version could have security vulnerabilities...

FYI: here is a command line to get the size of a specific GCR:
```
PROJECT_ID=the-project-id-where-your-gcr-is
gsutil du -hs gs://artifacts.$PROJECT_ID.appspot.com
```

Let's execute the `gcrgc.sh` script from the second approach highlighted earlier:
```
curl https://gist.githubusercontent.com/ahmetb/7ce6d741bd5baa194a3fac6b1fec8bb7/raw/2a838649c037d6d7b3c7c52dffcd95176adf764b/gcrgc.sh -o gcrgc.sh
chmod +x gcrgc.sh
IMAGE_NAME=the-name-of-your-container-image
./gcrgc.sh gcr.io/$PROJECT_ID/$IMAGE_NAME 2020-08-01
```

You could also find altenative criteria to delete images, [like for example here](https://medium.com/@daangeurts/deleting-unused-images-from-google-cloud-container-registry-2fec12901ce6) another way to see this by keeping only X number of images for a specific image name. You may also want to have this as a [recurrent Cloud Build like illustrated here](https://gist.github.com/hazcod/232d4aa30d2778f0ab5cc0cd21a53281).

In other words, you could adapt those scripts for your own needs.

Cheers!