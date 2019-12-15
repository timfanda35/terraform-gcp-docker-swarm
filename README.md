# Terraform GCP Docker swarm

Ser environment

```
export PROJECT=$(gcloud config get-value core/project)
export TF_SA="terraform"
```

Enable Compute Engine API

```
gcloud services enable compute.googleapis.com
```

Create service account for Terraform

```
gcloud iam service-accounts create ${TF_SA} \
  --display-name="Terraform Service Account" \
  --description="The service account for Terraform"
```

```
gcloud projects add-iam-policy-binding ${PROJECT} \
  --member="serviceAccount:${TF_SA}@${PROJECT}.iam.gserviceaccount.com" \
  --role=roles/editor
```

```
gcloud iam service-accounts keys create credentials.json \
  --iam-account="${TF_SA}@${PROJECT}.iam.gserviceaccount.com"
```

Create a SSH user for Terraform

```
ssh-keygen -t rsa -f ./${TF_SA}_key -C ${TF_SA}
```

Deploy docker swarm visualizer

```
docker service create --name=visualizer --publish=8080:8080/tcp \
       --constraint=node.role==manager --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
       dockersamples/visualizer
```

Deploy a simple service

Edit `stack.yml`

```
version: '3'

services:
  web:
    deploy:
      replicas: 3
      placement:
        constraints:
          - node.role == worker
    image: nginx
    ports:
      - "8081:80"
```

```
docker stack deploy -c stack.yml frontend
```