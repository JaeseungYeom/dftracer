# Coverage Scripts

This directory contains scripts for C/C++ code coverage analysis.

## Quick Start

### Using autobuild.sh (Recommended)

```bash
# 1. Build with coverage enabled
./autobuild.sh --enable-coverage

# 2. Generate coverage report
./script/coverage_after_autobuild.sh

# 3. Generate detailed analysis
./script/generate_coverage_report.sh > coverage_report.txt
```

### Manual Build

```bash
# 1. Build with coverage enabled
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=PROFILE -DDFTRACER_ENABLE_TESTS=ON ..
make -j

# 2. Run tests
ctest --output-on-failure

# 3. Generate and view coverage
cd ..
./script/check_coverage.sh
```

## Scripts

### `coverage_after_autobuild.sh` - Coverage for Autobuild Environments

**Purpose**: Run coverage analysis after building with autobuild.sh.

**Usage**:
```bash
# First build with coverage
./autobuild.sh --enable-coverage

# Then run coverage analysis
./script/coverage_after_autobuild.sh
```

**Features**:
- ✓ Validates PROFILE build type
- ✓ Checks tests are enabled
- ✓ Automatically runs tests if needed
- ✓ Generates all coverage reports
- ✓ Shows coverage summary
- ✓ Provides next steps

**Output**:
- HTML report: `build/coverage/html/index.html`
- XML report: `build/coverage/coverage.xml`
- Coveralls JSON: `build/coverage/coveralls.json`

### `generate_coverage_report.sh` - Detailed Analysis Report

**Purpose**: Generate a comprehensive coverage analysis report for improving tests.

**Usage**:
```bash
./script/generate_coverage_report.sh > coverage_report.txt
```

**What it includes**:
- Overall coverage statistics with targets
- File-by-file coverage breakdown (sorted by coverage %)
- Uncovered code sections with specific line numbers
- Partially covered branches
- Uncalled functions
- Recommendations for test improvement
- Instructions for sharing with AI assistants

**Use case**: Share the generated report with AI assistants to get help writing tests for uncovered code.

### `check_coverage.sh` - Interactive Coverage Tool

**Purpose**: Check coverage locally and get actionable feedback.

**Usage**:
```bash
./script/check_coverage.sh
```

**Features**:
- ✓ Automatically runs tests if needed
- ✓ Generates HTML reports
- ✓ Shows coverage summary with color-coded targets
- ✓ Provides instructions for viewing and improving coverage
- ✓ Compares against target thresholds (>80% line, >70% branch)

**Output**:
- HTML report: `build/coverage/html/index.html`
- Console summary with targets
- Instructions for next steps

### `generate_coverage.sh` - Report Generator

**Purpose**: Generate coverage reports in multiple formats.

**Usage**:
```bash
./script/generate_coverage.sh [build_dir] [source_dir]

# Examples
./script/generate_coverage.sh build .
./script/generate_coverage.sh build/Release ../src
```

**Generated Files**:
- `build/coverage/html/index.html` - Detailed HTML report
- `build/coverage/coverage.xml` - XML for CI tools
- `build/coverage/coveralls.json` - Coveralls.io format

**Features**:
- Multiple output formats
- Excludes test code, examples, dependencies
- Filters unreachable branches
- Summary printed to console

## Workflow Examples

### Complete Coverage Workflow with Autobuild

```bash
# 1. Build with coverage
./autobuild.sh --enable-coverage

# 2. Run coverage analysis
./script/coverage_after_autobuild.sh

# 3. View HTML report (interactive)
open build/coverage/html/index.html

# 4. Generate detailed report for AI analysis
./script/generate_coverage_report.sh > coverage_report.txt

# 5. Share coverage_report.txt with AI assistant
#    Ask: "Help me write tests to improve coverage for files with <70% coverage"

# 6. Add tests based on recommendations
vim test/new_coverage_test.cpp

# 7. Rebuild and check improved coverage
cd build && make -j && ctest && cd ..
./script/coverage_after_autobuild.sh
```

### Basic Local Testing

```bash
# Quick check during development
./script/check_coverage.sh

# View report
open build/coverage/html/index.html
```

### Iterative Test Development

```bash
# 1. Check current coverage
./script/check_coverage.sh

# 2. Identify uncovered code in HTML report
open build/coverage/html/index.html

# 3. Add tests for uncovered code
vim test/my_new_test.cpp

# 4. Build and test
cd build
make -j
ctest --output-on-failure

# 5. Check improved coverage
cd ..
./script/check_coverage.sh
```

### CI Integration

Coverage is automatically collected in GitHub Actions:
- Build type: PROFILE
- Platform: ubuntu-22.04
- Reports uploaded to Coveralls.io
- Artifacts stored for 7 days

## CMake Integration

The build system includes a `coverage` target:

```bash
cd build
make coverage
```

This runs gcovr with appropriate filters and generates:
- HTML report with details
- XML report for CI
- Coveralls JSON format
- Console summary

## Coverage Targets

| Metric | Target | Check Command |
|--------|--------|---------------|
| Line Coverage | >80% | `./script/check_coverage.sh` |
| Branch Coverage | >70% | `./script/check_coverage.sh` |
| Function Coverage | >75% | `./script/check_coverage.sh` |

## Requirements

### Tools

```bash
# gcovr (required)
pip install gcovr

# or system package
sudo apt-get install gcovr  # Ubuntu/Debian
brew install gcovr          # macOS
```

### Build Configuration

- **Build Type**: `PROFILE` (enables `--coverage` flags)
- **Tests**: Enabled with `DFTRACER_ENABLE_TESTS=ON`
- **Compiler**: GCC or Clang with coverage support

## Troubleshooting

### No coverage data found

**Problem**: `.gcda` files missing

**Solution**:
```bash
# Ensure PROFILE build
cmake -DCMAKE_BUILD_TYPE=PROFILE ..
make -j
# Run tests
ctest
```

### gcovr not found

**Solution**: Install gcovr
```bash
pip install gcovr
```

### Low coverage

**Solution**: Use interactive workflow
1. Run `./script/check_coverage.sh`
2. Open HTML report
3. Find red/yellow lines (uncovered code)
4. Add tests for those code paths
5. Re-run check_coverage.sh

## More Information

See [docs/coverage.md](../docs/coverage.md) for comprehensive guide including:
- Detailed local development workflow
- CI/CD integration
- Coverage improvement strategies
- Advanced usage and filtering
- Best practices
