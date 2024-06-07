resource "kubernetes_manifest" "k8s_manifest" {
  for_each = { for m in manifest_decode_multi(var.k8s_manifest_config.manifest):m.metadata.name => m }
  manifest = each.value
}