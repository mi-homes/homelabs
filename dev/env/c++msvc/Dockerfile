# Dockerfile for Windows Server Core with Chocolatey, Python, Git, CMake, Visual Studio Build Tools, and other tools.
# Sets up a BitBucket runner environment with essential development tools to be used to build Atlas in CI/CD pipelines.

ARG FROM_IMAGE=mcr.microsoft.com/windows/servercore:ltsc2025
FROM ${FROM_IMAGE}

SHELL ["powershell.exe", "-ExecutionPolicy", "RemoteSigned", "-Command"]

ENV chocolateyUseWindowsCompression=false \
    PYTHONIOENCODING=UTF-8

# Install Chocolatey and essential tools
# Chocolatey is a package manager for Windows, similar to apt-get on Linux.
RUN iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')); \
    $env:Path += '";C:\tools\python3;C:\tools\python3\Scripts"'; \
    choco install --no-progress --yes git --version=2.50.1 --params '"/InstallDir:C:\tools\git"'; \
    choco install --no-progress --yes cmake --version=4.0.3 --params '"/InstallDir:C:\tools\cmake"' \
        --installargs 'ADD_CMAKE_TO_PATH=""System""'; \
    choco install --no-progress --yes python --version=3.13.5 --params '"/InstallDir:C:\tools\python3"'

RUN choco install --no-progress --yes --execution-timeout=0 nano --version=7.2.36.20230412

RUN choco install --no-progress --yes visualstudio2022buildtools --version=117.14.6 \
    --package-parameters "--norestart --wait --includeRecommended"
RUN choco install --no-progress --yes --execution-timeout=0 visualstudio2022-workload-nativedesktop --version=1.0.0 \
    --package-parameters "--norestart --wait --includeRecommended"
RUN choco install --no-progress --yes --execution-timeout=0 visualstudio2022-workload-vctools --version=1.0.0 \
    --package-parameters "--norestart --wait --includeRecommended"

RUN choco install --no-progress --yes --execution-timeout=0 ninja --version=1.13.0

RUN choco install --no-progress --yes --execution-timeout=0 nasm --version=2.16.3