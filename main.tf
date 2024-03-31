#############
## MINIKUBE ##
##############

module "minikube_cluster" {
  source              = "github.com/kramfs/tf-minikube-cluster"
  cluster_name        = lookup(var.minikube, "cluster_name", "minikube")
  driver              = lookup(var.minikube, "driver", "docker")                 # # Options: docker, podman, kvm2, qemu, hyperkit, hyperv, ssh
  kubernetes_version  = lookup(var.minikube, "kubernetes_version", null)         # See options: "minikube config defaults kubernetes-version" or refer to: https://kubernetes.io/releases/
  container_runtime   = lookup(var.minikube, "container_runtime", "containerd")  # Default: containerd. Options: docker, containerd, cri-o
  nodes               = lookup(var.minikube, "nodes", null)
}


################
## KUBERNETES ##
################

provider "kubernetes" {
  #config_path = "~/.kube/config"
  host = module.minikube_cluster.minikube_cluster_host

  client_certificate     = module.minikube_cluster.minikube_cluster_client_certificate
  client_key             = module.minikube_cluster.minikube_cluster_client_key
  cluster_ca_certificate = module.minikube_cluster.minikube_cluster_ca_certificate
}


##################
## HELM SECTION ##
##################

## HELM PROVIDER ##
provider "helm" {
  kubernetes {
    host = module.minikube_cluster.minikube_cluster_host
    client_certificate     = module.minikube_cluster.minikube_cluster_client_certificate
    client_key             = module.minikube_cluster.minikube_cluster_client_key
    cluster_ca_certificate = module.minikube_cluster.minikube_cluster_ca_certificate
  }
}


## HELM RELEASE ##

## LOCAL-AI
# REF: https://github.com/go-skynet/helm-charts/blob/main/README.md

resource "helm_release" "local-ai" {
  count             = var.local-ai.install ? 1 : 0
  name              = var.local-ai.name
  namespace         = var.local-ai.namespace
  create_namespace  = var.local-ai.create_namespace

  repository = var.local-ai.repository
  chart      = var.local-ai.chart
  version    = lookup(var.local-ai, "version", null) # Chart version

  values = [
    templatefile("./helm_values/local-ai.yaml", {
      #serviceMonitor_enabled = lookup(var.local-ai, "serviceMonitor_enabled", false) # Check if servicemonitor will be enabled
      #wp-password = random_string.wp-password.result
      #memcached_enabled = lookup(var.local-ai, "memcached_enabled", false) # Check if memcached will be enabled
      #storageClass = lookup(var.csi-driver-nfs, "nfs-storageclass-name", "hostPath")
      #storageClass = "${coalesce(kubernetes_storage_class.nfs-csi[0].metadata[0].name, "hostPath")}"
      #storageClass = "${ kubernetes_storage_class.nfs-csi[0].metadata[0].name != null ? kubernetes_storage_class.nfs-csi[0].metadata[0].name : "hostPath" }"
      storageClass = "standard"
    })
  ]

  #depends_on = [ helm_release.csi-driver-nfs ]
  timeout = 600         # In seconds
}

## K8SGPT OPERATOR
# REF: https://charts.k8sgpt.ai/
resource "helm_release" "k8sgpt" {
  count             = var.k8sgpt.install ? 1 : 0
  name              = var.k8sgpt.name
  namespace         = var.k8sgpt.namespace
  create_namespace  = var.k8sgpt.create_namespace

  repository = var.k8sgpt.repository
  chart      = var.k8sgpt.chart
  version    = lookup(var.k8sgpt, "version", null) # Chart version

  #values = [
  #  templatefile("./helm_values/k8sgpt.yaml", {
  #  })
  #]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/helm_values/k8sgpt-localai.yaml"
  }

  depends_on = [ helm_release.local-ai ]
}