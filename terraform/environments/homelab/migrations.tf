moved {
  from = kubectl_manifest.namespaces
  to   = module.cluster_manifests.kubectl_manifest.namespaces
}

moved {
  from = kubectl_manifest.storage_classes
  to   = module.cluster_manifests.kubectl_manifest.storage_classes
}

moved {
  from = kubectl_manifest.workloads
  to   = module.cluster_manifests.kubectl_manifest.workloads
}

moved {
  from = kubectl_manifest.landing_page_namespace
  to   = module.landing_page.kubectl_manifest.namespace
}

moved {
  from = kubectl_manifest.landing_page_html
  to   = module.landing_page.kubectl_manifest.html
}

moved {
  from = kubectl_manifest.landing_page
  to   = module.landing_page.kubectl_manifest.deployment
}

moved {
  from = kubectl_manifest.landing_page_service
  to   = module.landing_page.kubectl_manifest.service
}