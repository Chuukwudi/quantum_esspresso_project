FROM mcr.microsoft.com/devcontainers/python:3.12-bullseye

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TEXTRACT_CACHE_URI=s3://textractor-cache/

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
    tree \
    htop \
    gnupg \
    software-properties-common \
    lsb-release && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and install AWS CLI v2 with architecture detection
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        AWSCLI_ARCH="x86_64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        AWSCLI_ARCH="aarch64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWSCLI_ARCH}.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update && \
    rm -rf awscliv2.zip aws/

    
# Install latest Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    apt-get install -y terraform && \
    terraform -install-autocomplete || true && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Uninstall any Python in /usr/bin/python* so that the Pytho in /usr/local/bin/python3 is used by default
RUN rm -f /usr/bin/python* || true

# Copy requirements files and install dependencies in a single layer
COPY requirements.txt flytta_toolbox-0.0.4-py3-none-any.whl ./
RUN pip3 install --no-cache-dir -r requirements.txt && \
    pip3 install --no-cache-dir flytta_toolbox-0.0.4-py3-none-any.whl && \
    pip3 install --no-cache-dir ipykernel jupyter && \
    rm requirements.txt flytta_toolbox-0.0.4-py3-none-any.whl

# Install Python code quality tools and set up jurn completion
RUN pip3 install --no-cache-dir isort black jurn && \
    echo 'eval "$(_JURN_COMPLETE=bash_source jurn)"' >> ~/.bashrc

# Define default command
CMD ["bash"]