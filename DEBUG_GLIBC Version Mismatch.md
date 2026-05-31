# Debug Task — GLIBC Version Mismatch

## Scenario
A Go binary (`./main`) compiled on the playground's Jenkins machine runs perfectly there, but fails on a fresh Ubuntu 18.04 VM at a customer site with:
```
./main: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.34' not found (required by ./main)
```

## Two Ranked Hypotheses

### Hypothesis 1 (Higher Likelihood)
**The binary was compiled with dynamic linking against the build machine's newer GLIBC (2.34+), but Ubuntu 18.04 ships with GLIBC 2.27.**

*Why plausible:* Ubuntu 18.04 (released April 2018) includes GLIBC 2.27, while GLIBC 2.34 was released in August 2021. If the Jenkins machine runs a newer distribution (Ubuntu 22.04+ or similar), the Go binary dynamically linked against system libraries requiring a newer GLIBC version than what's available on the customer's older OS.

### Hypothesis 2 (Lower Likelihood)
**The binary was compiled with CGO_ENABLED=1, introducing C dependencies that require a newer GLIBC version.**

*Why plausible:* By default, Go builds are statically linked and don't depend on system libraries. However, if CGO is enabled (either explicitly or implicitly through certain packages like `net` with DNS resolution), the binary can link against system C libraries, creating a GLIBC dependency that may not be satisfied on older systems.

## Verification Steps

### For Hypothesis 1:
Run on the customer's VM (or a Ubuntu 18.04 container):
```bash
ldd ./main | grep libc
```
This will show if the binary has a dynamic dependency on libc and which version it expects. Compare this against:
```bash
ldd --version
```
to see the installed GLIBC version on the customer's system (should be 2.27 on Ubuntu 18.04).

### For Hypothesis 2:
On the Jenkins build machine, check how the binary was built:
```bash
go version -m ./main | grep CGO_ENABLED
```
If it shows `CGO_ENABLED=1`, or run:
```bash
file ./main
```
If it shows "dynamically linked" instead of "statically linked", CGO was enabled during compilation.

## Fix

Rebuild the binary with static linking and CGO disabled to eliminate GLIBC dependencies:

```bash
CGO_ENABLED=0 go build -o main main.go
```

This forces Go to use its pure-Go implementations of all packages (including DNS resolution) and produces a fully static binary with no external dependencies.

## Underlying Lesson

**When deploying a Go binary to a different machine, ensure it's compiled as a fully static binary (CGO_ENABLED=0) to avoid system library dependencies.** Unlike dynamic binaries that rely on the host's specific GLIBC or other system library versions, a static Go binary is self-contained and portable across any Linux distribution, regardless of age or library versions. This is one of Go's key deployment advantages — true "compile once, run anywhere" on the same architecture.
