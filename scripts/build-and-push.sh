#!/bin/bash
set -e

# Docker Hub Configuration
DOCKER_USERNAME="thiago4go"
IMAGE_TAG="${1:-latest}"

echo "Building and pushing Docker images to docker.io/$DOCKER_USERNAME"
echo "Image tag: $IMAGE_TAG"

cd "$(dirname "$0")/../dapr-store"

# Build and push products service
echo "Building products service..."
docker build -f build/service.Dockerfile \
  --build-arg service_name=products \
  -t docker.io/$DOCKER_USERNAME/products:$IMAGE_TAG .

echo "Pushing products service..."
docker push docker.io/$DOCKER_USERNAME/products:$IMAGE_TAG

# Build and push cart service
echo "Building cart service..."
docker build -f build/service.Dockerfile \
  --build-arg service_name=cart \
  -t docker.io/$DOCKER_USERNAME/cart:$IMAGE_TAG .

echo "Pushing cart service..."
docker push docker.io/$DOCKER_USERNAME/cart:$IMAGE_TAG

# Build and push orders service
echo "Building orders service..."
docker build -f build/service.Dockerfile \
  --build-arg service_name=orders \
  -t docker.io/$DOCKER_USERNAME/orders:$IMAGE_TAG .

echo "Pushing orders service..."
docker push docker.io/$DOCKER_USERNAME/orders:$IMAGE_TAG

# Build and push users service
echo "Building users service..."
docker build -f build/service.Dockerfile \
  --build-arg service_name=users \
  -t docker.io/$DOCKER_USERNAME/users:$IMAGE_TAG .

echo "Pushing users service..."
docker push docker.io/$DOCKER_USERNAME/users:$IMAGE_TAG

# Build and push frontend
echo "Building frontend..."
docker build -f build/frontend.Dockerfile \
  -t docker.io/$DOCKER_USERNAME/frontend-host:$IMAGE_TAG .

echo "Pushing frontend..."
docker push docker.io/$DOCKER_USERNAME/frontend-host:$IMAGE_TAG

echo "✅ All images built and pushed successfully!"
echo ""
echo "Images:"
echo "  - docker.io/$DOCKER_USERNAME/products:$IMAGE_TAG"
echo "  - docker.io/$DOCKER_USERNAME/cart:$IMAGE_TAG"
echo "  - docker.io/$DOCKER_USERNAME/orders:$IMAGE_TAG"
echo "  - docker.io/$DOCKER_USERNAME/users:$IMAGE_TAG"
echo "  - docker.io/$DOCKER_USERNAME/frontend-host:$IMAGE_TAG"
