data "aws_route53_zone" "main_domain_name" {
    name = var.domain_name
}

data "aws_acm_certificate" "issued_certificate" {
    domain      = data.aws_route53_zone.main_domain_name.name
    statuses    = ["ISSUED"]
    most_recent = true
}

resource "helm_release" "nginx_ingress_controller" {
    name        = "ingress-nginx"
    chart       = var.k8s_ingress_chart_name
    repository  = var.k8s_ingress_chart_repo
    version     = var.k8s_ingress_chart_version
    namespace   = var.k8s_ingress_namespace

    set {
        name    = "controller.replicaCount"
        value   = "1"
    }

    set {
        name    = "controller.annotations.service.beta.kubernetes.io/aws-load-balancer-ssl-cert"
        value   = data.aws_acm_certificate.issued_certificate.arn
    }

    set {
        name    = "controller.annotations.service.beta.kubernetes.io/aws-load-balancer-backend-protocol"
        value   = "tcp"
    }

    set {
        name    = "controller.annotations.service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled"
        value   = "true"
    }

    set {
        name    = "controller.annotations.service.beta.kubernetes.io/aws-load-balancer-type"
        value   = "nlb"
    }

    set {
        name    = "controller.annotations.service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout"
        value   = "3600"
    }

    set {
        name    = "controller.annotations.service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags"
        value   = "creator=ingress,cluster=${var.k8s_cluster_name}"
    }
/*
    set {
        name    = "controller.extraArgs.default-ssl-certificate"
        value   = data.aws_acm_certificate.issued_certificate.name
    }
*/
    set {
        name    = "controller.config.use-forwarded-headers"
        value   = "true"
    }

    set {
        name    = "controller.config.use-http2"
        value   = "true"
    }

    set {
        name    = "controller.resources.limits.memory"
        value   = "200Mi"
    }

    set {
        name    = "controller.resources.requests.cpu"
        value   = "100m"
    }

    set {
        name    = "controller.resources.requests.memory"
        value   = "100Mi"
    }

}