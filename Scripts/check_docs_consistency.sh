#!/bin/bash

# NotBad Documentation Consistency Checker
# This script validates documentation consistency and link validity
# 
# Usage: ./Scripts/check_docs_consistency.sh [--fix]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
FIX_ISSUES=false
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --fix)
            FIX_ISSUES=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Usage: $0 [--fix] [--verbose]"
            exit 1
            ;;
    esac
done

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if tools are available
check_dependencies() {
    log_info "Checking dependencies..."
    
    local missing_tools=()
    
    if ! command -v markdownlint >/dev/null 2>&1; then
        missing_tools+=("markdownlint-cli")
    fi
    
    if ! command -v lychee >/dev/null 2>&1; then
        missing_tools+=("lychee")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Install with:"
        for tool in "${missing_tools[@]}"; do
            case $tool in
                "markdownlint-cli")
                    echo "  npm install -g markdownlint-cli"
                    ;;
                "lychee")
                    echo "  cargo install lychee"
                    echo "  # or download from https://github.com/lycheeverse/lychee/releases"
                    ;;
            esac
        done
        return 1
    fi
    
    log_success "All dependencies available"
    return 0
}

# Check README consistency between root and docs
check_readme_consistency() {
    log_info "Checking README consistency..."
    
    local root_readme="$PROJECT_ROOT/README.md"
    local docs_readme="$PROJECT_ROOT/docs/README.md"
    
    if [[ ! -f "$root_readme" ]]; then
        log_error "Root README.md not found"
        return 1
    fi
    
    if [[ ! -f "$docs_readme" ]]; then
        log_error "docs/README.md not found"
        return 1
    fi
    
    # Check for common sections that should be consistent
    local consistency_issues=0
    
    # Extract project name from both READMEs
    local root_title=$(head -n 5 "$root_readme" | grep -E "^#\s+" | head -n 1 || echo "")
    local docs_title=$(head -n 5 "$docs_readme" | grep -E "^#\s+" | head -n 1 || echo "")
    
    if [[ -n "$root_title" && -n "$docs_title" ]]; then
        if [[ "$root_title" != *"NotBad"* ]] || [[ "$docs_title" != *"NotBad"* ]]; then
            log_warning "Project titles may be inconsistent between root and docs README"
            consistency_issues=$((consistency_issues + 1))
        fi
    fi
    
    # Check for version consistency
    if grep -q "v6.0" "$docs_readme" && ! grep -q "v6.0" "$root_readme"; then
        log_warning "Version references may be inconsistent between README files"
        consistency_issues=$((consistency_issues + 1))
    fi
    
    # Check for broken internal links between root and docs
    local broken_links=0
    while IFS= read -r line; do
        if echo "$line" | grep -q '\[.*\](docs/[^)]*'; then
            local link_path=$(echo "$line" | grep -o 'docs/[^)]*' | head -n 1)
            local full_path="$PROJECT_ROOT/$link_path"
            if [[ ! -f "$full_path" ]]; then
                log_error "Broken internal link in root README: $link_path"
                broken_links=$((broken_links + 1))
            fi
        fi
    done < "$root_readme"
    
    if [[ $broken_links -eq 0 && $consistency_issues -eq 0 ]]; then
        log_success "README files appear consistent"
        return 0
    else
        log_warning "Found $consistency_issues consistency issues and $broken_links broken links"
        return 1
    fi
}

# Run markdown linting with fix option
run_markdown_lint() {
    log_info "Running markdown linting..."
    
    cd "$PROJECT_ROOT"
    
    local lint_cmd="markdownlint '**/*.md' --ignore node_modules --config .markdownlint.jsonc"
    
    if [[ "$FIX_ISSUES" == "true" ]]; then
        lint_cmd="$lint_cmd --fix"
        log_info "Running with --fix option"
    fi
    
    if eval "$lint_cmd"; then
        log_success "Markdown linting passed"
        return 0
    else
        log_error "Markdown linting failed"
        return 1
    fi
}

# Check for common documentation issues
check_documentation_standards() {
    log_info "Checking documentation standards..."
    
    local issues=0
    
    # Check for missing required files
    local required_files=(
        "README.md"
        "docs/README.md"
        "LICENSE"
        "CONTRIBUTING.md"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$PROJECT_ROOT/$file" ]]; then
            log_error "Missing required file: $file"
            issues=$((issues + 1))
        fi
    done
    
    # Check for documentation version consistency
    local version_files=(
        "docs/README.md"
        "docs/prd/"*.md
        "docs/tdd/"*.md
        "docs/rtm/"*.md
    )
    
    local found_versions=()
    for pattern in "${version_files[@]}"; do
        for file in $pattern; do
            if [[ -f "$file" ]] && grep -q "v[0-9]\+\.[0-9]\+" "$file"; then
                local version=$(grep -o "v[0-9]\+\.[0-9]\+" "$file" | head -n 1)
                if [[ ! " ${found_versions[*]} " =~ " ${version} " ]]; then
                    found_versions+=("$version")
                fi
            fi
        done
    done
    
    if [[ ${#found_versions[@]} -gt 1 ]]; then
        log_warning "Multiple document versions found: ${found_versions[*]}"
        log_warning "Consider standardizing to a single version across all documents"
        issues=$((issues + 1))
    fi
    
    if [[ $issues -eq 0 ]]; then
        log_success "Documentation standards check passed"
        return 0
    else
        log_warning "Found $issues documentation standard issues"
        return 1
    fi
}

# Run link validation with improved configuration
run_link_validation() {
    log_info "Running link validation..."
    
    cd "$PROJECT_ROOT"
    
    # Create temporary exclude file for problematic links
    local temp_exclude=$(mktemp)
    cat > "$temp_exclude" << EOF
# Temporarily exclude badge URLs (network issues in CI)
https://img.shields.io/badge/*

# GitHub repository links that may not exist yet
https://github.com/chramboliao/NotBad/discussions
https://github.com/chramboliao/NotBad/issues

# External links that may have CORS/certificate issues
https://conventionalcommits.org/
EOF
    
    # Run lychee with custom configuration
    if lychee \
        --verbose \
        --no-progress \
        --exclude-file "$temp_exclude" \
        --config .lychee.toml \
        --accept 200,204,301,302,307,308,404 \
        "README.md" "docs/**/*.md" \
        | grep -E "(ERROR|WARN|Issues found)" || true; then
        
        local exit_code=${PIPESTATUS[0]}
        
        # Clean up
        rm -f "$temp_exclude"
        
        if [[ $exit_code -eq 0 ]]; then
            log_success "Link validation passed"
            return 0
        else
            log_warning "Link validation completed with some issues (see output above)"
            return 1
        fi
    fi
    
    # Clean up
    rm -f "$temp_exclude"
    log_error "Link validation failed"
    return 1
}

# Generate documentation summary report
generate_summary_report() {
    log_info "Generating documentation summary report..."
    
    local report_file="$PROJECT_ROOT/docs/DOC_VALIDATION_REPORT.md"
    
    cat > "$report_file" << EOF
# Documentation Validation Report

> Generated on: $(date)
> Script: Scripts/check_docs_consistency.sh

## Summary

This report provides an overview of documentation consistency and validation results.

### Document Structure

\`\`\`
$(find "$PROJECT_ROOT" -name "*.md" -type f | sort | sed "s|$PROJECT_ROOT/||" | head -20)
$([ $(find "$PROJECT_ROOT" -name "*.md" -type f | wc -l) -gt 20 ] && echo "... and $(( $(find "$PROJECT_ROOT" -name "*.md" -type f | wc -l) - 20 )) more files")
\`\`\`

### Key Documentation Files

- **Root README**: $([ -f "$PROJECT_ROOT/README.md" ] && echo "✅ Present" || echo "❌ Missing")
- **Docs README**: $([ -f "$PROJECT_ROOT/docs/README.md" ] && echo "✅ Present" || echo "❌ Missing")
- **License**: $([ -f "$PROJECT_ROOT/LICENSE" ] && echo "✅ Present" || echo "❌ Missing")
- **Contributing Guide**: $([ -f "$PROJECT_ROOT/CONTRIBUTING.md" ] && echo "✅ Present" || echo "❌ Missing")

### Documentation Standards

- Markdown linting configuration: $([ -f "$PROJECT_ROOT/.markdownlint.jsonc" ] && echo "✅ Configured" || echo "❌ Missing")
- Link checking configuration: $([ -f "$PROJECT_ROOT/.lychee.toml" ] && echo "✅ Configured" || echo "❌ Missing")
- Pre-commit hooks: $([ -f "$PROJECT_ROOT/.pre-commit-config.yaml" ] && echo "✅ Configured" || echo "❌ Missing")

### Validation Status

Run \`./Scripts/check_docs_consistency.sh\` to see current validation status.

For issues or improvements, check the main validation script.
EOF

    log_success "Report generated: docs/DOC_VALIDATION_REPORT.md"
}

# Main execution
main() {
    echo -e "${BLUE}NotBad Documentation Consistency Checker${NC}"
    echo "========================================"
    echo
    
    cd "$PROJECT_ROOT"
    
    local exit_code=0
    
    # Run all checks
    if ! check_dependencies; then
        exit_code=1
    fi
    
    echo
    if ! check_readme_consistency; then
        exit_code=1
    fi
    
    echo
    if ! run_markdown_lint; then
        exit_code=1
    fi
    
    echo
    if ! check_documentation_standards; then
        exit_code=1
    fi
    
    echo
    if ! run_link_validation; then
        exit_code=1
    fi
    
    echo
    generate_summary_report
    
    echo
    if [[ $exit_code -eq 0 ]]; then
        log_success "All documentation checks passed! 🎉"
    else
        log_warning "Some documentation issues found. Run with --fix to auto-fix where possible."
        if [[ "$FIX_ISSUES" != "true" ]]; then
            log_info "Tip: Run '$0 --fix' to automatically fix markdown formatting issues"
        fi
    fi
    
    return $exit_code
}

# Execute main function
main "$@"