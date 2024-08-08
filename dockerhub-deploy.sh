#!/bin/bash

# Variables
IMAGE_NAME="your-image-name"    # Replace with your image name
DOCKERHUB_USERNAME="your-username" # Replace with your Docker Hub username
DOCKERHUB_REPO="your-repo-name"   # Replace with your Docker Hub repository name
TAG="latest"                     # Replace with your desired tag, e.g., "v1.0.0"

# Full image name with tag
IMAGE_TAG="$DOCKERHUB_USERNAME/$DOCKERHUB_REPO:$TAG"

# Step 1: Build the Docker image
echo "Building Docker image: $IMAGE_TAG"
docker build -t $IMAGE_TAG .

# Step 2: Log in to Docker Hub
echo "Logging in to Docker Hub"
docker login --username $DOCKERHUB_USERNAME

# Step 4: Push the Docker image to Docker Hub
echo "Pushing Docker image to Docker Hub: $IMAGE_TAG"
docker push $IMAGE_TAG

# Confirmation message
echo "Docker image pushed to Docker Hub successfully: $IMAGE_TAG"
