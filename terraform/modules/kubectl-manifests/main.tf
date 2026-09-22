data "kubectl_file_documents" "manifests" {
  for_each = toset(fileset(var.manifest_dir, "**/*.yaml"))
  content  = file("${var.manifest_dir}/${each.value}")
}

locals {
  manifest_documents = {
    for filename, manifest in data.kubectl_file_documents.manifests :
    filename => one(manifest.documents)
    if !strcontains(filename, ".template.")
  }

  namespace_documents = {
    for filename, document in local.manifest_documents :
    filename => document
    if yamldecode(document).kind == "Namespace"
  }

  storage_class_documents = {
    for filename, document in local.manifest_documents :
    filename => document
    if yamldecode(document).kind == "StorageClass"
  }

  workload_documents = {
    for filename, document in local.manifest_documents :
    filename => document
    if !contains(["Namespace", "PersistentVolumeClaim", "StorageClass"], yamldecode(document).kind)
  }
}

resource "kubectl_manifest" "namespaces" {
  for_each  = local.namespace_documents
  yaml_body = each.value

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubectl_manifest" "storage_classes" {
  for_each  = local.storage_class_documents
  yaml_body = each.value
}

resource "kubectl_manifest" "workloads" {
  for_each  = local.workload_documents
  yaml_body = each.value

  depends_on = [kubectl_manifest.namespaces, kubectl_manifest.storage_classes]
}