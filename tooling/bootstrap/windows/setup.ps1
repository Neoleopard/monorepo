# For setup.ps1
<#
Windows environment setup script for developer tooling monorepo.
Manages installation of core development tools via Chocolatey including
Python 3.11+, git 2.0.0+, and gcloud CLI. Features idempotent installations
with version checking and administrative privilege validation.

Part of a larger developer tools ecosystem designed for rapid prototyping
and cross-platform development.

Created with Claude 3.5 (2024-01-02)
#>
# Version requirements
$PYTHON_VERSION_REQUIRED = "3.11"
$MIN_GIT_VERSION = "2.0.0"

function Test-AdminPrivileges {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-PythonVersion {
    try {
        $pythonVersion = (python --version 2>&1).Split(" ")[1]
        $currentVersion = [version]($pythonVersion -split '-')[0]
        $requiredVersion = [version]$PYTHON_VERSION_REQUIRED
        
        if ($currentVersion -ge $requiredVersion) {
            Write-Host "Python $pythonVersion is already installed"
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

function Test-GitVersion {
    try {
        $gitVersion = (git --version 2>&1).Split(" ")[2]
        $currentVersion = [version]($gitVersion -split '-')[0]
        $requiredVersion = [version]$MIN_GIT_VERSION
        
        if ($currentVersion -ge $requiredVersion) {
            Write-Host "Git $gitVersion is already installed and meets minimum version requirement ($MIN_GIT_VERSION)"
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

function Test-GCloudInstallation {
    try {
        $gcloudVersion = (gcloud --version 2>&1)[0]
        if ($gcloudVersion -match "Google Cloud SDK") {
            Write-Host "Google Cloud SDK is already installed"
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

function Install-ChocoPackageIfMissing {
    param (
        [string]$PackageName,
        [scriptblock]$VersionCheck
    )
    
    # First check if already installed with required version
    if (& $VersionCheck) {
        Write-Host "$PackageName is already installed with required version - skipping installation"
        return $true
    }

    Write-Host "Installing $PackageName..."
    try {
        $result = choco install -y $PackageName
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Chocolatey installation failed for $PackageName"
            return $false
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Verify installation
        if (-not (& $VersionCheck)) {
            Write-Error "Version check failed after installing $PackageName"
            return $false
        }
        return $true
    } catch {
        Write-Error ("Failed to install " + $PackageName + ": " + $_.Exception.Message)
        return $false
    }
}

# Main installation logic
if (-not (Test-AdminPrivileges)) {
    Write-Error "Please run this script as Administrator"
    exit 1
}

# Ensure Chocolatey is installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Install packages if needed
$success = $true
$success = $success -and (Install-ChocoPackageIfMissing "python311" ${function:Test-PythonVersion})
$success = $success -and (Install-ChocoPackageIfMissing "git" ${function:Test-GitVersion})
$success = $success -and (Install-ChocoPackageIfMissing "gcloudsdk" ${function:Test-GCloudInstallation})

if (-not $success) {
    Write-Error "One or more installations failed"
    exit 1
}

Write-Host "All installations completed successfully!"