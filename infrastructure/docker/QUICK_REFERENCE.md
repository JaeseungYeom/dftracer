# DFTracer Docker Quick Reference

## Common Commands

### Build
```bash
# Build for current platform
./infrastructure/docker/build-multiplatform.sh build --load

# Build for multiple platforms
./infrastructure/docker/build-multiplatform.sh build --arch linux/amd64,linux/arm64

# Build with custom Python version
./infrastructure/docker/build-multiplatform.sh build --python 3.11 --tag py311 --load
```

### Run
```bash
# Basic run (auto-detects platform)
./infrastructure/docker/build-multiplatform.sh run

# Run with custom command
./infrastructure/docker/build-multiplatform.sh run --cmd "pytest test/"

# Run with environment variables
./infrastructure/docker/build-multiplatform.sh run -e DFTRACER_ENABLE=1

# Run in background
./infrastructure/docker/build-multiplatform.sh run --detach
```

### VS Code Dev Container
```
Cmd/Ctrl+Shift+P → "Dev Containers: Reopen in Container"
```

## File Locations

| File | Purpose |
|------|---------|
| `infrastructure/docker/Dockerfile.dev` | Development Dockerfile |
| `infrastructure/docker/build-multiplatform.sh` | Build and run script |
| `infrastructure/docker/README.md` | Docker documentation |
| `.devcontainer/devcontainer.json` | VS Code dev container config |
| `.devcontainer/README.md` | Dev container documentation |

## Troubleshooting

**Build fails?**
- Try `--no-cache` flag
- Check Docker is running
- Verify buildx is available

**Permission issues?**
- Check UID/GID in build args (default: 1000)

**Wrong platform?**
- Script auto-detects, but you can override with `--arch`

## Help
```bash
./infrastructure/docker/build-multiplatform.sh help
```
