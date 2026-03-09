FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV PIP_ROOT_USER_ACTION=ignore

WORKDIR /app
COPY requirements.txt .

RUN apt-get update && apt-get install -y --fix-missing \
    debian-archive-keyring \
    ca-certificates \
    build-essential \
    curl \
    cmake \
    gdb \
    git \
    htop \
    libgl1 \
    libopencv-dev \
    libxrender1 \
    nano \
    python3-opencv \
    screen \
    unzip \
    zip \
    wget \
    parallel \
    graphviz \
    imagemagick \
    clamav \
    clamav-daemon \
    && update-ca-certificates

RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN python -m venv $VIRTUAL_ENV && \
    pip install --no-cache-dir -r requirements.txt

RUN cd /opt && \
    wget https://releases.hashicorp.com/terraform/1.9.5/terraform_1.9.5_linux_amd64.zip && \
    unzip terraform_1.9.5_linux_amd64.zip && \
    mv terraform /usr/local/bin/
