#!/usr/bin/env bash
# Entry point setup script for developer tooling monorepo.
# Handles initial environment bootstrap and Python virtual environment activation.
# Part of a larger developer tools ecosystem designed for rapid prototyping
# and cross-platform development.
#
# Key features:
# - Runs initial bootstrap/init.py for environment setup
# - Activates Python virtual environment
# - Validates successful environment configuration
# - Adds monorepo root to PYTHONPATH
# - Provides clear error messaging and status updates
#
# USAGE:
#   source setup.sh
#   # or
#   . setup.sh
#
# NOTE: This script must be sourced, not executed, to persist the
# virtual environment activation in your shell session.
#
# Created with Claude 3.5 (2024-01-02)

# Check if the script is being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script must be sourced, not executed."
    echo "Usage: source setup.sh"
    echo "   or: . setup.sh"
    exit 1
fi

# Script location for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/monorepo"

# Color output helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[setup.sh]${NC} $1"
}

error() {
    echo -e "${RED}[error]${NC} $1" >&2
    return 1
}

# Check Python availability
if ! command -v python3 &> /dev/null; then
    error "Python 3 is required but not found in PATH"
    return 1
fi

# Run bootstrap script
log "Running bootstrap initialization..."
if ! python3 "${SCRIPT_DIR}/tooling/bootstrap/init.py"; then
    error "Bootstrap initialization failed"
    return 1
fi

# Ensure virtual environment exists
if [ ! -d "${VENV_DIR}" ]; then
    error "Virtual environment not found at ${VENV_DIR} after bootstrap"
    return 1
fi

# Activate virtual environment
log "Activating virtual environment..."
# shellcheck source=/dev/null
if ! source "${VENV_DIR}/bin/activate"; then
    error "Failed to activate virtual environment"
    return 1
fi

# Verify activation
if [ -z "${VIRTUAL_ENV:-}" ]; then
    error "Virtual environment activation failed"
    return 1
fi

log "Setup complete! Virtual environment is active."
log "You can now run development tools from the monorepo"

# Export PYTHONPATH if needed for monorepo modules
export PYTHONPATH="${SCRIPT_DIR}:${PYTHONPATH:-}"