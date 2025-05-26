#!/bin/bash

SERVICE_NAME=$1
RELEASE_VERSION=$2
USER_NAME=$3
EMAIL=$4

# Configure git
git config user.name "$USER_NAME"
git config user.email "$EMAIL"
git fetch --all && git checkout main

# Install dependencies for both Golang and Python
sudo apt-get update
sudo apt-get install -y protobuf-compiler golang-goprotobuf-dev python3.11 python3.11-pip python3.11-venv

# Install Go protoc plugins
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Install Python protoc plugins
python3.11 -m pip install --upgrade pip
python3.11 -m pip install grpcio-tools

# Clean up existing directories
rm -rf ./golang/${SERVICE_NAME}
rm -rf ./python/${SERVICE_NAME}

# Create output directories
mkdir -p ./golang/${SERVICE_NAME}
mkdir -p ./python/${SERVICE_NAME}

# Generate Golang stubs
protoc --go_out=./golang --go_opt=paths=source_relative \
  --go-grpc_out=./golang --go-grpc_opt=paths=source_relative \
  ./${SERVICE_NAME}/*.proto

# Generate Python stubs
protoc --python_out=./python \
  --grpc_python_out=./python \
  ./${SERVICE_NAME}/*.proto

# Setup Golang module
cd golang/${SERVICE_NAME}
go mod init \
  github.com/longlnOff/usages-proto/golang/${SERVICE_NAME} || true
go mod tidy
cd ../../

# Setup Python package
cd python/${SERVICE_NAME}
# Create __init__.py files to make it a proper Python package
touch __init__.py
# Create setup.py for the Python package
cat > setup.py << EOF
from setuptools import setup, find_packages

setup(
    name="${SERVICE_NAME}-proto",
    version="${RELEASE_VERSION}",
    packages=find_packages(),
    install_requires=[
        "grpcio>=1.50.0",
        "protobuf>=4.21.0",
    ],
    python_requires=">=3.11",
)
EOF
cd ../../

# Commit and push changes
git add . && git commit -am "proto update for golang and python" || true
git push origin HEAD:main

# Create tags for both languages
git tag -fa golang/${SERVICE_NAME}/${RELEASE_VERSION} \
  -m "golang/${SERVICE_NAME}/${RELEASE_VERSION}" 
git push origin refs/tags/golang/${SERVICE_NAME}/${RELEASE_VERSION}

git tag -fa python/${SERVICE_NAME}/${RELEASE_VERSION} \
  -m "python/${SERVICE_NAME}/${RELEASE_VERSION}" 
git push origin refs/tags/python/${SERVICE_NAME}/${RELEASE_VERSION}
