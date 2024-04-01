# Description

Demo using K8SGPT to triage and diagnose issue in a Kubernetes Cluster. It can use different backends and LLM models to do its job from ChatGPT, Google Gemini Pro, HuggingFace, LocalAI, etc. Some of the backends requires a pro subscription once you reach certain API thresholds, apart from you are sending data to a third party for analysis. In this example, we use  LocalAI with Meta Llama 2 model which is downloaded upon startup so all the analysis are done locally within the cluster, no data is transmitted.

**K8sGPT is**:
> ...a tool for scanning your kubernetes clusters, diagnosing and triaging issues in simple english. It has SRE experience codified into it’s analyzers and helps to pull out the most relevant information to enrich it with AI.
</quote>

**LocalAI is**:

> LocalAI is the free, Open Source OpenAI alternative. LocalAI act as a drop-in replacement REST API that’s compatible with OpenAI (Elevenlabs, Anthropic... ) API specifications for local AI inferencing. It allows you to run LLMs, generate images, audio (and not only) locally or on-prem with consumer grade hardware, supporting multiple model families. Does not require GPU.


## Pre-requisites

Before you dive in, make sure the following tools are set up and ready to go: minikube needs to spin up clusters smoothly, and docker must handle container creation without a hitch. This automated setup relies on them playing their parts flawlessly.

- `pkgx` - a blazingly fast, standalone, cross‐platform binary that runs anything. (Or you can use any tools you may have to install the following):
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
- Once the issue is fixed, the problem with the `bad` deployment is corrected, it will also remove the operator `result` resource in the k8sgpt namespace. What this means is that, the `result` resource will only be present and created if there's a new issue or diagnostic available.
    ```
    $ kubectl get result -n k8sgpt
    No resources found in k8sgpt namespace.
    ```
     With this in mind, for **production** use, you can potentially monitor this in Prometheus/Grafana and create an alert once the presence of the `result` is detected.


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
❯ task deploy-bad-app

task: [deploy-bad-app] kubectl create deploy bad-app --image=not-exist
deployment.apps/bad-app created

task: [deploy-bad-app] sleep 5s

task: [deploy-bad-app] kubectl get pods
NAME                       READY   STATUS         RESTARTS   AGE
bad-app-7d56b4fc5d-rx2f2   0/1     ErrImagePull   0          5s
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

## Clean up Test App

Try to remove the bad app, the operator will also detect that the issue is longer present and remove the diagnostic `result` too.

```
task clean-bad-app
```

Example:
```
❯ task clean-bad-app
task: [clean-bad-app] kubectl delete deploy bad-app

deployment.apps "bad-app" deleted

task: [clean-bad-app] kubectl get pods
NAME                       READY   STATUS        RESTARTS   AGE
bad-app-7d56b4fc5d-rx2f2   0/1     Terminating   0          119s
```

After a while (usually just few seconds), if you check diagnostic again, there should be nothing available as the issue has been cleared.

```
task query-diagnostics
```

Example:
```
❯ task query-diagnostics
task: [query-diagnostics] kubectl get result -n k8sgpt
No resources found in k8sgpt namespace.
```

You can play around and deploy the `bad` again with `task test-bad-app`, the operator should catch up the issue and provide a diagnostic accordingly.


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
  }

Plan: 0 to add, 0 to change, 3 to destroy.

Changes to Outputs:
  - minikube_domain = "cluster.local" -> null
  - minikube_ip     = "https://192.168.49.2:8443" -> null
  - minikube_name   = "minikube" -> null

Destroy complete! Resources: 3 destroyed.
task: [cleanup] find . -name '*terraform*' -print | xargs rm -Rf

```