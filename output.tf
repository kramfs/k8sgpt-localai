output "minikube_ip" {
  value = module.minikube_cluster.minikube_cluster_host
}

output "minikube_name" {
  value = module.minikube_cluster.minikube_cluster_name
}

output "minikube_domain" {
  value = module.minikube_cluster.minikube_cluster_dns_domain
}