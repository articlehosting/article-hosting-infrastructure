resource "helm_release" "mongo_cluster" {
  name       = "mongodb"
  chart      = "bitnami/mongodb"
  repository = "https://charts.bitnami.com/bitnami"
  version    = "8.2.1"
  namespace  = var.namespace

  set {
    name  = "architecture"
    value = "replicaset"
  }

  set {
    name  = "auth.database"
    value = var.mongo_db_name
  }
  set {
    name  = "auth.username"
    value = var.mongo_username
  }
  set {
    name  = "auth.password"
    value = var.mongo_password
  }
}
