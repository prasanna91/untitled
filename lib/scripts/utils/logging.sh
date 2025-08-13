#!/bin/bash

# 🚀 Logging Utility Script for Codemagic Builds
# Provides consistent logging functions across all build scripts

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ SUCCESS:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}❌ ERROR:${NC} $1"
}

log_step() {
    echo -e "${CYAN}🔧 STEP:${NC} $1"
}

log_section() {
    echo -e "${PURPLE}📋 SECTION:${NC} $1"
    echo "=================================="
}

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    log_error "Build failed at line $line_number with exit code $exit_code"
    exit $exit_code
}

# Set error handling
set -euo pipefail
trap 'handle_error $LINENO' ERR

# Export functions for use in other scripts
export -f log_info log_success log_warning log_error log_step log_section
