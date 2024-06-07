resource "kubernetes_manifest" "k8s_manifest" {
  manifest  = var.k8s_manifest_config.manifest
}