For the Multi-stage build, I used a two-stage process: the first stage compiles the binary with `golang:1.24`, and the second stage uses `alpine:latest` to keep the final image size under 50MB while maintaining the necessary compatibility to run health checks.

For the HEALTHCHECK, I configured a check using `wget` every 10 seconds. This allows an orchestrator like Kubernetes to automatically detect failures, remove the container from traffic, and restart it to restore service.


### Kubernetes

Liveness and Readiness Probes
I added livenessProbe.httpGet and readinessProbe.httpGet to the Pod spec on port 4444. They are not redundant because they control different things. The readiness probe controls traffic routing; if it fails, Kubernetes stops sending HTTP requests to that specific pod until it recovers. The liveness probe controls the execution state; if it fails, Kubernetes assumes the application is dead and physically restarts the container.

Resource Requests and Limits
I set memory requests to 64Mi and limits to 128Mi. If you set neither on a real cluster, the Scheduler has no idea how heavy your app is and might place it on a node that is already at 100% capacity, causing system-wide crashes. If you only set limits without requests, the Scheduler assumes your app needs 0 memory to start, assigns it anywhere blindly, and then K8s will suddenly kill your pod (OOMKilled) the moment it actually needs some memory to work.

Service Implementation
I added a ClusterIP Service that selects the myapp pod and targets port 4444. Pod IPs are a terrible target for clients because pods are ephemeral; if a pod crashes and is recreated, it gets a completely new, unpredictable IP address, breaking all client connections. The Service buys us a stable, permanent internal IP and DNS name that routes traffic to the correct pod regardless of how many times the pod dies and comes back.