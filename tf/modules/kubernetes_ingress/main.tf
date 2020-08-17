data "aws_route53_zone" "main_domain_name" {
  name = var.domain_name
}

data "aws_acm_certificate" "issued_certificate" {
  domain      = data.aws_route53_zone.main_domain_name.name
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "helm_release" "nginx_ingress_controller" {
  name       = "ingress-nginx"
  chart      = var.k8s_ingress_chart_name
  repository = var.k8s_ingress_chart_repo
  version    = var.k8s_ingress_chart_version
  namespace  = var.k8s_ingress_namespace

  values = [<<EOF
controller:
    replicaCount: 1
    service:
        annotations: 
            service.beta.kubernetes.io/aws-load-balancer-ssl-cert: ${data.aws_acm_certificate.issued_certificate.arn}
            service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "tcp"
            service.beta.kubernetes.io/aws-load-balancer-type: nlb
            service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "3600"
            service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: "creator=ingress,cluster=${var.k8s_cluster_name}"
    config:
        use-forwarded-headers: "true"
        use-http2: "true"
    resources:
        limits:
            memory: 200Mi
        requests:
            cpu: 100m
            memory: 100Mi
EOF
  ]
  /*
    set {
        name    = "controller.extraArgs.default-ssl-certificate"
        value   = data.aws_acm_certificate.issued_certificate.name
    }
*/

}