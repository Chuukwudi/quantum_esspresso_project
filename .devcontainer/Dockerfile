FROM mcr.microsoft.com/devcontainers/python:3.12-bullseye

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive 

# Working directory will be set by the Docker Compose configuration
# to /workspaces/${localWorkspaceFolderBasename}

# Update and install dependencies, clean up in the same layer
RUN apt-get update && \
    apt-get install -y \
    zip \
    unzip \
    curl \
    git \
    build-essential \
    quantum-espresso \
    wannier90 \
    tree \
    htop \
    gnupg \
    software-properties-common \
    lsb-release && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Uninstall any Python in /usr/bin/python* so that the Pytho in /usr/local/bin/python3 is used by default
RUN rm -f /usr/bin/python* || true

# Copy requirements files and install dependencies in a single layer
COPY requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt && \
    pip3 install --no-cache-dir ipykernel jupyter && \
    rm requirements.txt

# Define default command
CMD ["bash"]
