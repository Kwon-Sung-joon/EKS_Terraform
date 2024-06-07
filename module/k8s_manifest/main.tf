resource "kubectl_manifest" "k8s_manifest" {
  yaml_body = var.k8s_manifest_config.yaml_body
}