# Version Management

DFTracer uses two separate version files for different purposes:

## Version Files

### 1. `VERSION` - Library Version
- **Location**: `VERSION` (project root)
- **Purpose**: C++ library version (semantic versioning)
- **Current**: `$(cat ../../VERSION 2>/dev/null || echo "4.0.0")`
- **Used by**: 
  - CMake build system
  - Shared library SO versioning
  - Documentation (Sphinx)
  - Module files

### 2. `PACKAGE_VERSION` - Python Package Version
- **Location**: `PACKAGE_VERSION` (project root)  
- **Purpose**: Python package version
- **Current**: `$(cat ../../PACKAGE_VERSION 2>/dev/null || echo "2.0.2")`
- **Used by**:
  - Python bindings
  - PyPI releases
  - setuptools-scm integration

## Why Two Versions?

The library and package versions are decoupled because:
- The C++ library API changes independently from Python package releases
- Python packages may need patch releases without library changes
- Library major versions indicate ABI compatibility
- Package versions track Python-specific changes and fixes

## Updating Versions

### Library Version (VERSION file)

Use the automated script:

```bash
# Auto-detect version bump from git commits
./script/repo/update_version.sh

# Force a specific bump type
./script/repo/update_version.sh --type minor

# Set a specific version
./script/repo/update_version.sh --version 4.1.0

# Dry run to preview changes
./script/repo/update_version.sh --dry-run
```

The script analyzes commits since the last tag and determines the appropriate version bump:
- **MAJOR**: Breaking changes, API changes (keywords: BREAKING, API_CHANGE)
- **MINOR**: New features, enhancements (keywords: feat, feature, add, new)
- **PATCH**: Bug fixes, documentation (keywords: fix, bug, doc, chore)

### Package Version (PACKAGE_VERSION file)

For Python package releases, update manually or use setuptools-scm:

```bash
# Manual update
echo "2.0.3" > PACKAGE_VERSION

# Or rely on setuptools-scm to generate from git tags
```

## CMake Variables

After reading the version files, CMakeLists.txt sets these variables:

### Library Version Variables
- `DFTRACER_VERSION_MAJOR` - Major version (e.g., `4`)
- `DFTRACER_VERSION_MINOR` - Minor version (e.g., `0`)
- `DFTRACER_VERSION_PATCH` - Patch version (e.g., `0`)
- `DFTRACER_LIBRARY_VERSION` - Full library version (e.g., `4.0.0`)

### Package Version Variables
- `DFTRACER_PACKAGE_VERSION_MAJOR` - Package major (e.g., `2`)
- `DFTRACER_PACKAGE_VERSION_MINOR` - Package minor (e.g., `0`)
- `DFTRACER_PACKAGE_VERSION_PATCH` - Package patch (e.g., `2`)
- `DFTRACER_PACKAGE_VERSION` - Tuple string (e.g., `(2, 0, 2)`)
- `DFTRACER_PACKAGE_VERSION_FULL` - Full package version (e.g., `2.0.2`)

## Release Workflow

1. **Make changes and commit**
   ```bash
   git add .
   git commit -m "feat: Add new feature"
   ```

2. **Update library version**
   ```bash
   ./script/repo/update_version.sh
   git add VERSION
   git commit -m "Bump library version to X.Y.Z"
   ```

3. **Update package version (if needed)**
   ```bash
   echo "2.0.3" > PACKAGE_VERSION
   git add PACKAGE_VERSION
   git commit -m "Bump package version to 2.0.3"
   ```

4. **Create and push tag**
   ```bash
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push && git push --tags
   ```

## Version History

- **Library $(cat ../../VERSION 2>/dev/null || echo "4.0.0")** / **Package $(cat ../../PACKAGE_VERSION 2>/dev/null || echo "2.0.2")** - Current versions
  - Centralized version management
  - Separate library and package versioning
