FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3.11 \
    python3.11-dev \
    python3-pip \
    build-essential \
    curl \
    git \
    htop \
    ca-certificates \
    wget \
    bzip2 \
    bash \
    && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

RUN curl -fsSL https://pixi.sh/install.sh -o /tmp/pixi-install.sh && \
    bash /tmp/pixi-install.sh && \
    rm /tmp/pixi-install.sh

ENV PATH="/root/.pixi/bin:${PATH}"

RUN which pixi && pixi --version

WORKDIR /opt/mojo-env

RUN pixi init -c https://conda.modular.com/max-nightly/ -c conda-forge && \
    pixi add mojo && \
    pixi install --verbose

ENV PATH="/opt/mojo-env/.pixi/bin:/opt/mojo-env/.pixi/envs/default/bin:${PATH}"
ENV MODULAR_HOME="/opt/mojo-env/.pixi/envs/default/share/max"

RUN mojo --version

WORKDIR /workspace

