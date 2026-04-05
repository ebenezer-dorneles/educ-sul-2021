FROM rocker/r2u:26.04

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    openssl \
    r-cran-arrow \
    r-cran-duckdb \
    r-cran-dbi \
    && rm -rf /var/lib/apt/lists/*

# Adiciona certificado intermediário da RNP
RUN curl -o /usr/local/share/ca-certificates/rnp.crt \
    http://secure.globalsign.com/cacert/rnpicpedugr46ovtlsca2025.crt \
    && update-ca-certificates

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

WORKDIR /workspace
