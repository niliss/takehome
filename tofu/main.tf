resource "terraform_data" "k3d_cluster" {
  input = {
    name  = var.k3d_cluster_name
    image = "rancher/k3s:${var.k3s_version}"
  }

  provisioner "local-exec" {
    command = "k3d cluster create ${self.input.name} --image ${self.input.image} --servers 1 --agents 0 -p '8080:80@loadbalancer'"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "k3d cluster delete ${self.input.name}"
  }
}

provider "kubernetes" {
  config_path    = pathexpand("~/.kube/config")
  config_context = "k3d-infra-takehome"
}

resource "kubernetes_namespace" "postgrest" {
  depends_on = [terraform_data.k3d_cluster]

  metadata {
    name = "postgrest"
  }
}

resource "kubernetes_secret" "postgrest_db_secret" {
  depends_on = [kubernetes_namespace.postgrest]

  metadata {
    name      = "postgrest-db-secret"
    namespace = kubernetes_namespace.postgrest.metadata[0].name
  }

  data = {
    DB_NAME      = var.db_name
    DB_USER      = var.db_user
    DB_PASSWORD  = var.db_password
    DB_SUPERUSER = var.db_superuser
    DB_SUPERPASS = var.db_superuser_password
    PGRST_DB_URI = "postgres://${var.db_user}:${var.db_password}@postgres.postgrest.svc.cluster.local:5432/${var.db_name}"
  }

  type = "Opaque"
}