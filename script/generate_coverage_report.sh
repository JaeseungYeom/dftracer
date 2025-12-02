#!/bin/bash
# Generate a detailed coverage report for AI assistant analysis
# This report helps identify specific uncovered code sections for test improvement

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-${PROJECT_DIR}/build}"

# Check if coverage data exists
if [ ! -d "$BUILD_DIR/coverage" ]; then
    echo "Error: Coverage reports not found. Run coverage analysis first:"
    echo "  ./script/coverage_after_autobuild.sh"
    exit 1
fi

echo "==============================================================================="
echo "DFTracer C/C++ Coverage Analysis Report"
echo "==============================================================================="
echo ""
echo "Generated: $(date)"
echo "Build Directory: $BUILD_DIR"
echo "Source Directory: $PROJECT_DIR"
echo ""
echo "This report provides detailed coverage information to help improve test coverage."
echo "It includes:"
echo "  - Overall coverage statistics"
echo "  - File-by-file coverage breakdown"
echo "  - Uncovered and partially covered functions"
echo "  - Specific line numbers that need test coverage"
echo ""
echo "==============================================================================="
echo ""

# Overall statistics
echo "## OVERALL COVERAGE STATISTICS"
echo "==============================================================================="
cd "$BUILD_DIR"
gcovr -r "$PROJECT_DIR" . \
    -e "$PROJECT_DIR/test/" \
    -e "$PROJECT_DIR/examples/" \
    -e "$PROJECT_DIR/dependency/" \
    -e "$PROJECT_DIR/build/" \
    --exclude-unreachable-branches \
    --exclude-throw-branches \
    --print-summary

cd "$PROJECT_DIR"
echo ""
echo "Coverage Targets:"
echo "  - Line Coverage:     >80%"
echo "  - Branch Coverage:   >70%"
echo "  - Function Coverage: >75%"
echo ""
echo "==============================================================================="
echo ""

# File-by-file coverage
echo "## FILE-BY-FILE COVERAGE BREAKDOWN"
echo "==============================================================================="
echo ""
echo "Files sorted by coverage percentage (lowest first):"
echo ""

cd "$BUILD_DIR"
gcovr -r "$PROJECT_DIR" . \
    -e "$PROJECT_DIR/test/" \
    -e "$PROJECT_DIR/examples/" \
    -e "$PROJECT_DIR/dependency/" \
    -e "$PROJECT_DIR/build/" \
    --exclude-unreachable-branches \
    --exclude-throw-branches \
    --sort-percentage

echo ""
echo "==============================================================================="
echo ""

# Uncovered lines by file
echo "## UNCOVERED CODE SECTIONS"
echo "==============================================================================="
echo ""
echo "The following sections show files with uncovered lines that need test coverage."
echo "Focus on critical files first (core library functionality)."
echo ""

# Generate detailed coverage data with uncovered lines
cd "$BUILD_DIR"
COVERAGE_DATA=$(gcovr -r "$PROJECT_DIR" . \
    -e "$PROJECT_DIR/test/" \
    -e "$PROJECT_DIR/examples/" \
    -e "$PROJECT_DIR/dependency/" \
    -e "$PROJECT_DIR/build/" \
    --exclude-unreachable-branches \
    --exclude-throw-branches \
    --json)

cd "$PROJECT_DIR"

# Parse JSON to extract uncovered lines per file
echo "$COVERAGE_DATA" | python3 -c "
import json
import sys
from pathlib import Path

data = json.load(sys.stdin)
source_dir = Path('$PROJECT_DIR')

# Group files by directory
files_by_dir = {}
for file in data['files']:
    file_path = file['file']
    
    # Skip if not in src/dftracer
    if '/src/dftracer/' not in file_path:
        continue
    
    line_cov = file['line_coverage'] if file['line_coverage'] > 0 else 0
    branch_cov = file['branch_coverage'] if file.get('branch_coverage', 0) > 0 else 0
    
    # Only show files with less than 90% coverage
    if line_cov >= 90:
        continue
    
    # Extract uncovered lines
    uncovered_lines = []
    partially_covered_lines = []
    
    for line in file.get('lines', []):
        line_num = line['line_number']
        count = line['count']
        
        if count == 0:
            uncovered_lines.append(line_num)
        
        # Check for partially covered branches
        if 'branches' in line:
            branches = line['branches']
            covered_branches = sum(1 for b in branches if b['count'] > 0)
            total_branches = len(branches)
            if 0 < covered_branches < total_branches:
                partially_covered_lines.append(line_num)
    
    if not uncovered_lines and not partially_covered_lines:
        continue
    
    # Get relative path
    try:
        rel_path = Path(file_path).relative_to(source_dir)
    except:
        rel_path = file_path
    
    # Group by directory
    dir_name = str(rel_path.parent)
    if dir_name not in files_by_dir:
        files_by_dir[dir_name] = []
    
    files_by_dir[dir_name].append({
        'path': str(rel_path),
        'line_coverage': line_cov,
        'branch_coverage': branch_cov,
        'uncovered_lines': uncovered_lines,
        'partially_covered_lines': partially_covered_lines
    })

# Print results grouped by directory
for dir_name in sorted(files_by_dir.keys()):
    print(f'\n### Directory: {dir_name}')
    print('---' + '-' * 70)
    
    for file_info in sorted(files_by_dir[dir_name], key=lambda x: x['line_coverage']):
        print(f\"\\nFile: {file_info['path']}\")
        print(f\"  Line Coverage:   {file_info['line_coverage']:.1f}%\")
        print(f\"  Branch Coverage: {file_info['branch_coverage']:.1f}%\")
        
        if file_info['uncovered_lines']:
            uncovered = file_info['uncovered_lines']
            # Group consecutive lines
            ranges = []
            start = uncovered[0]
            end = uncovered[0]
            for line in uncovered[1:]:
                if line == end + 1:
                    end = line
                else:
                    ranges.append(f'{start}-{end}' if start != end else str(start))
                    start = line
                    end = line
            ranges.append(f'{start}-{end}' if start != end else str(start))
            
            print(f\"  Uncovered Lines: {', '.join(ranges)}\")
            if len(uncovered) > 20:
                print(f\"    (Total: {len(uncovered)} uncovered lines)\")
        
        if file_info['partially_covered_lines']:
            partial = file_info['partially_covered_lines'][:10]  # Show first 10
            print(f\"  Partial Branch Coverage: Lines {', '.join(map(str, partial))}\")
            if len(file_info['partially_covered_lines']) > 10:
                print(f\"    (... and {len(file_info['partially_covered_lines']) - 10} more)\")

print()
" 2>/dev/null || echo "Note: Detailed line-by-line analysis requires Python 3 with json module"

echo ""
echo "==============================================================================="
echo ""

# Function coverage
echo "## FUNCTION COVERAGE ANALYSIS"
echo "==============================================================================="
echo ""
echo "Functions that are never called during tests:"
echo ""

cd "$BUILD_DIR"
# Generate function coverage report
gcovr -r "$PROJECT_DIR" . \
    -e "$PROJECT_DIR/test/" \
    -e "$PROJECT_DIR/examples/" \
    -e "$PROJECT_DIR/dependency/" \
    -e "$PROJECT_DIR/build/" \
    --exclude-unreachable-branches \
    --exclude-throw-branches \
    --json | python3 -c "
import json
import sys

data = json.load(sys.stdin)

uncalled_functions = []
for file in data['files']:
    if '/src/dftracer/' not in file['file']:
        continue
    
    for func in file.get('functions', []):
        if func['execution_count'] == 0:
            uncalled_functions.append({
                'file': file['file'].split('/')[-1],
                'name': func['name'],
                'line': func['start_line_number']
            })

if uncalled_functions:
    # Group by file
    by_file = {}
    for func in uncalled_functions:
        fname = func['file']
        if fname not in by_file:
            by_file[fname] = []
        by_file[fname].append(func)
    
    for fname in sorted(by_file.keys()):
        print(f'\n{fname}:')
        for func in by_file[fname]:
            print(f\"  - {func['name']} (line {func['line']})\")
else:
    print('All functions are covered!')
" 2>/dev/null || echo "Note: Function analysis requires Python 3"

cd "$PROJECT_DIR"

echo ""
echo "==============================================================================="
echo ""

# Recommendations
echo "## RECOMMENDATIONS FOR TEST IMPROVEMENT"
echo "==============================================================================="
echo ""
echo "Based on the coverage analysis above, here are recommended actions:"
echo ""
echo "1. PRIORITY: Files with <60% coverage"
echo "   - These files need comprehensive test coverage"
echo "   - Focus on core functionality first"
echo ""
echo "2. MEDIUM: Files with 60-80% coverage"
echo "   - Add tests for edge cases and error paths"
echo "   - Test branch conditions (if/else, switch)"
echo ""
echo "3. BRANCH COVERAGE: Partially covered lines"
echo "   - Test both true and false conditions"
echo "   - Test all switch/case branches"
echo "   - Test error handling paths"
echo ""
echo "4. FUNCTION COVERAGE: Uncalled functions"
echo "   - Verify if function is dead code or needs tests"
echo "   - Add API tests if function is part of public API"
echo ""
echo "==============================================================================="
echo ""

echo "## HOW TO USE THIS REPORT"
echo "==============================================================================="
echo ""
echo "To share this report with an AI assistant for test improvement:"
echo ""
echo "1. Save this output:"
echo "   ./script/generate_coverage_report.sh > coverage_analysis.txt"
echo ""
echo "2. Share with AI assistant and ask:"
echo "   'Based on this coverage report, help me write tests to improve coverage"
echo "    for the files with lowest coverage. Start with files in src/dftracer/core/'"
echo ""
echo "3. The AI can help you:"
echo "   - Write new test cases for uncovered functions"
echo "   - Add edge case tests for partial branch coverage"
echo "   - Identify which uncovered lines are critical vs. unreachable"
echo ""
echo "4. After adding tests:"
echo "   cd $BUILD_DIR"
echo "   make -j && ctest"
echo "   cd .."
echo "   ./script/coverage_after_autobuild.sh"
echo "   ./script/generate_coverage_report.sh > coverage_analysis_updated.txt"
echo ""
echo "==============================================================================="
echo ""
echo "Report complete. HTML report available at:"
echo "  $BUILD_DIR/coverage/html/index.html"
echo ""
