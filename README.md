# bozz-gitops

Practice on GitHub, Cloud Build, Cloud Source Repository   

Ref : https://cloud.google.com/kubernetes-engine/docs/tutorials/gitops-cloud-build

## Get zones list
```
gcloud compute zones list
```
## Get project ID
```
PROJECT_ID=$(gcloud config get-value project)
```
## Get project number
```
PROJECT_NUMBER="$(gcloud projects describe ${PROJECT_ID} --format='get(projectNumber)')"
```
## Create k8s cluster
```
gcloud container clusters create bozz-gitpos --num-nodes 1 --zone asia-southeast1-b # cluster_name, node number, zone
```
## Create repository on cloud
```
gcloud source repos create bozz-gitops-app # Repo name
gcloud source repos create bozz-gitops-env 
```
## Get list of source repository
```
gcloud source repos list
```
## Clone source repository
```
gcloud source repos clone <repo_name>
```

## Add remote google
```
git remote add google "https://source.developers.google.com/p/${PROJECT_ID}/r/bozz-gitops-app"
```
## Enable service 
```
gcloud services enable container.googleapis.com 
gcloud services enable cloudbuild.googleapis.com
gcloud services enable sourcerepo.googleapis.com
gcloud services enable containeranalysis.googleapis.com
```
# CI : commit/push => build => push image => registry
## Add tag then build using cloudbuild
```
COMMIT_ID="$(git rev-parse --short=7 HEAD)"
gcloud builds submit --tag="gcr.io/${PROJECT_ID}/bozz-gitops:${COMMIT_ID}" .
```

# CD : commit/push => build => push image => registry => trigger => deploy => GKE
## grant cloud build access gke 
```
PROJECT_NUMBER="$(gcloud projects describe ${PROJECT_ID} --format='get(projectNumber)')"
gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
    --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role=roles/container.developer
```

### grant source repo access cloud build 
```
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
```