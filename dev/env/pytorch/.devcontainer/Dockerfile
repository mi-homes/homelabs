# For more information, please refer to https://aka.ms/vscode-docker-python
FROM nvcr.io/nvidia/pytorch:24.06-py3

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

# Set environment variable to noninteractive to avoid getting stuck
ENV DEBIAN_FRONTEND=noninteractive

# We can replace virtualenv's 'activate' by setting the appropriate environment variables: 
# Docker’s ENV command applies both subsequent RUNs as well as to the CMD. PATH is searched for commands.
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV PIP_ROOT_USER_ACTION=ignore

WORKDIR /app
COPY ./requirements.txt .

# Install system dependencies
RUN apt-get update && \
    apt-get install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update && apt-get install -y --fix-missing \
    python3 python3-dev python3-venv python3-pip \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    gdb \
    git \
    htop \
    libopencv-dev \
    libxrender1 \
    nano \
    python3-opencv \
    screen \
    unzip \
    wget \
    ffmpeg \
    parallel \
    && update-ca-certificates

# Clean up cache to reduce image size
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Reset the environment variable for the rest of the build
ENV DEBIAN_FRONTEND=dialog

# Install Python packages
RUN python3 -m pip install --upgrade pip setuptools wheel
RUN python3 -m venv $VIRTUAL_ENV && \
    . $VIRTUAL_ENV/bin/activate && \
    pip install --no-cache-dir --trusted-host pypi.org --trusted-host files.pythonhosted.org -r requirements.txt

# Set timezone
RUN ln -fs /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime

# Creates a non-root user with an explicit UID and adds permission to access the /app folder
# For more info, please refer to https://aka.ms/vscode-docker-python-configure-containers
# RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app/src
# USER appuser

# During debugging, this entry point will be overridden. For more information, 
# please refer to https://aka.ms/vscode-docker-python-debug
# CMD ["python", "/app/src/ct/app.py"]
