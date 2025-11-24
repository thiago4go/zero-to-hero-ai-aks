# Repository Configuration

## Git Repositories

### Main Repository
- **URL**: git@github.com:thiago4go/zero-to-hero-ai-aks.git
- **Purpose**: Main lab project with infrastructure, specs, and documentation

### Dapr Store Fork
- **URL**: git@github.com:thiago4go/dapr-store.git
- **Location**: `/home/thiago/azure/zero-to-hero-ai-aks-q/dapr-store`
- **Upstream**: git@github.com:Azure-Samples/dapr-store.git
- **Purpose**: Forked microservices application with AI enhancements

## Docker Hub

### Registry Configuration
- **Registry**: docker.io
- **Username**: thiago4go
- **Image Prefix**: thiago4go/

### Images
All Docker images are built and pushed to Docker Hub under the `thiago4go` namespace:

- `docker.io/thiago4go/products:latest` - Products service with AI descriptions
- `docker.io/thiago4go/cart:latest` - Shopping cart service
- `docker.io/thiago4go/orders:latest` - Orders service
- `docker.io/thiago4go/users:latest` - Users service
- `docker.io/thiago4go/frontend-host:latest` - Frontend application

### Building and Pushing Images

```bash
# Build and push all images with default 'latest' tag
./scripts/build-and-push.sh

# Build and push with custom tag
./scripts/build-and-push.sh v1.0.0
```

### Docker Login

Before pushing images, ensure you're logged in to Docker Hub:

```bash
docker login docker.io
# Enter username: thiago4go
# Enter password: <your-docker-hub-token>
```

## Configuration Files

- `.dockerhub` - Docker Hub registry configuration
- `.env` - Environment variables including Docker Hub username
- `AGENTS.md` - Development guidelines with repository information
- `scripts/build-and-push.sh` - Automated build and push script

## Important Notes

1. **Always use `thiago4go` namespace** for Docker images
2. **Dapr store is a fork** - maintain sync with upstream when needed
3. **Image tags** should follow semantic versioning for releases
4. **Latest tag** is used for development builds
