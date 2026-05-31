# Debug Task — Build and deploy the app as a docker image

### 1. Two ranked hypotheses
Hypothesis 1: The binary was compiled on an ARM64 host without cross-compilation flags, creating an executable incompatible with the x86_64 instruction set of the runtime host.
Hypothesis 2: The base image layer is architecturally mismatched for the target environment, causing a failure at the loader level.

### 2. Verification steps
Hypothesis 1: Run `docker run --rm ttl.sh/alejandro-ramirez:2h file /main` to inspect the binary's architecture directly within the container.
Hypothesis 2: Run `docker buildx imagetools inspect ttl.sh/alejandro-ramirez:2h` to verify the manifest platform support reported by the registry.

### 3. Your fix
Update the build step in the `Dockerfile` to force a cross-compilation target:
`RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o main main.go`

### 4. Underlying lesson
Building an image on a local host guarantees the layers are packaged correctly, but it does not guarantee that the compiled binaries inside the layers are portable across different CPU architectures.


# Kubernetes

### 1. Two ranked hypotheses
1. The ephemeral image expired on ttl.sh and was deleted from the remote registry, but Jenkins can still pull it successfully because it is serving it directly from its local Docker cache.
2. The Kubernetes worker node has a DNS or network configuration issue preventing it from reaching external internet registries like ttl.sh, whereas the Jenkins machine has unrestricted outbound access.

### 2. Verification steps
1. For the cache hypothesis: Run `docker rmi ttl.sh/alejandro-ramirez:2h` on the Jenkins machine to delete the local cache, then run `docker pull ttl.sh/alejandro-ramirez:2h` again; if it fails now, the image is definitely gone from the remote registry.
2. For the network hypothesis: Run `kubectl describe pod myapp` and check the "Events" section at the bottom; a cache/expiration issue will say "manifest unknown", while a network issue will say "failed to resolve" or "connection timeout".

### 3. Your fix
Trigger a new Jenkins build to recompile the Go binary and push a completely fresh image to ttl.sh, ensuring a live, unexpired copy is available on the remote registry.

### 4. Underlying lesson
"I can pull this image" only proves the image is accessible from your specific machine's cache or network context, whereas "the cluster can pull this image" requires the independent Kubernetes worker nodes to have direct, authenticated network access to the live remote registry.
