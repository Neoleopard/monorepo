#!/bin/bash
# """
# Unix/Linux/OSX environment setup script for developer tooling monorepo.
# Handles installation and version management of core development tools including
# Python 3.11+, git 2.0.0+, and gcloud CLI. Features idempotent installations
# with version checking across different package managers (apt, brew, dnf).
# """
set -euo pipefail

# Version requirements
PYTHON_VERSION_REQUIRED="3.11"
MIN_GIT_VERSION="2.0.0"

# Logging functions
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

# Function to detect package manager
detect_pkg_manager() {
    if command -v brew >/dev/null; then
        echo "brew"
    elif command -v apt-get >/dev/null; then
        echo "apt"
    elif command -v dnf >/dev/null; then
        echo "dnf"
    else
        log_error "No supported package manager found (brew/apt-get/dnf)"
        exit 1
    fi
}

# Function to compare versions - returns 0 if ver1 >= ver2
version_compare() {
    local ver1=$1
    local ver2=$2
    
    if [[ "$ver1" == "$ver2" ]]; then
        return 0
    fi
    
    local IFS=.
    local i ver1=($ver1) ver2=($ver2)
    
    # Fill empty positions in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    
    for ((i=0; i<${#ver1[@]}; i++)); do
        # Fill empty positions in ver2 with zeros
        [[ -z ${ver2[i]} ]] && ver2[i]=0
        
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 0
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 1
        fi
    done
    return 0
}

# Function to extract version numbers more robustly
get_version_number() {
    local version_str=$1
    if [[ $version_str =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        log_error "Could not extract version number from: $version_str"
        exit 1
    fi
}

# Function to check Python version
check_python() {
    if command -v python3 >/dev/null; then
        local current_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
        if version_compare "$current_version" "$PYTHON_VERSION_REQUIRED"; then
            log_info "Python $current_version is already installed"
            return 1  # Already installed
        fi
    fi
    return 0  # Need to install
}

# Function to check Git version
check_git() {
    if command -v git >/dev/null; then
        local version_output=$(git --version)
        local current_version=$(get_version_number "$version_output")
        if version_compare "$current_version" "$MIN_GIT_VERSION"; then
            log_info "Git $current_version is already installed"
            return 1  # Already installed
        fi
    fi
    return 0  # Need to install
}

# Function to check gcloud
check_gcloud() {
    if command -v gcloud >/dev/null; then
        log_info "gcloud CLI is already installed"
        return 1  # Already installed
    fi
    return 0  # Need to install
}

# Function to run package manager commands with error handling
run_pkg_cmd() {
    local cmd="$1"
    local error_msg="$2"
    
    if ! eval "$cmd"; then
        log_error "$error_msg"
        exit 1
    fi
}

# Modified setup functions with improved error handling
setup_python() {
    if ! check_python; then
        return
    fi
    
    local pkg_manager=$(detect_pkg_manager)
    log_info "Installing Python..."
    case $pkg_manager in
        brew)
            run_pkg_cmd "brew install python@3.11" "Failed to install Python via brew"
            ;;
        apt)
            run_pkg_cmd "sudo add-apt-repository -y ppa:deadsnakes/ppa" "Failed to add Python PPA"
            run_pkg_cmd "sudo apt-get update" "Failed to update apt repositories"
            run_pkg_cmd "sudo apt-get install -y python3.11 python3.11-venv" "Failed to install Python"
            ;;
        dnf)
            run_pkg_cmd "sudo dnf install -y python3.11" "Failed to install Python via dnf"
            ;;
    esac
    
    # Verify installation
    if ! command -v python3 >/dev/null; then
        log_error "Python installation failed - python3 command not found"
        exit 1
    fi
}

setup_gcloud() {
    if ! check_gcloud; then
        return
    fi

    log_info "Installing gcloud CLI..."
    local pkg_manager=$(detect_pkg_manager)
    case $pkg_manager in
        brew)
            run_pkg_cmd "brew install --cask google-cloud-sdk" "Failed to install gcloud via brew"
            ;;
        apt)
            if [ ! -f /usr/share/keyrings/cloud.google.gpg ]; then
                run_pkg_cmd "curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -" "Failed to add Google Cloud public key"
                echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
            fi
            run_pkg_cmd "sudo apt-get update && sudo apt-get install -y google-cloud-sdk" "Failed to install gcloud"
            ;;
        *)
            log_error "Please install gcloud CLI manually from: https://cloud.google.com/sdk/docs/install"
            exit 1
            ;;
    esac
    
    # Verify installation
    if ! command -v gcloud >/dev/null; then
        log_error "gcloud installation failed - command not found"
        exit 1
    fi
}

setup_git() {
    if ! check_git; then
        return
    fi

    log_info "Installing git..."
    local pkg_manager=$(detect_pkg_manager)
    case $pkg_manager in
        brew)
            run_pkg_cmd "brew install git" "Failed to install git via brew"
            ;;
        apt)
            run_pkg_cmd "sudo apt-get install -y git" "Failed to install git via apt"
            ;;
        dnf)
            run_pkg_cmd "sudo dnf install -y git" "Failed to install git via dnf"
            ;;
    esac
    
    # Verify installation
    if ! command -v git >/dev/null; then
        log_error "Git installation failed - command not found"
        exit 1
    fi
}

# Main execution
main() {
    log_info "Starting development environment setup..."
    
    # Ensure we're running with necessary permissions
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi
    
    setup_python
    setup_git
    setup_gcloud
    
    log_info "Setup completed successfully"
}

main "$@"