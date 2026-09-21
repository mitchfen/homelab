1. Install terraform, kubectl, az cli
2. az login
3. Set kubeconfig for kubectl
4. `cd terraform`
5. Terraform init: `terraform init`
6. Terraform plan: `terraform plan -var="kubeconfig_path=$HOME/.kube/config"`
7. Terraform apply: `terraform apply -var="kubeconfig_path=$HOME/.kube/config"`