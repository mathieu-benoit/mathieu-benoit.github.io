---
title: setup of cloud build and gke in different projects
date: 2020-10-18
tags: [gcp, kubernetes, security]
description: fixme
draft: true
aliases:
    - /fixme/
---
+ diagram

Since my first setup of myblog (FIXME) and mygkecluster (FIXME) I now need to split the resources from each other. The typical scenario is I would like to have one project per application I'm deploying in my GKE cluster. With that in place I have more control over the cost, the security and the governance at the project level for each app. The GKE cluster and its project are seen here as shared resources. The above diagram illustrates this scenario.

Here is the minimal setup for the GKE's project:
```

```

We are also enabling the container registry in this shared project to be able to get all the container images of the different apps.

So here we are, now we need to create the Cloud Build setup for a sepcific apps, myblog in this case, here are the associated command lines to accomplish that:
```

```

Complementary to this, we would like improve our security posture here, more specifically by respecting the least privilege principle with the different service account involved here:

For the GKE's project, we just need to follow what I have already documented here (FIXME)

For the apps' project, FIXME
```

```
So typically, by doing this, we just get rid off these permissions: `storage.buckets.create|get|list`, `artifactregistry.*`, and `containeranalysis.occurrences.*` which are not necessary in my context.

That's a wrap! So we just saw how to properly setup Cloud Build able to push containers in GCR as well as deploying them in GKE by being in a different GCP project than the one actually hosting GCR and GKE. You could now repeat this scenario for any apps deployed in a shared GKE cluster. Furthermore, you could leverage this to manage different environments (DEV, QA, PROD) by having their respective GCP projects for example.

Hope you enjoyed that one, cheers!

https://cloud.google.com/cloud-build/docs/cloud-build-service-account
https://cloud.google.com/iam/docs/understanding-roles