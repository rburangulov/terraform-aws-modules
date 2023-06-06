resource "aws_iam_policy" "iam_policy" {
  name        = "lbcontroller-${var.env_name}"
  description = "Allow aws-load-balancer-controller to manage AWS resources"
  path        = "/"
  policy      = file("${path.module}/iam_policy.json")
}

data "aws_iam_policy_document" "load-balancer-role-trust-policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.account_id}:oidc-provider/oidc.eks.${var.region}.amazonaws.com/id/${var.issuer_id}"]
    }

    condition {
      test     = "StringEquals"
      variable = "oidc.eks.${var.region}.amazonaws.com/id/${var.issuer_id}:aud"

      values = [
        "sts.amazonaws.com",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "oidc.eks.${var.region}.amazonaws.com/id/${var.issuer_id}:sub"

      values = [
        "system:serviceaccount:kube-system:aws-load-balancer-controller",
      ]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]
  }
}

resource "aws_iam_role" "AmazonEKSLoadBalancerControllerRole" {
  name               = "AmazonEKSLoadBalancerControllerRole-${var.env_name}"
  assume_role_policy = data.aws_iam_policy_document.load-balancer-role-trust-policy.json
}

resource "aws_iam_role_policy_attachment" "AmazonEKSLoadBalancerControllerRole" {
  policy_arn = aws_iam_policy.iam_policy.arn
  role       = aws_iam_role.AmazonEKSLoadBalancerControllerRole.name
}

resource "local_file" "service_account" {
  content  = templatefile("${path.module}/aws-load-balancer-controller-service-account.tpl", { account_id = var.account_id, env_name = var.env_name })
  filename = "${path.module}/aws-load-balancer-controller-service-account.yaml"
}

resource "null_resource" "apply_service_account" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/aws-load-balancer-controller-service-account.yaml"
  }
  depends_on = [
    local_file.service_account
  ]
}

data "tls_certificate" "issuer_cert" {
  url = var.issuer
}

resource "aws_iam_openid_connect_provider" "openid_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.issuer_cert.certificates[0].sha1_fingerprint]
  url             = var.issuer
}

resource "helm_release" "aws-load-balancer-controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  namespace = "kube-system"

  set {
    name  = "clusterName"
    value = var.env_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}
