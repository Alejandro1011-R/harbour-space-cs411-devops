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