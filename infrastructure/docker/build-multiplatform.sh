#!/bin/bash
# Multi-platform Docker build script for DFTracer development environment
# Supports building for amd64 and arm64 architectures

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
IMAGE_NAME="${IMAGE_NAME:-dftracer/dftracer-dev}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
PYTHON_VERSION="${PYTHON_VERSION:-3.10}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
DOCKERFILE="${DOCKERFILE:-${SCRIPT_DIR}/Dockerfile.dev}"
PUSH="${PUSH:-true}"
REGISTRY="${REGISTRY:-}"
MODE="${MODE:-build}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect host platform
detect_platform() {
    local arch=$(uname -m)
    
    # Convert architecture names
    case "$arch" in
        x86_64)
            arch="amd64"
            ;;
        aarch64|arm64)
            arch="arm64"
            ;;
        *)
            echo -e "${RED}Unsupported architecture: $arch${NC}" >&2
            exit 1
            ;;
    esac
    
    # Docker containers always run Linux, even on macOS
    echo "linux/${arch}"
}

# Print usage
usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Build and run multi-platform Docker images for DFTracer development environment.

COMMANDS:
    build                   Build Docker image (default)
    run                     Run Docker container with auto-detected platform
    help                    Show this help message

BUILD OPTIONS:
    -n, --name NAME         Image name (default: dftracer-dev)
    -t, --tag TAG           Image tag (default: latest)
    -p, --python VERSION    Python version (default: 3.10)
    -a, --arch PLATFORMS    Comma-separated platforms (default: linux/amd64,linux/arm64)
                            Examples: linux/amd64, linux/arm64, linux/amd64,linux/arm64
    -r, --registry REGISTRY Docker registry (default: none)
    --push                  Push image to registry after build
    --load                  Load image to local Docker (single platform only)
    --no-cache              Build without using cache

RUN OPTIONS:
    -n, --name NAME         Image name (default: dftracer-dev)
    -t, --tag TAG           Image tag (default: latest)
    -r, --registry REGISTRY Docker registry (default: none)
    -c, --cmd COMMAND       Command to run in container (default: /bin/bash)
    -e, --env KEY=VALUE     Set environment variable (can be used multiple times)
    -v, --volume SRC:DST    Mount volume (can be used multiple times)
    --no-mount              Don't mount current directory
    --privileged            Run with privileged mode
    --detach                Run container in background

EXAMPLES:
    # Build for current platform and load locally
    $0 build --arch \$(uname -s | tr '[:upper:]' '[:lower:]')/\$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') --load
    
    # Build for multiple platforms
    $0 build --arch linux/amd64,linux/arm64
    
    # Build and push to Docker Hub
    $0 build --name myuser/dftracer-dev --push
    
    # Run container (auto-detects platform)
    $0 run
    
    # Run with custom command
    $0 run --cmd "pip install -e . && pytest"
    
    # Run with environment variables
    $0 run -e DFTRACER_ENABLE=1 -e DFTRACER_LOG_FILE=/tmp/trace.log
    
    # Run without mounting workspace
    $0 run --no-mount

EOF
}

# Run container function
run_container() {
    local cmd="/bin/bash"
    local env_vars=()
    local volumes=()
    local mount_workspace=true
    local privileged=false
    local detach=false
    
    # Parse run-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                IMAGE_NAME="$2"
                shift 2
                ;;
            -t|--tag)
                IMAGE_TAG="$2"
                shift 2
                ;;
            -r|--registry)
                REGISTRY="$2"
                shift 2
                ;;
            -c|--cmd)
                cmd="$2"
                shift 2
                ;;
            -e|--env)
                env_vars+=("-e" "$2")
                shift 2
                ;;
            -v|--volume)
                volumes+=("-v" "$2")
                shift 2
                ;;
            --no-mount)
                mount_workspace=false
                shift
                ;;
            --privileged)
                privileged=true
                shift
                ;;
            --detach)
                detach=true
                shift
                ;;
            *)
                echo -e "${RED}Unknown run option: $1${NC}"
                usage
                exit 1
                ;;
        esac
    done
    
    # Build full image name
    if [ -n "$REGISTRY" ]; then
        local full_image_name="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    else
        local full_image_name="${IMAGE_NAME}:${IMAGE_TAG}"
    fi
    
    # Detect host platform
    local host_platform=$(detect_platform)
    
    echo -e "${GREEN}=== Running DFTracer Development Container ===${NC}"
    echo "Image: ${full_image_name}"
    echo "Host Platform: ${host_platform}"
    echo "Command: ${cmd}"
    
    # Build docker run command array for proper space handling
    local run_args=("docker" "run")
    
    if [ "$detach" = true ]; then
        run_args+=("-d")
    else
        run_args+=("-it")
    fi
    
    run_args+=("--rm")
    
    if [ "$privileged" = true ]; then
        run_args+=("--privileged")
    fi
    
    # Add workspace mount if enabled
    if [ "$mount_workspace" = true ]; then
        run_args+=("-v" "${PROJECT_ROOT}:/workspace/dftracer")
    fi
    
    # Add custom volumes
    for vol in "${volumes[@]}"; do
        run_args+=("${vol}")
    done
    
    # Add environment variables
    for env in "${env_vars[@]}"; do
        run_args+=("${env}")
    done
    
    # Add platform specification
    run_args+=("--platform" "${host_platform}")
    
    # Add image
    run_args+=("${full_image_name}")
    
    # Add command (needs special handling for commands with spaces/args)
    if [ "$cmd" != "/bin/bash" ]; then
        run_args+=("bash" "-c" "${cmd}")
    else
        run_args+=("${cmd}")
    fi
    
    echo -e "${BLUE}Executing: ${run_args[*]}${NC}"
    echo ""
    
    # Execute run command
    "${run_args[@]}"
}

# Parse command
if [[ $# -eq 0 ]]; then
    MODE="build"
else
    case $1 in
        build)
            MODE="build"
            shift
            ;;
        run)
            MODE="run"
            shift
            run_container "$@"
            exit 0
            ;;
        help|-h|--help)
            usage
            exit 0
            ;;
        *)
            # If no command specified, assume build mode
            MODE="build"
            ;;
    esac
fi

# Parse build arguments
LOAD_IMAGE=false
NO_CACHE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -p|--python)
            PYTHON_VERSION="$2"
            shift 2
            ;;
        -a|--arch)
            PLATFORMS="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        --push)
            PUSH=true
            shift
            ;;
        --load)
            LOAD_IMAGE=true
            shift
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Auto-detect platform if --load is specified without explicit --arch
if [ "$LOAD_IMAGE" = true ] && [ "$PLATFORMS" = "linux/amd64,linux/arm64" ]; then
    PLATFORMS=$(detect_platform)
    echo -e "${YELLOW}Auto-detecting platform for --load: ${PLATFORMS}${NC}"
fi

# Build full image name
if [ -n "$REGISTRY" ]; then
    FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
else
    FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
fi

echo -e "${GREEN}=== DFTracer Multi-Platform Docker Build ===${NC}"
echo "Project Root: ${PROJECT_ROOT}"
echo "Dockerfile: ${DOCKERFILE}"
echo "Image Name: ${FULL_IMAGE_NAME}"
echo "Python Version: ${PYTHON_VERSION}"
echo "Platforms: ${PLATFORMS}"
echo "Push: ${PUSH}"
echo "Load: ${LOAD_IMAGE}"

# Check if Docker buildx is available
if ! docker buildx version &> /dev/null; then
    echo -e "${RED}Error: Docker buildx is not available${NC}"
    echo "Please install Docker Desktop or enable buildx"
    exit 1
fi

# Create or use buildx builder
BUILDER_NAME="dftracer-builder"
if ! docker buildx inspect ${BUILDER_NAME} &> /dev/null; then
    echo -e "${YELLOW}Creating new buildx builder: ${BUILDER_NAME}${NC}"
    docker buildx create --name ${BUILDER_NAME} --use --bootstrap
else
    echo -e "${GREEN}Using existing buildx builder: ${BUILDER_NAME}${NC}"
    docker buildx use ${BUILDER_NAME}
fi

# Build command array for proper space handling
BUILD_ARGS=(
    "docker" "buildx" "build"
    "--platform" "${PLATFORMS}"
    "--build-arg" "PYTHON_VERSION=${PYTHON_VERSION}"
    "-t" "${FULL_IMAGE_NAME}"
    "-f" "${DOCKERFILE}"
)

# Add no-cache flag if specified
if [ -n "$NO_CACHE" ]; then
    BUILD_ARGS+=("${NO_CACHE}")
fi

# Add push or load flag
if [ "$PUSH" = true ] && [ "$LOAD_IMAGE" = true ]; then
    echo -e "${RED}Error: Cannot use both --push and --load${NC}"
    exit 1
elif [ "$PUSH" = true ]; then
    BUILD_ARGS+=("--push")
elif [ "$LOAD_IMAGE" = true ]; then
    # Check if multiple platforms specified
    if [[ "$PLATFORMS" == *","* ]]; then
        echo -e "${RED}Error: --load only works with a single platform${NC}"
        echo "Please specify a single platform with --arch, e.g., --arch linux/amd64"
        exit 1
    fi
    BUILD_ARGS+=("--load")
fi

# Add project root as the last argument
BUILD_ARGS+=("${PROJECT_ROOT}")

# Execute build
echo -e "${GREEN}Building Docker image...${NC}"
echo "Command: ${BUILD_ARGS[*]}"
echo ""

if "${BUILD_ARGS[@]}"; then
    echo ""
    echo -e "${GREEN}=== Build Successful ===${NC}"
    echo "Image: ${FULL_IMAGE_NAME}"
    echo ""
    echo "To run the container:"
    if [ "$LOAD_IMAGE" = true ] || [ "$PUSH" = false ]; then
        echo "  docker run -it --rm -v \$(pwd):/workspace/dftracer ${FULL_IMAGE_NAME}"
    else
        echo "  docker pull ${FULL_IMAGE_NAME}"
        echo "  docker run -it --rm -v \$(pwd):/workspace/dftracer ${FULL_IMAGE_NAME}"
    fi
    echo ""
    echo "To build DFTracer inside the container:"
    echo "  docker run -it --rm -v \$(pwd):/workspace/dftracer ${FULL_IMAGE_NAME} bash -c 'pip install -e .'"
else
    echo -e "${RED}=== Build Failed ===${NC}"
    exit 1
fi
