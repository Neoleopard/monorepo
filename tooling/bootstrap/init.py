#!/usr/bin/env python3
"""
Cross-platform environment bootstrapper for developer tooling monorepo.
Part of a larger developer tools ecosystem designed for rapid prototyping and exploration.
This script detects the operating system and runs appropriate setup scripts to install
and configure Python, gcloud CLI, git, and other development tools.

Key features:
- Cross-platform compatibility (Windows/OSX/Linux)
- Idempotent installations with version checking
- Comprehensive logging
- Error handling and validation

Created with Claude 3.5 (2024-01-02)
"""
import platform
import subprocess
import logging
import sys
from pathlib import Path
from dataclasses import dataclass
from typing import Optional

@dataclass
class ToolVersion:
    name: str
    current: Optional[str]
    required: str
    installed: bool = False

def setup_logging():
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler('bootstrap.log')
        ]
    )

def get_platform():
    system = platform.system().lower()
    if system in ("darwin", "linux"):
        return "unix"
    elif system == "windows":
        return "windows"
    else:
        raise RuntimeError(f"Unsupported platform: {system}")

def run_platform_script():
    platform_type = get_platform()
    script_dir = Path(__file__).parent
    
    logging.info(f"Detected platform: {platform_type}")
    
    try:
        if platform_type == "unix":
            script_path = script_dir / "unix" / "setup.sh"
            logging.info(f"Running Unix setup script: {script_path}")
            subprocess.run(["bash", str(script_path)], check=True)
        else:
            script_path = script_dir / "windows" / "setup.ps1"
            logging.info(f"Running Windows setup script: {script_path}")
            subprocess.run(["powershell", "-ExecutionPolicy", "Bypass", "-File", str(script_path)], check=True)
            
        logging.info("Setup completed successfully")
        
    except subprocess.CalledProcessError as e:
        logging.error(f"Setup failed with error code {e.returncode}")
        sys.exit(1)
    except Exception as e:
        logging.error(f"Unexpected error: {e}")
        sys.exit(1)

def run_python_bootstrap():
    """Run Python dependency bootstrapping"""
    script_dir = Path(__file__).parent
    bootstrap_script = script_dir / "python_bootstrap.py"
    
    logging.info("Setting up Python environment...")
    try:
        subprocess.run([sys.executable, str(bootstrap_script)], check=True)
    except subprocess.CalledProcessError as e:
        logging.error(f"Python bootstrap failed with error code {e.returncode}")
        sys.exit(1)

def main():
    setup_logging()
    
    try:
        # First run platform-specific setup
        run_platform_script()
        
        # Then setup Python environment
        run_python_bootstrap()
        
        logging.info("Setup completed successfully!")
    except Exception as e:
        logging.error(f"Setup failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()