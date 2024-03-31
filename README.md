# Usage

## Pre-requisiteS

Before you dive in, make sure the following tools are set up and ready to go: minikube needs to spin up clusters smoothly, and docker must handle container creation without a hitch. This automated setup relies on them playing their parts flawlessly.

- `pkgx` 
  - Follow the [installation](https://pkgx.sh/) instruction
   - Once you have the `pkgx` utility installed, you can install the other required files with:
    ```
    pkgx install minikube task terraform kubectl jq k6 git
    ```
   If you see an installation path error i.e.  `$HOME/.local/bin is not in PATH`, you can either:

   add the PATH temporarily
   ```
   export PATH="$HOME/.local/bin:$PATH"
   ```
   Or add it permanently
   ```
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```
   and try the `pkgx install` again.

- `Docker Engine` 
    - Follow the [installation](https://docs.docker.com/engine/install/) instruction. Make sure the Docker daemon is also available to the user running the commands `without` needing to sudo.

## Steps Summary

- Bring up the cluster
- Install the LocalAI helm chart
    - The pod may start quickly but it will download a large model file on start, multiple Gigabytes in size so this can take sometime depending on your internet connection. Watch the pod's log for status, it is ready to accept queries when you see this:
    ```
    # 11:33AM INF core/startup process completed!
    # ┌───────────────────────────────────────────────────┐
    # │                   Fiber v2.50.0                   │
    # │               http://127.0.0.1:8080               │
    # │       (bound on host 0.0.0.0 and port 8080)       │
    # │                                                   │
    # │ Handlers ........... 117  Processes ........... 1 │
    # │ Prefork ....... Disabled  PID ................. 22│
    # └───────────────────────────────────────────────────┘
    ```

- Install the K8SGPT Operator helm chart
- Apply a CRD configure what LLM model to use, the name and location of the backend serving the model (refer to `helm_values/k8sgpt-localai.yaml`)
- Create a `bad` deployment to demonstrate that `k8sgpt` can analyze and troubleshoot
- Watch as the CPU spike while `k8sgpt` analyze the Kubernetes cluster for any issue. After a while, the result will be accessible in a result resource that can be viewed just like a normal resource i.e.
    - To check if there's a result available:
        - `kubectl get result -n k8sgpt`
    - To view the result analysis:
        - `kubectl describe result -n k8sgpt $(kubectl get result -n k8sgpt -o jsonpath='{.items[0].metadata.name}')`


## Available Tasks
Typing `task` will show up the available options

```
❯ task
task: [default] task --list-all
task: Available tasks for this project:
* clean-bad-app:             Clean up the bad deployment
* cleanup:                   Destroy and clean up the cluster
* config-llm-backend:        Configure LLM backend model
* default:                   Show this task list
* deploy-bad-app:            Create a bad pod
* display-diagnostics:       Display troubleshooting analysis
* query-diagnostics:         Analyze the cluster for issue
* up:                        Bring up the cluster
```

## Task UP!
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
.

Terraform has been successfully initialized!
.
.
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

minikube_domain = "cluster.local"
minikube_ip = "https://192.168.49.2:8443"
minikube_name = "minikube"
```

## Deploy the Test App

Deploy a pod that uses a non-existing image. This will keep on retrying with `ImagePullBackoff` status, which should be pick up by k8sgpt analysis

```
task test-bad-app
```

Example:
```
❯ task test-bad-app
task: [test-bad-app] kubectl create deploy bad-app --image=not-exist
deployment.apps/bad-app created
```

## Check for New Analysis
The k8sgpt operator will create a `result` resource if there's a new analysis available:
```
❯ task query-diagnostics
task: [query-diagnostics] kubectl get result -n k8sgpt
NAME                           KIND   BACKEND
defaultbadapp7d56b4fc5djrmtx   Pod    localai
```

## Show K8SGPT Troubleshooting Result

```
task display-diagnostics
```

Example:
```
❯ task display-diagnostics
task: [display-diagnostics] kubectl describe result -n k8sgpt $(kubectl get result -n k8sgpt -o jsonpath='{.items[0].metadata.name}')
Name:         defaultbadapp7d56b4fc5djrmtx
Namespace:    k8sgpt
Labels:       k8sgpts.k8sgpt.ai/backend=localai
              k8sgpts.k8sgpt.ai/name=k8sgpt-localai
              k8sgpts.k8sgpt.ai/namespace=k8sgpt
Annotations:  <none>
API Version:  core.k8sgpt.ai/v1alpha1
Kind:         Result
Metadata:
  Creation Timestamp:  2024-03-30T11:56:11Z
  Generation:          1
  Resource Version:    2998
  UID:                 efa594ff-69e7-4f90-a128-b391a59ba728
Spec:
  Backend:  localai
  Details:  Error: Back-off pulling image "not-exist"
Solution:
1. Check if the image name is spelled correctly.
2. Verify the image name is available for download by using the following command:
  `docker search not-exist`
3. If the image is available, try pulling the image using the following command:
  `docker pull not-exist`
4. If the image is not found, try using a different image name or refer to the Docker Hub documentation for more information on pulling images.
```



## Task Cleanup!
To destroy and clean up the cluster:
```
task cleanup
```

Example:

```
❯ task cleanup
task: [destroy] terraform destroy $TF_AUTO
module.minikube_cluster.minikube_cluster.docker: Refreshing state... [id=minikube]
helm_release.local-ai[0]: Refreshing state... [id=local-ai]
helm_release.k8sgpt[0]: Refreshing state... [id=k8sgpt]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # helm_release.k8sgpt[0] will be destroyed
  - resource "helm_release" "k8sgpt" {
      - atomic                     = false -> null
      - chart                      = "k8sgpt-operator" -> null
      - cleanup_on_fail            = false -> null
      - create_namespace           = true -> null

.
.
Plan: 0 to add, 0 to change, 3 to destroy.

Changes to Outputs:
  - minikube_domain = "cluster.local" -> null
  - minikube_ip     = "https://192.168.49.2:8443" -> null
  - minikube_name   = "minikube" -> null

Destroy complete! Resources: 3 destroyed.
task: [cleanup] find . -name '*terraform*' -print | xargs rm -Rf

```