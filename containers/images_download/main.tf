data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "null_resource" "copy_images" {
  provisioner "local-exec" {
    command = <<EOT
               aws ecr get-login-password --region ${data.aws_region.current.name} --profile ${var.profile} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com ; 
               docker pull ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.image}:${var.tag} ;
               docker tag ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.image}:${var.tag} ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.image}:${var.tag} ;
               EOT
  }
}
