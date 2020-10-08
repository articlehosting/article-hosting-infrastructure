data "aws_region" "current" {}

resource "kubernetes_namespace" "cw_namespace" {
  metadata {
    annotations = {
        name = var.cw_namespace_name
    }

    labels = {
        name = var.cw_namespace_name
    }

    name = var.cw_namespace_name
  }
}

resource "kubernetes_service_account" "cw_service_acc" {
    metadata {
        name        = var.cw_service_acc_name
        namespace   = var.cw_namespace_name
    }
}

resource "kubernetes_cluster_role" "cw_cluster_role" {
    metadata {
        name    = var.cw_cluster_role_name
    }

    rule {
        api_groups   = [""]
        resources   = ["pods", "nodes", "endpoints"]
        verbs       = ["list", "watch"]
    }

    rule {
        api_groups   = ["apps"]
        resources   = ["replicasets"]
        verbs       = ["list", "watch"]
    }

    rule {
        api_groups   = ["batch"]
        resources   = ["jobs"]
        verbs       = ["list", "watch"]
    }

    rule {
        api_groups   = [""]
        resources   = ["nodes/proxy"]
        verbs       = ["get"]
    }

    rule {
        api_groups   = [""]
        resources   = ["nodes/stats", "configmaps", "events"]
        verbs       = ["create"]
    }

    rule {
        api_groups       = [""]
        resources       = ["configmaps"]
        resource_names   = ["cwagent-clusterleader"]
        verbs           = ["get","update"]
    }
}

resource "kubernetes_cluster_role_binding" "cw_cluster_role_binding" {
    metadata {
        name    = var.cw_role_binding_name
    }

    role_ref {
        kind        = "ClusterRole"
        api_group    = "rbac.authorization.k8s.io"
        name        = var.cw_cluster_role_name
    }

    subject {
        kind        = "ServiceAccount"
        name        = var.cw_service_acc_name
        namespace   = var.cw_namespace_name
    }
}

resource "kubernetes_config_map" "cw_agent_configmap" {
    metadata {
        name        = var.cw_agen_config_name
        namespace   = var.cw_namespace_name
    }

    data = {
        "cwagentconfig.json" = file("${path.module}/configs/cw_config.json")
    }
}

resource "kubernetes_daemonset" "cw_daemon_set" {
    metadata {
        name        = var.cw_daemon_set_name
        namespace   = var.cw_namespace_name
    }

    spec {
        selector {
            match_labels = {
                name    = var.cw_daemon_set_name
            }
        }

        template {
            metadata {
                labels = {
                    name = var.cw_daemon_set_name
                }
            }

            spec {
                container {
                    name    = "cloudwatch-agent" 
                    image   = "amazon/cloudwatch-agent:1.247345.36b249270"

                    resources {
                        limits {
                            cpu     = "200m" 
                            memory  = "200Mi"
                        }
                        requests {
                            cpu     = "200m" 
                            memory  = "200Mi"
                        }
                    }

                    env {
                        name = "HOST_IP"
                        value_from {
                            field_ref {
                                field_path = "status.hostIP"
                            }
                        }
                    }

                    env {
                        name = "HOST_NAME"
                        value_from {
                            field_ref {
                                field_path = "spec.nodeName"
                            }
                        }
                    }

                    env {
                        name = "K8S_NAMESPACE"
                        value_from {
                            field_ref {
                                field_path = "metadata.namespace"
                            }
                        }
                    }

                    env {
                        name    = "CI_VERSION"
                        value   = "k8s/1.2.2"
                    }

                    volume_mount {
                        name        = "cwagentconfig"
                        mount_path  = "/etc/cwagentconfig"
                    }
                    volume_mount {
                        name        = "rootfs"
                        mount_path  = "/rootfs"
                        read_only   = "true"
                    }
                    volume_mount {
                        name        = "dockersock"
                        mount_path  = "/var/run/docker.sock"
                        read_only   = "true"
                    }
                    volume_mount {
                        name        = "varlibdocker"
                        mount_path  = "/var/lib/docker"
                        read_only   = "true"
                    }
                    volume_mount {
                        name        = "sys"
                        mount_path  = "/sys"
                        read_only   = "true"
                    }
                    volume_mount {
                        name        = "devdisk"
                        mount_path  = "/dev/disk"
                        read_only   = "true"
                    }
                }

                volume {
                    name = "cwagentconfig"
                    config_map {
                        name    = var.cw_agen_config_name
                    }
                }
                volume {
                    name = "rootfs"
                    host_path {
                        path = "/"
                    }  
                }
                volume {
                    name = "dockersock"
                    host_path {
                        path = "/var/run/docker.sock"
                    }
                }
                volume {
                    name = "varlibdocker"
                    host_path {
                        path = "/var/lib/docker"
                    }
                }
                volume {
                    name = "sys"
                    host_path {
                        path = "/sys"
                    }
                }
                volume {
                    name = "devdisk"
                    host_path {
                        path = "/dev/disk/"
                    }
                }

                termination_grace_period_seconds    = "60"
                service_account_name                =  var.cw_service_acc_name
            }
        }
    }
}

resource "kubernetes_config_map" "cluster_info" {
    metadata {
        name        = "cluster-info"
        namespace   = var.cw_namespace_name
    }

    data = {
        "cluster.name"  = var.k8s_cluster_name
        "logs.region"   = data.aws_region.current.name
    }
}

resource "kubernetes_config_map" "fluentd_config" {
    metadata {
        name        = var.fluentd_config_name
        namespace   = var.cw_namespace_name
        labels      = {
            "k8s-app" = "fluentd-cloudwatch"
        }
    }

    data = {
        "fluent.conf"       = file("${path.module}/configs/fluent.conf")
        "containers.conf"   = file("${path.module}/configs/containers.conf")
        "systemd.conf"      = file("${path.module}/configs/systemd.conf")
        "host.conf"         = file("${path.module}/configs/host.conf")
    }
}

resource "kubernetes_service_account" "fluentd_service_acc" {
    metadata {
        name        = var.fluentd_service_acc_name
        namespace   = var.cw_namespace_name
    }
}

resource "kubernetes_cluster_role" "fluentd_cluser_role" {
    metadata {
        name    = var.fluentd_cluster_role_name
    }

    rule {
        api_groups   = [""]
        resources   = ["namespaces", "pods", "pods/logs"]
        verbs       = ["get", "list", "watch"]
    }
}

resource "kubernetes_cluster_role_binding" "fluentd_role_binding" {
    metadata {
        name    = var.fluentd_role_binding_name
    }

    role_ref {
        api_group   = "rbac.authorization.k8s.io"
        kind        = "ClusterRole"
        name        = var.fluentd_cluster_role_name
    }

    subject {
        kind        = "ServiceAccount"
        name        = var.fluentd_service_acc_name
        namespace   = var.cw_namespace_name
    }
}

resource "kubernetes_daemonset" "fluend_daemon_set" {
    metadata {
        name        = var.fluentd_ds_name
        namespace   = var.cw_namespace_name
    }

    spec {
        selector {
            match_labels = {
                "k8s-app" = var.fluentd_ds_name
            }
        }

        template {
            metadata {
                labels = {
                    "k8s-app" = var.fluentd_ds_name
                }
                annotations = {
                    config_hash = "8915de4cf9c3551a8dc74c0137a3e83569d28c71044b0359c2578d2e0461825"
                }
            }

            spec {
                service_account_name                = var.fluentd_service_acc_name
                termination_grace_period_seconds    = "30"

                init_container {
                    name    = "copy-fluentd-config"
                    image   = "busybox"
                    command = ["sh", "-c", "cp /config-volume/..data/* /fluentd/etc"]
                    volume_mount {
                        name        = "config-volume"
                        mount_path  = "/config-volume"
                    }
                    volume_mount {
                        name        = "fluentdconf"
                        mount_path  = "/fluentd/etc"
                    }
                }

                init_container {
                    name    = "update-log-driver"
                    image   = "busybox"
                    command = ["sh", "-c", ""] 
                }

                container {
                    name    = "fluentd-cloudwatch"
                    image   = "fluent/fluentd-kubernetes-daemonset:v1.7.3-debian-cloudwatch-1.0"

                    env {
                        name = "REGION"
                        value_from {
                            config_map_key_ref {
                                name    = "cluster-info"
                                key     = "logs.region"
                            }
                        }
                    }

                    env {
                        name = "CLUSTER_NAME"
                        value_from {
                            config_map_key_ref {
                                name    = "cluster-info"
                                key     = "cluster.name"
                            }
                        }
                    }

                    env {
                        name    = "CI_VERSION"
                        value   = "k8s/1.2.2"
                    }

                    resources {
                        limits {
                            memory  = "400Mi"
                        }
                        requests {
                            cpu     = "100m"
                            memory  = "200Mi"
                        }
                    }

                    volume_mount {
                        name        = "config-volume"
                        mount_path  = "/config-volume"
                    }
                    volume_mount {
                        name        = "fluentdconf"
                        mount_path  = "/fluentd/etc"
                    }
                    volume_mount {
                        name        = "varlog"
                        mount_path  = "/var/log"
                    }
                    volume_mount {
                        name        = "varlibdockercontainers"
                        mount_path  = "/var/lib/docker/containers"
                        read_only   = "true"
                    }
                    volume_mount {
                        name        = "runlogjournal"
                        mount_path  = "/run/log/journal"
                        read_only   = "true"
                    }
                    volume_mount {
                        name        = "dmesg"
                        mount_path  = "/var/log/dmesg"
                        read_only   = "true"
                    }
                } 

                volume {
                    name = "config-volume"
                    config_map {
                        name    = "fluentd-config"
                    }
                }

                volume { 
                    name = "fluentdconf"
                    empty_dir {}
                }

                volume {
                    name = "varlog"
                    host_path {
                        path = "/var/log"
                    }
                }

                volume {
                    name = "varlibdockercontainers"
                    host_path {
                        path = "/var/lib/docker/containers"
                    }
                }

                volume {
                    name = "runlogjournal"
                    host_path {
                        path = "/run/log/journal"
                    }
                }

                volume {
                    name = "dmesg"
                    host_path {
                        path = "/var/log/dmesg"
                    }
                }
            }
        }
    }
}