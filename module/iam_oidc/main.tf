resource "aws_iam_openid_connect_provider" "default" {
  url = var.iam_oidc_config.url
  client_id_list = var.iam_oidc_config.client_id_list
  thumbprint_list = var.iam_oidc_config.thumbprint_list
}