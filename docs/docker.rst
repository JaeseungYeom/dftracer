=======================================
Using Docker for Testing DFTracer
=======================================

This guide explains how to use Docker containers for testing and developing DFTracer. Docker provides a consistent, isolated environment that makes it easy to test DFTracer without affecting your host system.

Overview
========

DFTracer includes a complete Docker development environment with:

* Multi-platform support (amd64 and arm64)
* Pre-installed dependencies (Python, C++, system tools, hwloc, MPICH)
* Pre-built production images on Docker Hub
* Automated build and run scripts
* VS Code Dev Container integration
* Consistent environment across all platforms

Using Pre-built Docker Images
==============================

The easiest way to get started is to use pre-built images from Docker Hub:

Pulling from Docker Hub
-----------------------

.. code-block:: bash

   # Pull the latest release
   docker pull dftracer/dftracer:latest

   # Pull a specific version
   docker pull dftracer/dftracer:1.0.0

Running Pre-built Images
------------------------

.. code-block:: bash

   # Run with your workspace mounted
   docker run -it --rm -v "$PWD:/workspace/myproject" dftracer/dftracer:latest

   # Inside the container, the virtual environment is already activated
   # DFTracer is pre-installed and ready to use
   dftracer --help

The pre-built images include:

* Python 3.10 with virtual environment activated
* DFTracer with all dependencies pre-installed
* hwloc and MPICH for parallel computing
* All development tools (gdb, vim, htop, etc.)

Building from Source
=====================

Quick Start
-----------

Building the Docker Image
~~~~~~~~~~~~~~~~~~~~~~~~~~

Build the Docker image for your current platform:

.. code-block:: bash

   # From the project root
   ./infrastructure/docker/build-multiplatform.sh build --load

This command will:

1. Detect your platform (amd64 or arm64)
2. Build a Docker image with all DFTracer dependencies
3. Load the image into your local Docker registry
4. Tag it as ``dftracer-dev:latest``

Running the Container
---------------------

Run the container with automatic platform detection:

.. code-block:: bash

   ./infrastructure/docker/build-multiplatform.sh run

This will:

* Auto-detect your host platform
* Mount your current directory to ``/workspace/dftracer``
* Start an interactive bash session
* Use the non-root ``developer`` user

Inside the container, DFTracer is automatically installed in editable mode.

Testing DFTracer in Docker
===========================

Basic Testing
-------------

Once inside the container, you can run tests:

.. code-block:: bash

   # Run Python tests
   pytest test/

   # Run specific test file
   pytest test/py/test_core.py

   # Run with verbose output
   pytest -v test/

Building from Source
--------------------

Build DFTracer using CMake:

.. code-block:: bash

   # Create build directory
   mkdir build && cd build

   # Configure
   cmake ..

   # Build with all CPU cores
   make -j$(nproc)

   # Run C++ tests
   ctest

   # Install
   make install

Testing with Different Python Versions
---------------------------------------

Build images with different Python versions:

.. code-block:: bash

   # Build with Python 3.11
   ./infrastructure/docker/build-multiplatform.sh build \
       --python 3.11 \
       --tag py311 \
       --load

   # Run with Python 3.11 image
   ./infrastructure/docker/build-multiplatform.sh run --tag py311

Advanced Usage
==============

Running Custom Commands
-----------------------

Execute specific commands without entering the container:

.. code-block:: bash

   # Run tests directly
   ./infrastructure/docker/build-multiplatform.sh run \
       --cmd "pytest test/ -v"

   # Build and test in one command
   ./infrastructure/docker/build-multiplatform.sh run \
       --cmd "pip install -e .[test] && pytest test/"

   # Run a Python script
   ./infrastructure/docker/build-multiplatform.sh run \
       --cmd "python examples/simple_example.py"

Using Environment Variables
----------------------------

Set environment variables for testing:

.. code-block:: bash

   # Enable DFTracer with specific settings
   ./infrastructure/docker/build-multiplatform.sh run \
       -e DFTRACER_ENABLE=1 \
       -e DFTRACER_LOG_FILE=/tmp/trace.log \
       -e DFTRACER_DATA_DIR=/workspace/dftracer/data

   # Test with different configurations
   ./infrastructure/docker/build-multiplatform.sh run \
       -e DFTRACER_INIT=PRELOAD \
       -e LD_PRELOAD=/usr/local/lib/libdftracer.so \
       --cmd "python my_test.py"

Mounting Additional Volumes
----------------------------

Mount additional directories for testing:

.. code-block:: bash

   # Mount a data directory
   ./infrastructure/docker/build-multiplatform.sh run \
       -v /host/data:/data \
       -e DFTRACER_DATA_DIR=/data

   # Mount multiple volumes
   ./infrastructure/docker/build-multiplatform.sh run \
       -v /host/data:/data \
       -v /host/output:/output

Running in Background
---------------------

Run containers in detached mode:

.. code-block:: bash

   # Start container in background
   ./infrastructure/docker/build-multiplatform.sh run \
       --detach \
       --cmd "python long_running_test.py"

   # Check running containers
   docker ps

   # View logs
   docker logs <container-id>

   # Stop container
   docker stop <container-id>

Multi-Platform Builds
=====================

Building for Multiple Architectures
------------------------------------

Build images for both amd64 and arm64:

.. code-block:: bash

   # Build for multiple platforms
   ./infrastructure/docker/build-multiplatform.sh build \
       --arch linux/amd64,linux/arm64

   # Push to registry (e.g., Docker Hub)
   ./infrastructure/docker/build-multiplatform.sh build \
       --name username/dftracer-dev \
       --arch linux/amd64,linux/arm64 \
       --push

.. note::
   Multi-platform builds require Docker Buildx. It's included in Docker Desktop by default.

Platform-Specific Builds
-------------------------

Build for a specific platform:

.. code-block:: bash

   # Build for amd64 only
   ./infrastructure/docker/build-multiplatform.sh build \
       --arch linux/amd64 \
       --load

   # Build for arm64 only
   ./infrastructure/docker/build-multiplatform.sh build \
       --arch linux/arm64 \
       --load

VS Code Dev Container
=====================

Using the Dev Container
-----------------------

DFTracer includes a pre-configured VS Code Dev Container:

1. Open the project in VS Code
2. Press ``Cmd+Shift+P`` (Mac) or ``Ctrl+Shift+P`` (Windows/Linux)
3. Select **"Dev Containers: Reopen in Container"**
4. Wait for the container to build and start

The dev container includes:

* Python and C++ development tools
* Pre-configured extensions (Pylance, CMake Tools, etc.)
* Automatic DFTracer installation
* Debugging support with GDB

Dev Container Features
----------------------

The dev container automatically:

* Builds the Docker image on first use
* Installs DFTracer with test and analyzer dependencies
* Configures git safe directory
* Sets up Python and C++ tooling
* Mounts your workspace

Working in VS Code
------------------

Once inside the dev container:

* Use the integrated terminal for commands
* Run and debug Python/C++ code
* Use IntelliSense for code completion
* Run tests with the Testing sidebar
* Build with CMake Tools extension

Customization
-------------

Edit ``.devcontainer/devcontainer.json`` to customize:

.. code-block:: json

   {
       "build": {
           "args": {
               "PYTHON_VERSION": "3.11"  // Change Python version
           }
       },
       "remoteEnv": {
           "DFTRACER_ENABLE": "1"  // Set environment variables
       }
   }

Testing Workflows
=================

Integration Testing
-------------------

Test DFTracer with real applications:

.. code-block:: bash

   # Run container with your application
   ./infrastructure/docker/build-multiplatform.sh run

   # Inside container
   cd /workspace/dftracer
   
   # Install your application
   pip install your-app
   
   # Enable DFTracer and run
   export DFTRACER_ENABLE=1
   export DFTRACER_LOG_FILE=/tmp/trace.log
   export DFTRACER_DATA_DIR=/workspace/dftracer/data
   
   python -c "import dftracer; from your_app import main; main()"

Performance Testing
-------------------

Test DFTracer overhead:

.. code-block:: bash

   # Run performance tests
   ./infrastructure/docker/build-multiplatform.sh run \
       --cmd "python test/paper/test_overhead.py"

   # Compare with and without tracing
   ./infrastructure/docker/build-multiplatform.sh run \
       -e DFTRACER_ENABLE=0 \
       --cmd "python benchmark.py"

Regression Testing
------------------

Run the full test suite:

.. code-block:: bash

   # Run all tests
   ./infrastructure/docker/build-multiplatform.sh run \
       --cmd "pytest test/ --cov=dftracer --cov-report=html"

   # Run specific test categories
   ./infrastructure/docker/build-multiplatform.sh run \
       --cmd "pytest test/unit/"

Continuous Integration
----------------------

Use Docker in CI/CD pipelines:

.. code-block:: yaml

   # GitHub Actions example
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v2
         - name: Build Docker image
           run: |
             ./infrastructure/docker/build-multiplatform.sh build --load
         - name: Run tests
           run: |
             ./infrastructure/docker/build-multiplatform.sh run \
               --cmd "pytest test/ -v"

Troubleshooting
===============

Common Issues
-------------

**Build fails with "buildx not available":**

.. code-block:: bash

   # Install buildx (if using standalone Docker)
   docker buildx install
   
   # Or install Docker Desktop which includes buildx

**Permission denied errors:**

The container uses UID 1000 by default. If your user has a different UID:

.. code-block:: bash

   # Check your UID
   id -u
   
   # Rebuild with your UID
   docker build \
       --build-arg USER_UID=$(id -u) \
       --build-arg USER_GID=$(id -g) \
       -f infrastructure/docker/Dockerfile.dev \
       -t dftracer-dev:latest .

**Container can't access files:**

Make sure the workspace is mounted:

.. code-block:: bash

   # Explicitly mount the workspace
   ./infrastructure/docker/build-multiplatform.sh run \
       -v $(pwd):/workspace/dftracer

**Out of disk space:**

Clean up Docker resources:

.. code-block:: bash

   # Remove unused images
   docker image prune
   
   # Remove all unused resources
   docker system prune -a

Getting Container Information
------------------------------

.. code-block:: bash

   # List images
   docker images | grep dftracer
   
   # List running containers
   docker ps
   
   # Inspect container
   docker inspect dftracer-dev:latest
   
   # View container logs
   docker logs <container-id>

Rebuilding from Scratch
------------------------

.. code-block:: bash

   # Build without cache
   ./infrastructure/docker/build-multiplatform.sh build \
       --no-cache \
       --load

   # Remove old images
   docker rmi dftracer-dev:latest

   # Rebuild
   ./infrastructure/docker/build-multiplatform.sh build --load

Best Practices
==============

1. **Use the run script**: Prefer ``build-multiplatform.sh run`` over manual ``docker run`` commands
2. **Mount your workspace**: Keep your code on the host for easy editing
3. **Use environment variables**: Configure DFTracer through env vars instead of modifying files
4. **Test incrementally**: Use the container for quick iterative testing
5. **Clean up regularly**: Remove unused containers and images to save disk space
6. **Version your images**: Use tags to track different configurations

Example Testing Session
=======================

Complete workflow for testing a new feature:

.. code-block:: bash

   # 1. Build the Docker image
   ./infrastructure/docker/build-multiplatform.sh build --load

   # 2. Run tests to establish baseline
   ./infrastructure/docker/build-multiplatform.sh run \
       --cmd "pytest test/ -v"

   # 3. Make code changes on your host
   # (Edit files in your editor)

   # 4. Test your changes
   ./infrastructure/docker/build-multiplatform.sh run \
       --cmd "pytest test/py/test_my_feature.py -v"

   # 5. Test with DFTracer enabled
   ./infrastructure/docker/build-multiplatform.sh run \
       -e DFTRACER_ENABLE=1 \
       -e DFTRACER_LOG_FILE=/tmp/trace.log \
       --cmd "python examples/test_feature.py"

   # 6. Interactive debugging session
   ./infrastructure/docker/build-multiplatform.sh run
   # Inside container:
   # >>> python -m pdb test_script.py

   # 7. Run full test suite before committing
   ./infrastructure/docker/build-multiplatform.sh run \
       --cmd "pytest test/ --cov=dftracer"

Additional Resources
====================

* Docker Documentation: ``infrastructure/docker/README.md``
* Dev Container Documentation: ``.devcontainer/README.md``
* Quick Reference: ``infrastructure/docker/QUICK_REFERENCE.md``
* Build Script Help: ``./infrastructure/docker/build-multiplatform.sh help``

See Also
========

* :doc:`build` - Building DFTracer from source
* :doc:`testing` - Testing DFTracer
* :doc:`developer-guide` - Contributing to DFTracer
* :doc:`debugging` - Debugging DFTracer
