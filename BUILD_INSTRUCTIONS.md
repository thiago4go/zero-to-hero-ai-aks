# Docker Build Instructions

Since Docker daemon is not available in this environment, you'll need to build and push images from your local machine or CI/CD pipeline.

## Prerequisites

1. Docker installed and running
2. Logged into Docker Hub:
   ```bash
   docker login docker.io
   # Username: thiago4go
   ```

## Build and Push All Images

From your local machine:

```bash
cd /path/to/zero-to-hero-ai-aks-q
./scripts/build-and-push.sh
```

This will build and push:
- docker.io/thiago4go/products:latest
- docker.io/thiago4go/cart:latest
- docker.io/thiago4go/orders:latest
- docker.io/thiago4go/users:latest
- docker.io/thiago4go/frontend-host:latest

## Build Individual Service

```bash
cd dapr-store

# Products service (with AI enhancements)
docker build -f build/service.Dockerfile \
  --build-arg service_name=products \
  -t docker.io/thiago4go/products:latest .
docker push docker.io/thiago4go/products:latest

# Other services follow same pattern
```

## Next Steps After Building

Once images are pushed to Docker Hub:

1. Update Helm deployment:
   ```bash
   cd dapr-store
   helm upgrade daprstore deploy/helm/daprstore \
     --set image.registry=docker.io \
     --set image.repo=thiago4go \
     --set image.tag=latest
   ```

2. Verify pods are using new images:
   ```bash
   kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
   ```

## GitHub Repositories

- Main: https://github.com/thiago4go/zero-to-hero-ai-aks
- Dapr Store Fork: https://github.com/thiago4go/dapr-store
