#!/usr/bin/env python3
"""
Python dependency bootstrapper for developer tooling monorepo.
Installs and configures uv package manager, then uses it to manage Python dependencies.
Features cross-platform support, version checking, and automatic venv activation.

Part of a larger developer tools ecosystem designed for rapid prototyping
and cross-platform development.

Created with Claude 3.5 (2024-01-02)
"""

import os
import platform
import subprocess
import sys
import tempfile
from pathlib import Path
import logging
import shutil

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def check_uv_installation():
    """Check if uv is installed and accessible"""
    uv_path = shutil.which("uv")
    if uv_path:
        try:
            result = subprocess.run(["uv", "--version"], 
                                  capture_output=True, 
                                  text=True,
                                  check=True)
            logger.info(f"Found uv at {uv_path} (version: {result.stdout.strip()})")
            return True
        except subprocess.CalledProcessError:
            logger.warning("uv found but version check failed")
            return False
    return False

def get_uv_install_command():
    system = platform.system().lower()
    if system in ("linux", "darwin"):
        return "curl -LsSf https://astral.sh/uv/install.sh | sh"
    elif system == "windows":
        return "powershell -c \"(Invoke-WebRequest -Uri https://astral.sh/uv/install.ps1 -UseBasicParsing).Content | powershell -command -\""
    else:
        raise RuntimeError(f"Unsupported platform: {system}")

def ensure_uv_installed():
    """Install uv if not already present"""
    if check_uv_installation():
        logger.info("uv is already installed and working")
        return

    logger.info("Installing uv...")
    install_command = get_uv_install_command()
    
    try:
        subprocess.run(install_command, shell=True, check=True)
        if not check_uv_installation():
            raise RuntimeError("uv installation succeeded but verification failed")
        logger.info("uv installed successfully")
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to install uv: {e}")
        sys.exit(1)

def setup_venv(repo_root: Path):
    """Create virtual environment using uv"""
    venv_path = repo_root / "monorepo"
    
    if not venv_path.exists():
        logger.info("Creating virtual environment...")
        subprocess.run(["uv", "venv", "monorepo"], cwd=repo_root, check=True)
    else:
        logger.info("Virtual environment already exists")
    
    return venv_path

def get_activation_script(venv_path: Path) -> Path:
    """Get the appropriate activation script path based on platform"""
    system = platform.system().lower()
    if system == "windows":
        return venv_path / "Scripts" / "activate.bat"
    return venv_path / "bin" / "activate"

def activate_venv(venv_path: Path):
    """Activate the virtual environment in the current process"""
    activate_script = get_activation_script(venv_path)
    
    if not activate_script.exists():
        logger.error(f"Activation script not found: {activate_script}")
        sys.exit(1)
    
    # Modify environment variables to activate venv
    venv_bin = venv_path / ("Scripts" if platform.system().lower() == "windows" else "bin")
    os.environ["VIRTUAL_ENV"] = str(venv_path)
    os.environ["PATH"] = f"{venv_bin}{os.pathsep}{os.environ['PATH']}"
    sys.prefix = str(venv_path)
    
    logger.info(f"Activated virtual environment at {venv_path}")

def install_dependencies(repo_root: Path):
    """Install dependencies using uv"""
    requirements_file = repo_root / "requirements.txt"
    
    if not requirements_file.exists():
        logger.error("requirements.txt not found")
        sys.exit(1)
    
    logger.info("Installing dependencies with uv...")
    subprocess.run(["uv", "pip", "install", "-r", "requirements.txt"], cwd=repo_root, check=True)

def main():
    repo_root = Path(__file__).parent.parent.parent
    try:
        ensure_uv_installed()
        venv_path = setup_venv(repo_root)
        activate_venv(venv_path)
        install_dependencies(repo_root)
        logger.info("Python environment setup complete!")
        
        # Provide activation instructions for shell
        system = platform.system().lower()
        if system == "windows":
            logger.info("\nTo activate this environment in a new shell, run:\nmonorepo\\Scripts\\activate.bat")
        else:
            logger.info("\nTo activate this environment in a new shell, run:\nsource monorepo/bin/activate")
            
    except Exception as e:
        logger.error(f"Setup failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()