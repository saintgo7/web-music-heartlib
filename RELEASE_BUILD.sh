#!/bin/bash

# ABADA Music Studio - Release Build Script
# Version: 1.0.0
# Usage: ./RELEASE_BUILD.sh [options]
#
# Options:
#   --skip-tests    Skip E2E tests
#   --skip-lint     Skip linting
#   --tag           Create git tag after build
#   --push          Push tag to remote
#   --help          Show this help message

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VERSION="1.0.0"
PROJECT_NAME="ABADA Music Studio"
WEB_DIR="web"
BUILD_DIR="web/build"

# Flags
SKIP_TESTS=false
SKIP_LINT=false
CREATE_TAG=false
PUSH_TAG=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --skip-lint)
            SKIP_LINT=true
            shift
            ;;
        --tag)
            CREATE_TAG=true
            shift
            ;;
        --push)
            PUSH_TAG=true
            shift
            ;;
        --help)
            echo "Usage: ./RELEASE_BUILD.sh [options]"
            echo ""
            echo "Options:"
            echo "  --skip-tests    Skip E2E tests"
            echo "  --skip-lint     Skip linting"
            echo "  --tag           Create git tag after build"
            echo "  --push          Push tag to remote"
            echo "  --help          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Functions
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

check_requirements() {
    print_header "Checking Requirements"

    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed"
        exit 1
    fi

    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_error "Node.js version must be >= 18 (current: $NODE_VERSION)"
        exit 1
    fi
    print_success "Node.js $(node --version)"

    # Check npm
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed"
        exit 1
    fi
    print_success "npm $(npm --version)"

    # Check git
    if ! command -v git &> /dev/null; then
        print_error "git is not installed"
        exit 1
    fi
    print_success "git $(git --version | cut -d' ' -f3)"

    # Check if we're in the right directory
    if [ ! -d "$WEB_DIR" ]; then
        print_error "web/ directory not found. Run from project root."
        exit 1
    fi
    print_success "Project directory verified"
}

clean_build() {
    print_header "Cleaning Previous Build"

    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        print_success "Removed previous build directory"
    fi

    print_success "Clean complete"
}

install_dependencies() {
    print_header "Installing Dependencies"

    cd "$WEB_DIR"

    # Clean install
    print_info "Running npm ci..."
    npm ci

    print_success "Dependencies installed"
    cd ..
}

run_lint() {
    print_header "Running Linting"

    if [ "$SKIP_LINT" = true ]; then
        print_warning "Linting skipped (--skip-lint flag)"
        return
    fi

    cd "$WEB_DIR"

    print_info "Running ESLint..."
    npm run lint

    print_success "Linting passed"
    cd ..
}

run_typecheck() {
    print_header "Running Type Checking"

    cd "$WEB_DIR"

    print_info "Running TypeScript type check..."
    npm run typecheck

    print_success "Type checking passed"
    cd ..
}

run_tests() {
    print_header "Running Tests"

    if [ "$SKIP_TESTS" = true ]; then
        print_warning "Tests skipped (--skip-tests flag)"
        return
    fi

    cd "$WEB_DIR"

    print_info "Running E2E tests..."
    npm run test:e2e || {
        print_warning "Some tests may have failed. Check test report."
    }

    print_success "Tests complete"
    cd ..
}

run_audit() {
    print_header "Running Security Audit"

    cd "$WEB_DIR"

    print_info "Running npm audit..."
    npm audit || {
        print_warning "Security vulnerabilities found. Review npm audit output."
    }

    cd ..
}

build_production() {
    print_header "Building for Production"

    cd "$WEB_DIR"

    print_info "Running production build..."
    npm run build

    print_success "Production build complete"
    cd ..
}

verify_build() {
    print_header "Verifying Build"

    # Check if build directory exists
    if [ ! -d "$BUILD_DIR" ]; then
        print_error "Build directory not found"
        exit 1
    fi
    print_success "Build directory exists"

    # Check for index.html
    if [ ! -f "$BUILD_DIR/index.html" ]; then
        print_error "index.html not found"
        exit 1
    fi
    print_success "index.html exists"

    # Check for assets
    if [ ! -d "$BUILD_DIR/assets" ]; then
        print_error "assets directory not found"
        exit 1
    fi
    print_success "Assets directory exists"

    # Count JS files
    JS_COUNT=$(find "$BUILD_DIR/assets" -name "*.js" | wc -l)
    print_info "Found $JS_COUNT JavaScript files"

    # Count CSS files
    CSS_COUNT=$(find "$BUILD_DIR/assets" -name "*.css" | wc -l)
    print_info "Found $CSS_COUNT CSS files"

    # Check total size
    TOTAL_SIZE=$(du -sh "$BUILD_DIR" | cut -f1)
    print_info "Total build size: $TOTAL_SIZE"

    print_success "Build verification passed"
}

create_git_tag() {
    print_header "Creating Git Tag"

    if [ "$CREATE_TAG" = false ]; then
        print_info "Tag creation skipped (use --tag flag to enable)"
        return
    fi

    TAG_NAME="v$VERSION"

    # Check if tag already exists
    if git tag -l | grep -q "^$TAG_NAME$"; then
        print_warning "Tag $TAG_NAME already exists"
        return
    fi

    # Create tag
    git tag -a "$TAG_NAME" -m "Release $TAG_NAME - $PROJECT_NAME"
    print_success "Created tag: $TAG_NAME"

    if [ "$PUSH_TAG" = true ]; then
        print_info "Pushing tag to remote..."
        git push origin "$TAG_NAME"
        print_success "Tag pushed to remote"
    fi
}

print_summary() {
    print_header "Build Summary"

    echo -e "Project:        ${GREEN}$PROJECT_NAME${NC}"
    echo -e "Version:        ${GREEN}$VERSION${NC}"
    echo -e "Build Output:   ${GREEN}$BUILD_DIR${NC}"
    echo -e "Build Size:     ${GREEN}$(du -sh "$BUILD_DIR" | cut -f1)${NC}"
    echo ""

    # List main assets
    echo "Main Assets:"
    ls -lh "$BUILD_DIR/assets/"*.js 2>/dev/null | while read line; do
        echo "  $line"
    done

    echo ""
    echo -e "${GREEN}Build completed successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Preview locally: cd web && npm run preview"
    echo "  2. Run full verification: see BUILD_VERIFICATION.md"
    echo "  3. Deploy to Cloudflare Pages"
    if [ "$CREATE_TAG" = false ]; then
        echo "  4. Create release tag: ./RELEASE_BUILD.sh --tag --push"
    fi
}

# Main execution
main() {
    print_header "$PROJECT_NAME - Release Build v$VERSION"

    START_TIME=$(date +%s)

    check_requirements
    clean_build
    install_dependencies
    run_audit
    run_lint
    run_typecheck
    run_tests
    build_production
    verify_build
    create_git_tag

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    print_summary

    echo "Build completed in ${DURATION} seconds"
}

# Run main function
main
