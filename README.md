# Usage

## Steps Summary

- Bring up the cluster
- Install the csi-driver-nfs
- Create and apply a Kubernetes Storage Class (sc) that uses the `nfs.csi.k8s.io` CSI driver.
    - Uses the terraform `local_file provisioner` to create the `serviceClass` manifest and share the serviceClass name with the sample app later
- Create a new PersistentVolumeClaim (pvc) using the nfs-csi storage class. This is as simple as specifying `storageClassName: nfs-csi` in the PVC definition
    - Verify it with: `kubectl describe pvc my-pvc`
     ```
      Type     Reason                 Age                    From                                                          Message
      ----     ------                 ----                   ----                                                          -------
      Normal   ExternalProvisioning   4m10s (x2 over 4m10s)  persistentvolume-controller                                   Waiting for a volume to be created either by the external provisioner 'nfs.csi.k8s.io' or manually by the system administrator. If volume creation is delayed, please verify that the provisioner is running and correctly registered.
      Normal   Provisioning           4m10s                  nfs.csi.k8s.io_minikube_a046549b-e2f2-489e-a5f3-752a91490c3b  External provisioner is provisioning volume for claim "default/my-pvc"
      Normal   ProvisioningSucceeded  4m10s                  nfs.csi.k8s.io_minikube_a046549b-e2f2-489e-a5f3-752a91490c3b  Successfully provisioned volume pvc-f199c164-725b-46a4-97c0-1dc69190518d

     ```
- Install MetalLB to handout Load Balancer IP when using minikube
- Install Local-AI, an OpenAI compatible API
- Try to validate the API and get the model ID:
    ```
    # Using cURL
    ❯ curl -s http://192.168.49.50/v1/models | jq '.data[].id'
    "ggml-gpt4all-j_f5d8f27287d3"

    # Using HTTPie
    ❯ http http://192.168.49.50/v1/models | jq '.data[].id'
    "ggml-gpt4all-j_f5d8f27287d3"
    ```

 Note: The above will be done with Terraform

## TASK UP
To bring up the cluster:
```
task up
```

Example:
```
❯ task up
task: [init] terraform init -upgrade

Initializing the backend...
Upgrading modules...
Downloading git::https://github.com/kramfs/tf-minikube-cluster.git for minikube_cluster...
- minikube_cluster in .terraform/modules/minikube_cluster

Initializing provider plugins...
- Finding latest version of hashicorp/random...
- Finding latest version of hashicorp/kubernetes...
- Finding scott-the-programmer/minikube versions matching "~> 0.3"...
- Finding latest version of hashicorp/helm...
- Finding latest version of hashicorp/local...
- Installing scott-the-programmer/minikube v0.3.10...
- Installed scott-the-programmer/minikube v0.3.10 (self-signed, key ID 336AB9C62499A32D)
- Installing hashicorp/helm v2.12.1...
- Installed hashicorp/helm v2.12.1 (signed by HashiCorp)
- Installing hashicorp/local v2.5.1...
- Installed hashicorp/local v2.5.1 (signed by HashiCorp)
- Installing hashicorp/random v3.6.0...
- Installed hashicorp/random v3.6.0 (signed by HashiCorp)
- Installing hashicorp/kubernetes v2.27.0...
- Installed hashicorp/kubernetes v2.27.0 (signed by HashiCorp)

....

Terraform has been successfully initialized!

.
.
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

minikube_domain = "cluster.local"
minikube_ip = "https://192.168.49.2:8443"
minikube_name = "minikube"
wp-password = "JRi33652wGWDbiYj"
```



## TASK CLEANUP
To destroy and clean up the cluster:
```
task cleanup
```

Example:

```
❯ task cleanup
task: [destroy] terraform destroy $TF_AUTO
random_string.wp-password: Refreshing state... [id=JRi33652wGWDbiYj]
local_file.sc-nfs: Refreshing state... [id=453b196645508304236c4e213cffb17540f9409d]
module.minikube_cluster.minikube_cluster.docker: Refreshing state... [id=minikube]
helm_release.csi-driver-nfs[0]: Refreshing state... [id=csi-driver-nfs]
helm_release.metallb[0]: Refreshing state... [id=metallb-system]
helm_release.wordpress[0]: Refreshing state... [id=wordpress]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # helm_release.csi-driver-nfs[0] will be destroyed
  - resource "helm_release" "csi-driver-nfs" {
      - atomic                     = false -> null
      - chart                      = "csi-driver-nfs" -> null
      - cleanup_on_fail            = false -> null
      - create_namespace           = true -> null
      - dependency_update          = false -> null
      - disable_crd_hooks          = false -> null
      - disable_openapi_validation = false -> null
      - disable_webhooks           = false -> null
      - force_update               = false -> null
      - id                         = "csi-driver-nfs" -> null
      - lint                       = false -> null
      - max_history                = 0 -> null
      - metadata                   = [
          - {
              - app_version = "v4.6.0"
              - chart       = "csi-driver-nfs"
              - name        = "csi-driver-nfs"
              - namespace   = "csi-driver-nfs"
              - revision    = 1
              - values      = jsonencode({})
              - version     = "v4.6.0"
            },
        ] -> null

.
.
Plan: 0 to add, 0 to change, 6 to destroy.

Changes to Outputs:
  - minikube_domain = "cluster.local" -> null
  - minikube_ip     = "https://192.168.49.2:8443" -> null
  - minikube_name   = "minikube" -> null
  - wp-password     = "JRi33652wGWDbiYj" -> null
helm_release.metallb[0]: Destroying... [id=metallb-system]
helm_release.wordpress[0]: Destroying... [id=wordpress]
helm_release.metallb[0]: Destruction complete after 0s
helm_release.wordpress[0]: Destruction complete after 2s
random_string.wp-password: Destroying... [id=JRi33652wGWDbiYj]
helm_release.csi-driver-nfs[0]: Destroying... [id=csi-driver-nfs]
random_string.wp-password: Destruction complete after 0s
helm_release.csi-driver-nfs[0]: Destruction complete after 0s
local_file.sc-nfs: Destroying... [id=453b196645508304236c4e213cffb17540f9409d]
local_file.sc-nfs: Destruction complete after 0s
module.minikube_cluster.minikube_cluster.docker: Destroying... [id=minikube]
module.minikube_cluster.minikube_cluster.docker: Destruction complete after 8s

Destroy complete! Resources: 6 destroyed.
task: [cleanup] find . -name '*terraform*' -print | xargs rm -Rf

```

Typing `task` will show up the available options
