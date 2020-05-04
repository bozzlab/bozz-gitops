#!/bin/sh

# get zones list
gcloud compute zones list

# get project ID
PROJECT_ID=$(gcloud config get-value project)
# get project number 
PROJECT_NUMBER="$(gcloud projects describe ${PROJECT_ID} --format='get(projectNumber)')"

# create source repo
gcloud source repos create bozz-gitops-app # Repo name
gcloud source repos create bozz-gitops-env 

## get list of source repository
gcloud source repos list

## clone source repository
gcloud source repos clone <repo_name>


# create k8s cluster
gcloud container clusters create bozz-gitpos --num-nodes 1 --zone asia-southeast1-b # cluster_name, node number, zone

# create repository on cloud
gcloud source repos create bozz-gitops-app # Repo name
gcloud source repos create bozz-gitops-env 

# add remote google
git remote add google "https://source.developers.google.com/p/${PROJECT_ID}/r/bozz-gitops-app"

# enable service 
gcloud services enable container.googleapis.com 
gcloud services enable cloudbuild.googleapis.com
gcloud services enable sourcerepo.googleapis.com
gcloud services enable containeranalysis.googleapis.com

### CI : commit/push => build => push image => registry
# add tag then build using cloudbuild
COMMIT_ID="$(git rev-parse --short=7 HEAD)"
gcloud builds submit --tag="gcr.io/${PROJECT_ID}/bozz-gitops:${COMMIT_ID}" .

### CD : commit/push => build => push image => registry => trigger => deploy => GKE
# grant cloud build acess gke 
PROJECT_NUMBER="$(gcloud projects describe ${PROJECT_ID} --format='get(projectNumber)')"
gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
    --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role=roles/container.developer


### grant source repo access cloud build 
PROJECT_NUMBER="$(gcloud projects describe ${PROJECT_ID} \
    --format='get(projectNumber)')"
cat >/tmp/bozz-gitops-env-policy.yaml <<EOF
bindings:
- members:
  - serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com
  role: roles/source.writer
EOF
gcloud source repos set-iam-policy \
    bozz-gitops-env /tmp/bozz-gitops-env-policy.yaml