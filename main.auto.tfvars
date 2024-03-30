minikube = {
  cluster_name       = "minikube"
  driver             = "docker" # Options: docker, podman, kvm2, qemu, hyperkit, hyperv, ssh
  kubernetes_version = "v1.28.3"  # See available options: "minikube config defaults kubernetes-version" or refer to: https://kubernetes.io/releases/
  container_runtime  = "containerd" # Options: docker, containerd, cri-o
  nodes              = "2"
}


# LOCAL-AI
# REF:
# - https://github.com/go-skynet/helm-charts
# - https://github.com/go-skynet/helm-charts/blob/main/charts/local-ai/values.yaml
# - https://github.com/mudler/LocalAI?tab=readme-ov-file#-usage
local-ai = {
  install           = true
  name              = "local-ai"
  namespace         = "local-ai"
  create_namespace  = true

  repository        = "https://go-skynet.github.io/helm-charts/"
  chart             = "local-ai"
  #version          = "4.6.0"           # Chart version
}

## K8SGPT
k8sgpt = {
  install           = true
  name              = "k8sgpt"
  namespace         = "k8sgpt"
  create_namespace  = true

  repository        = "https://charts.k8sgpt.ai/"
  chart             = "k8sgpt-operator"
  #version          = "4.6.0"           # Chart version
}