#!/bin/bash
# Quick script to check C/C++ coverage locally and improve tests
# Works with both manual builds and autobuild.sh environments

set -e

BUILD_DIR="${BUILD_DIR:-build}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "==========================================="
echo "DFTracer C/C++ Coverage Quick Check"
echo "==========================================="

# Check if build directory exists
if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${RED}Error: build directory not found${NC}"
    echo ""
    echo "Build with coverage enabled:"
    echo "  ./autobuild.sh --enable-coverage"
    echo ""
    echo "Or manually:"
    echo "  mkdir build && cd build"
    echo "  cmake -DCMAKE_BUILD_TYPE=PROFILE -DDFTRACER_ENABLE_TESTS=ON .."
    echo "  make -j"
    exit 1
fi

# Check if gcovr is available
if ! command -v gcovr &> /dev/null; then
    echo -e "${RED}Error: gcovr not found${NC}"
    echo "Install with: pip install gcovr"
    exit 1
fi

# Check if tests have been run
GCDA_COUNT=$(find "$BUILD_DIR" -name "*.gcda" 2>/dev/null | wc -l)
if [ "$GCDA_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}Warning: No coverage data found (.gcda files)${NC}"
    echo "Running tests first..."
    echo ""
    cd "$BUILD_DIR"
    ctest --output-on-failure
    cd ..
    echo ""
fi

# Clean old coverage reports
echo "Cleaning old coverage reports..."
rm -rf "$BUILD_DIR/coverage"

# Generate coverage report
echo ""
echo "Generating coverage report..."
echo "-------------------------------------------"
bash script/generate_coverage.sh "$BUILD_DIR" .

# Parse coverage summary for highlighting
echo ""
echo "==========================================="
echo "Coverage Analysis"
echo "==========================================="

cd "$BUILD_DIR"
SUMMARY=$(gcovr -r .. . \
    -e ../test/ \
    -e ../examples/ \
    -e ../dependency/ \
    -e ../build/ \
    --exclude-unreachable-branches \
    --exclude-throw-branches 2>&1)

echo "$SUMMARY"

# Extract coverage percentages
LINE_COV=$(echo "$SUMMARY" | grep "^TOTAL" | awk '{print $4}' | tr -d '%')
BRANCH_COV=$(echo "$SUMMARY" | grep "^TOTAL" | awk '{print $6}' | tr -d '%')

cd ..

echo ""
echo "==========================================="
echo "Coverage Targets"
echo "==========================================="
echo "  Line Coverage:   ${LINE_COV}% (target: >80%)"
echo "  Branch Coverage: ${BRANCH_COV}% (target: >70%)"
echo ""

# Check coverage targets
NEED_IMPROVEMENT=0
if (( $(echo "$LINE_COV < 80" | bc -l) )); then
    echo -e "${YELLOW}⚠ Line coverage below target${NC}"
    NEED_IMPROVEMENT=1
fi
if (( $(echo "$BRANCH_COV < 70" | bc -l) )); then
    echo -e "${YELLOW}⚠ Branch coverage below target${NC}"
    NEED_IMPROVEMENT=1
fi

if [ $NEED_IMPROVEMENT -eq 0 ]; then
    echo -e "${GREEN}✓ All coverage targets met!${NC}"
fi

echo ""
echo "==========================================="
echo "Next Steps"
echo "==========================================="
echo ""
echo "1. View detailed HTML report:"
echo -e "   ${GREEN}open $BUILD_DIR/coverage/html/index.html${NC}"
echo ""
echo "2. Or start a local server:"
echo "   python3 -m http.server -d $BUILD_DIR/coverage/html 8000"
echo "   Then visit: http://localhost:8000"
echo ""
echo "3. Find uncovered code:"
echo "   Look for red/yellow highlighted lines in HTML report"
echo ""
echo "4. Improve coverage by:"
echo "   - Adding tests for uncovered functions"
echo "   - Testing error paths and edge cases"
echo "   - Adding branch coverage tests"
echo ""
echo "5. Re-run after adding tests:"
echo "   cd $BUILD_DIR && ctest && cd .. && ./script/check_coverage.sh"
echo ""
echo "==========================================="
