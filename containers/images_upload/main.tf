data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "null_resource" "copy_images" {
  provisioner "local-exec" {
    command = <<EOT
               aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com ; 
               docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.image}:${var.tag}
               EOT
  }
}
