# Coverage Quick Reference Card

## Build with Coverage

```bash
# Using autobuild.sh (recommended)
./autobuild.sh --enable-coverage

# Or manually
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=PROFILE -DDFTRACER_ENABLE_TESTS=ON ..
make -j
```

## Generate Reports

```bash
# After autobuild.sh
./script/coverage_after_autobuild.sh

# Quick check
./script/check_coverage.sh

# Detailed analysis for AI
./script/generate_coverage_report.sh > coverage_report.txt
```

## View Reports

```bash
# Open HTML report
open build/coverage/html/index.html

# Or start web server
python3 -m http.server -d build/coverage/html 8000
# Visit http://localhost:8000
```

## Complete Workflow

```bash
# 1. Build with coverage
./autobuild.sh --enable-coverage

# 2. Generate reports
./script/coverage_after_autobuild.sh

# 3. Generate detailed analysis
./script/generate_coverage_report.sh > coverage_report.txt

# 4. Share coverage_report.txt with AI assistant for test suggestions

# 5. Add suggested tests to test/ directory

# 6. Rebuild and verify
cd build && make -j && ctest && cd ..
./script/coverage_after_autobuild.sh

# 7. Repeat until targets met
```

## Coverage Targets

| Metric | Target |
|--------|--------|
| Line Coverage | >80% |
| Branch Coverage | >70% |
| Function Coverage | >75% |

## AI Assistant Prompt Template

```
I have a C++ project called DFTracer with the following coverage report:

[paste coverage_report.txt contents]

Please help me write ctest tests to improve coverage. Focus on:
1. Files with <70% line coverage
2. Uncovered functions in src/dftracer/core/
3. Partially covered branches (error handling paths)

For each suggestion, provide:
- The specific file and line numbers being tested
- Complete test function using Google Test framework
- Explanation of what the test covers
```

## Scripts Reference

| Script | Purpose | Usage |
|--------|---------|-------|
| `coverage_after_autobuild.sh` | Run coverage after autobuild | `./script/coverage_after_autobuild.sh` |
| `generate_coverage_report.sh` | Detailed analysis report | `./script/generate_coverage_report.sh > report.txt` |
| `check_coverage.sh` | Quick interactive check | `./script/check_coverage.sh` |
| `generate_coverage.sh` | Generate reports (low-level) | `./script/generate_coverage.sh build .` |

## Troubleshooting

### No coverage data

```bash
# Ensure PROFILE build
./autobuild.sh --enable-coverage

# Or check build type
grep CMAKE_BUILD_TYPE build/CMakeCache.txt
```

### Tests not running

```bash
# Run tests manually
cd build
ctest --output-on-failure
```

### gcovr not found

```bash
pip install gcovr
```

### Low coverage

```bash
# Generate detailed report
./script/generate_coverage_report.sh > coverage_report.txt

# Share with AI for test suggestions
cat coverage_report.txt | pbcopy  # macOS
```

## Files Generated

- `build/coverage/html/index.html` - Interactive HTML report (main view)
- `build/coverage/html/*.html` - File-by-file detailed views
- `build/coverage/coverage.xml` - XML for CI tools
- `build/coverage/coveralls.json` - Coveralls.io format
- `coverage_report.txt` - Detailed analysis (you generate this)

## Next Steps

After generating coverage reports:

1. **View HTML**: See visual representation with line-by-line highlighting
2. **Generate Analysis**: Create text report for AI assistant
3. **Get AI Help**: Share report with AI for test suggestions
4. **Write Tests**: Implement suggested tests in `test/` directory
5. **Verify**: Rebuild, run tests, check coverage improved
6. **Iterate**: Repeat until coverage targets met

## Documentation

- Full guide: `docs/coverage.md`
- Script details: `script/README_COVERAGE.md`
- Autobuild help: `./autobuild.sh --help`
