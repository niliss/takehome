# Infrastructure Take Home

Treat this system as a production system.

This repository provisions a **local Kubernetes environment** using **OpenTofu**, deploys **PostgreSQL**, **PostgREST**, and seeds the database.

The final result is a REST endpoint that exposes database records through PostgREST.

---

# Architecture

The environment consists of:

- **OpenTofu** → Infrastructure provisioning
- **k3d** → Local Kubernetes cluster
- **PostgreSQL** → Database backend
- **Kubernetes Job** → Data seeding
- **PostgREST** → REST API for PostgreSQL
- **Argo CD** → GitOps deployment of Kubernetes resources

```text
OpenTofu
|
| creates
▼
k3d Kubernetes Cluster
|
├── PostgreSQL
|
├── Kubernetes Job (seed database)
|
└── PostgREST API
|
▼
/people endpoint
```

Argo CD manages the application manifests stored in the k8s directory.

---

## Prerequisites

Install the following tools:

- Docker
- k3d
- OpenTofu (or Terraform)
- kubectl
- git

Verify installation:

```bash
docker --version
k3d version
tofu version
kubectl version --client
git --version
```

---

## Step 1 — Clone Repository

```bash
git clone https://github.com/niliss/takehome
cd takehome
```

---

## Step 2 — Configure Terraform Variables

Copy the example variables file.

```bash
cp tofu/terraform.tfvars.example tofu/terraform.tfvars
```

Edit if needed.

Example:

```terraform
db_name                = "appdbs"
db_user                = "postgrest_user"
db_password            = "super_secret_password_that_should_be_in_a_vault"
db_superuser           = "admin_user"
db_superuser_password  = "change_me_super_password"
```

---

## Step 3 — Create Infrastructure

OpenTofu creates:

- k3d Kubernetes cluster
- namespace `postgrest`
- Kubernetes secrets containing database credentials

Run:

```bash
cd tofu
tofu init
tofu apply -var-file=terraform.tfvars
```

Return to repository root:

```bash
cd ..
```

---

## Step 4 — Install Argo CD

Install Argo CD into the cluster using the manifests in the argocd directory.

```bash
kubectl create namespace argocd
kubectl apply -k argocd/
```

Verify Argo CD pods:

```bash
kubectl -n argocd get pods
```

Wait until all pods are Running.

---

## Step 5 — Deploy Application with Argo CD

Create the Argo CD application:

```bash
kubectl apply -f argocd/application.yaml
```

Verify the application:

```bash
kubectl -n argocd get applications
```

Argo CD will now deploy:

- PostgreSQL
- database seed job
- PostgREST API

from the `k8s/` directory.

---

## Step 6 — Verify Workloads

Check Kubernetes resources:

```bash
kubectl -n postgrest get pods
kubectl -n postgrest get jobs
kubectl -n postgrest get svc
```

Expected result:

```
postgres pod running
postgrest pod running
postgrest-seed job completed
```

---

## Step 7 — Access PostgREST API

Forward the PostgREST service:

```bash
kubectl -n postgrest port-forward svc/postgrest 3000:3000
```

Open in your browser: http://localhost:3000/people

You should see JSON data inserted by the Kubernetes Job.

---

## Expected Output

Example API response:

![/people endpoint](https://p130.p1.n0.cdn.zight.com/items/04ujgZZE/c6c610f2-2b30-46d6-80f5-1976c62aa55c.jpg?v=7aba4f624bcdf82b7e6225e3152882df)

```json
[
  {
    "id": 1,
    "name": "Niels",
    "email": "niels@example.com"
  },
  {
    "id": 2,
    "name": "Alice",
    "email": "alice@example.com"
  },
  {
    "id": 3,
    "name": "Bob",
    "email": "bob@example.com"
  }
]
```

---

## Access Argo CD UI

Port forward the Argo CD server:

```bash
kubectl -n argocd port-forward svc/argocd-server 8081:443
```

Open: https://localhost:8081

Retrieve the admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 --decode; echo
```

Login with:

- username: `admin`
- password: `<decoded password>`

You should see the postgrest application synced and healthy.

![Argo CD UI](https://p130.p1.n0.cdn.zight.com/items/X6u1D6g0/5810a1c6-630f-474c-b581-29dd082b9679.jpg?v=a23c0f568218435422404d1ec8c3f748)

---

## Kubernetes Resources Managed by Argo CD

```
k8s/
├── postgres/
│   └── deployment.yaml
├── jobs/
│   └── seed-job.yaml
└── postgrest/
    └── deployment.yaml
```

---

## Secrets Management

Database credentials are injected using OpenTofu into Kubernetes.

- **Secret:** `postgrest-db-secret`
- **Namespace:** `postgrest`

Secrets include:

- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`
- `DB_SUPERUSER`
- `DB_SUPERPASS`
- `PGRST_DB_URI`

---

## Data Injection

A Kubernetes Job seeds the database.

```
k8s/jobs/seed-job.yaml
```

This job:

- waits for PostgreSQL
- creates schema `api`
- creates table `people`
- inserts sample data

---

## Git Ignore

Sensitive files are excluded from the repository.

```
*.tfvars
*.tfstate
*.tfstate.*
```

---

## Summary

This repository demonstrates:

- Infrastructure provisioning with OpenTofu
- Kubernetes cluster creation using k3d
- Secret management via Terraform/OpenTofu
- GitOps deployment with Argo CD
- PostgREST exposing PostgreSQL as a REST API
- Data seeding using Kubernetes Jobs

The result is a fully reproducible local environment exposing a REST API backed by PostgreSQL.