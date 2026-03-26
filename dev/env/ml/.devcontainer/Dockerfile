FROM nvidia/cuda:12.3.2-runtime-ubuntu22.04

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive \
    VIRTUAL_ENV=/opt/venv \
    PIP_ROOT_USER_ACTION=ignore
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app
COPY requirements.txt .

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

RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=dialog

RUN python3 -m pip install --upgrade pip setuptools wheel
RUN python3 -m venv $VIRTUAL_ENV && \
    . $VIRTUAL_ENV/bin/activate && \
    pip install --no-cache-dir --trusted-host pypi.org --trusted-host files.pythonhosted.org -r requirements.txt

RUN ln -fs /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
