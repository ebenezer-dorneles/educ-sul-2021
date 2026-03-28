FROM rocker/r2u:26.04

RUN apt-get update && apt-get install -y \
    r-cran-arrow \
    r-cran-duckdb \
    r-cran-dbi \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace