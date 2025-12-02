# DFTracer Dev Container Configuration

This directory contains the VS Code Dev Container configuration for DFTracer development.

## Active Configuration

**`devcontainer.json`** - The primary dev container configuration that uses the Dockerfile-based setup from `infrastructure/docker/Dockerfile.dev`.

This configuration:
- Uses the multi-platform Dockerfile for consistent development environment
- Includes all necessary DFTracer dependencies
- Configures VS Code with recommended extensions and settings
- Sets up a non-root user for safer development
- Automatically installs DFTracer in editable mode on container creation

## Usage

### Open in Dev Container

1. Open this project in VS Code
2. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
3. Select "Dev Containers: Reopen in Container"
4. Wait for the container to build and start

### First Time Setup

The container will automatically:
- Build the development Docker image
- Install DFTracer with test and analyzer dependencies
- Configure git safe directory

### Working in the Container

Once inside the container:
```bash
# Build DFTracer with CMake
mkdir build && cd build
cmake ..
make -j$(nproc)

# Run Python tests
pytest test/

# Run C++ tests
cd build && ctest
```

## Legacy Files

The following files are kept for reference but are no longer actively used:

- **`docker-compose.yml`** - Legacy Docker Compose configuration (now uses Dockerfile directly)
- **`devcontainer-dockerfile.json`** - Duplicate configuration (consolidated into devcontainer.json)

You can safely delete these files if you don't need them for backward compatibility.

## Customization

### Change Python Version

Edit `devcontainer.json` and modify the `PYTHON_VERSION` build arg:

```json
"build": {
    "args": {
        "PYTHON_VERSION": "3.11"
    }
}
```

### Add VS Code Extensions

Add extension IDs to the `extensions` array in `customizations.vscode`:

```json
"extensions": [
    "ms-python.python",
    "your-extension-id"
]
```

### Set Environment Variables

Add variables to the `remoteEnv` section:

```json
"remoteEnv": {
    "DFTRACER_ENABLE": "1",
    "CUSTOM_VAR": "value"
}
```

## Troubleshooting

### Container Build Fails

If the container fails to build:
1. Check that Docker is running
2. Try rebuilding without cache: "Dev Containers: Rebuild Without Cache"
3. Check the build logs in the VS Code terminal

### Permission Issues

If you encounter permission issues with mounted files:
- The container uses UID 1000 by default
- You can modify `USER_UID` and `USER_GID` in the build args to match your host user

### Can't Access Files

Make sure the workspace folder is correctly mounted:
- Check `workspaceMount` in `devcontainer.json`
- Default: `source=${localWorkspaceFolder},target=/workspace/dftracer,type=bind`

## Alternative: Using the Build Script

You can also run the container manually without VS Code:

```bash
# From project root
./infrastructure/docker/build-multiplatform.sh run

# With custom options
./infrastructure/docker/build-multiplatform.sh run --cmd "bash"
```

See `infrastructure/docker/README.md` for more details.
