resource "null_resource" "git_clone" {
  count = fileexists("../repos/${var.repo}/.helm/${var.repo}/Chart.yaml") ? 0 : 1
  provisioner "local-exec" {
    command = "cd ../repos ; git clone git@github.com:${var.github_org}/${var.repo}.git ; cd ../repos/${var.repo}/ ; git checkout ${var.branch}"
  }
}

resource "helm_release" "app" {
  name             = var.repo
  chart            = "../repos/${var.repo}/.helm/${var.repo}"
  namespace        = var.namespace
  create_namespace = true
  set {
    name  = "image.repository"
    value = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_repo}"
  }
  set {
    name  = "image.tag"
    value = var.ecr_tag
  }
  set {
    name  = "ingress.certificateArn"
    value = var.certificate_arn
  }

  dynamic "set" {
    for_each = var.env
    content {
      name  = "env.${set.key}"
      value = set.value
    }
  }
  depends_on = [null_resource.git_clone]
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [helm_release.app]

  create_duration = "30s"
}

data "aws_route53_zone" "route53_zone" {
  name = var.zone_name
}

data "aws_lb" "app_lb" {
  count = var.app_domain != "" ? 1 : 0
  tags = {
    "ingress.k8s.aws/stack" = var.repo
  }
  depends_on = [time_sleep.wait_30_seconds]
}

resource "aws_route53_record" "app_record" {
  count   = var.app_domain != "" ? 1 : 0
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = var.app_domain
  type    = "CNAME"
  ttl     = 300
  records = [data.aws_lb.app_lb[0].dns_name]
}
