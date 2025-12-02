# DFTracer Docker Development Environment

This directory contains Docker configurations for building and running DFTracer in a containerized development environment.

## Files

- **Dockerfile.dev**: Multi-platform development Dockerfile with all DFTracer dependencies
- **Dockerfile.prod**: Production Dockerfile with DFTracer pre-installed (used for Docker Hub releases)
- **build-multiplatform.sh**: Script for building and running Docker containers for multiple architectures
- **README.md**: This file

## Using Pre-built Images from Docker Hub

The easiest way to get started is to use pre-built images from Docker Hub:

```bash
# Pull the latest release
docker pull dftracer/dftracer:latest

# Pull a specific version
docker pull dftracer/dftracer:1.0.0

# Run the image with your workspace mounted
docker run -it --rm -v "$PWD:/workspace/myproject" dftracer/dftracer:latest

# Inside the container, the virtual environment is already activated
# DFTracer is pre-installed and ready to use
dftracer --help
```

The pre-built images include:
- Python 3.10 with virtual environment activated
- DFTracer with all dependencies pre-installed
- hwloc and MPICH for parallel computing
- All development tools (gdb, vim, etc.)

## Building from Source

### Build and Run (Easiest Way)

```bash
# Build for current platform and run
./infrastructure/docker/build-multiplatform.sh build --load
./infrastructure/docker/build-multiplatform.sh run

# Or use the shorthand (auto-detects your platform)
./infrastructure/docker/build-multiplatform.sh run
```

### Build for Current Platform

```bash
# From the project root
./infrastructure/docker/build-multiplatform.sh build --load
```

### Build for Multiple Platforms

```bash
# Build for both amd64 and arm64
./infrastructure/docker/build-multiplatform.sh build --arch linux/amd64,linux/arm64
```

### Run the Development Container

```bash
# Simple run (auto-detects platform, mounts workspace)
./infrastructure/docker/build-multiplatform.sh run

# Run with custom command
./infrastructure/docker/build-multiplatform.sh run --cmd "pip install -e . && pytest"

# Run with environment variables
./infrastructure/docker/build-multiplatform.sh run \
    -e DFTRACER_ENABLE=1 \
    -e DFTRACER_LOG_FILE=/tmp/trace.log

# Run in background
./infrastructure/docker/build-multiplatform.sh run --detach

# Run without mounting workspace
./infrastructure/docker/build-multiplatform.sh run --no-mount
```

## Build Script Commands and Options

The `build-multiplatform.sh` script supports two main commands:

### Build Command

```bash
./build-multiplatform.sh build [OPTIONS]

OPTIONS:
    -n, --name NAME         Image name (default: dftracer-dev)
    -t, --tag TAG           Image tag (default: latest)
    -p, --python VERSION    Python version (default: 3.10)
    -a, --arch PLATFORMS    Comma-separated platforms (default: linux/amd64,linux/arm64)
    -r, --registry REGISTRY Docker registry (default: none)
    --push                  Push image to registry after build
    --load                  Load image to local Docker (single platform only)
    --no-cache              Build without using cache
```

### Run Command

```bash
./build-multiplatform.sh run [OPTIONS]

OPTIONS:
    -n, --name NAME         Image name (default: dftracer-dev)
    -t, --tag TAG           Image tag (default: latest)
    -r, --registry REGISTRY Docker registry (default: none)
    -c, --cmd COMMAND       Command to run in container (default: /bin/bash)
    -e, --env KEY=VALUE     Set environment variable (can be used multiple times)
    -v, --volume SRC:DST    Mount volume (can be used multiple times)
    --no-mount              Don't mount current directory
    --privileged            Run with privileged mode
    --detach                Run container in background
```

**Note:** The run command automatically detects your host platform (amd64 or arm64) and selects the appropriate image.

### Examples

**Build for current platform and run:**
```bash
./infrastructure/docker/build-multiplatform.sh build --load
./infrastructure/docker/build-multiplatform.sh run
```

**Build with Python 3.11:**
```bash
./infrastructure/docker/build-multiplatform.sh build --python 3.11 --tag py311 --load
./infrastructure/docker/build-multiplatform.sh run --tag py311
```

**Build and push to Docker Hub:**
```bash
./infrastructure/docker/build-multiplatform.sh build \
    --name myuser/dftracer-dev \
    --tag latest \
    --arch linux/amd64,linux/arm64 \
    --push
```

**Run with custom environment and volumes:**
```bash
./infrastructure/docker/build-multiplatform.sh run \
    -e DFTRACER_ENABLE=1 \
    -e DFTRACER_DATA_DIR=/data \
    -v /host/data:/data \
    --cmd "python my_script.py"
```

**Build without cache:**
```bash
./infrastructure/docker/build-multiplatform.sh build --no-cache --load
```

## Using with VS Code Dev Containers

This project includes a devcontainer configuration for use with VS Code.

### Setup

1. Open the project in VS Code
2. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
3. Select "Dev Containers: Reopen in Container"
4. Wait for the container to build and start

See `.devcontainer/README.md` for more details.

### Dev Container Features

The dev container includes:
- Python development tools (Pylance, pytest)
- C/C++ development tools (CMake, cpptools)
- Git integration with GitLens
- Docker support
- Pre-configured settings for Python and C++

## Dockerfile Details

The `Dockerfile.dev` includes:

### System Dependencies
- Build tools (gcc, g++, make, cmake, ninja)
- Git for version control
- Development utilities (gdb, vim, htop)
- YAML-CPP library

### Python Environment
- Python 3.10 (configurable via build arg)
- All DFTracer build dependencies
- All DFTracer runtime dependencies
- Optional dfanalyzer dependencies

### C++ Dependencies
- cpp-logger
- gotcha
- brahma
- yaml-cpp

### Non-root User
The container creates a `developer` user (UID 1000) for running without root privileges.

## Development Workflow

### 1. Start the Container

```bash
# Using the build script (recommended)
./infrastructure/docker/build-multiplatform.sh run

# Or using docker directly
docker run -it --rm -v $(pwd):/workspace/dftracer dftracer-dev:latest
```

### 2. Build DFTracer

```bash
# Install in editable mode
pip install -e .[test,dfanalyzer]

# Or use CMake directly
mkdir build && cd build
cmake ..
make -j$(nproc)
```

### 3. Run Tests

```bash
# Python tests
pytest test/

# C++ tests (after CMake build)
cd build
ctest
```

### 4. Development Iterations

Since the workspace is mounted, changes made on your host are immediately visible in the container.

## Multi-Platform Support

The Dockerfile uses multi-stage builds and is compatible with:
- **linux/amd64**: Intel/AMD 64-bit processors
- **linux/arm64**: ARM 64-bit processors (Apple Silicon, AWS Graviton, etc.)

### Building for Multiple Architectures

Docker Buildx is used for multi-platform builds:

```bash
# Create a new builder (first time only)
docker buildx create --name dftracer-builder --use --bootstrap

# Build for multiple platforms
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t dftracer-dev:latest \
    -f infrastructure/docker/Dockerfile.dev \
    .
```

## Publishing to Docker Hub (Maintainers Only)

Docker images are automatically built and pushed to Docker Hub when a version tag is created:

```bash
# Tag a new release
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions will automatically:
# 1. Build multi-platform images (linux/amd64, linux/arm64)
# 2. Push to Docker Hub as dftracer/dftracer:1.0.0 and dftracer/dftracer:latest
```

### Manual Docker Hub Push

To manually build and push to Docker Hub:

```bash
# Login to Docker Hub
docker login

# Build and push production image
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --build-arg DFTRACER_VERSION=1.0.0 \
    -t dftracer/dftracer:1.0.0 \
    -t dftracer/dftracer:latest \
    -f infrastructure/docker/Dockerfile.prod \
    --push \
    .
```

### Required GitHub Secrets

For automated publishing, the following secrets must be configured in the GitHub repository:
- `DOCKER_USERNAME`: Docker Hub username
- `DOCKER_PASSWORD`: Docker Hub password or access token

## Troubleshooting

### Docker Buildx Not Available

If you get an error about buildx not being available:

```bash
# Install buildx (if using standalone Docker)
docker buildx install

# Or install Docker Desktop which includes buildx
```

### Permission Issues

If you encounter permission issues with mounted volumes:

```bash
# Build with your user ID
./infrastructure/docker/build-multiplatform.sh \
    --arch linux/amd64 \
    --load

# Run with user mapping
docker run -it --rm \
    -v $(pwd):/workspace/dftracer \
    -u $(id -u):$(id -g) \
    dftracer-dev:latest
```

### Build Failures

If the build fails:

1. Check that all dependencies in `dependency/cpp.requirements.txt` are accessible
2. Try building with `--no-cache` flag
3. Check Docker daemon logs: `docker logs`

## Environment Variables

The following environment variables can be set when running the container:

- `DFTRACER_ENABLE`: Enable/disable DFTracer (default: 0 in dev container)
- `DFTRACER_LOG_FILE`: Path to DFTracer log file
- `DFTRACER_DATA_DIR`: Colon-separated paths to trace
- `PYTHONPATH`: Python module search path

Example:
```bash
docker run -it --rm \
    -v $(pwd):/workspace/dftracer \
    -e DFTRACER_ENABLE=1 \
    -e DFTRACER_LOG_FILE=/tmp/trace.log \
    -e DFTRACER_DATA_DIR=/workspace/dftracer/data \
    dftracer-dev:latest
```

## Cleaning Up

Remove unused Docker resources:

```bash
# Remove dangling images
docker image prune

# Remove all unused images
docker image prune -a

# Remove build cache
docker builder prune
```

## Contributing

When updating the Dockerfile:

1. Test builds for both amd64 and arm64
2. Keep image size minimal (use multi-stage builds, clean up apt cache)
3. Document any new dependencies or build arguments
4. Update this README with any new features or requirements
