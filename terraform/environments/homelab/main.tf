module "cluster_manifests" {
  source = "../../modules/kubectl-manifests"

  manifest_dir = "${path.root}/../../../manifests"
}

module "landing_page" {
  source = "../../modules/landing-page"

  html_path = "${path.root}/../../../landing-page/index.html"
}

module "monitoring" {
  source = "../../modules/monitoring"
}