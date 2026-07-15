FROM rocker/rstudio:4.4.2

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    openssl \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Adiciona certificado intermediário da RNP
RUN curl -o /usr/local/share/ca-certificates/rnp.crt \
    http://secure.globalsign.com/cacert/rnpicpedugr46ovtlsca2025.crt \
    && update-ca-certificates

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

# Pacotes R (instalados via CRAN, pois a imagem rocker/rstudio não usa o repositório r2u)
RUN install2.r --error --skipinstalled \
    arrow \
    duckdb \
    DBI

WORKDIR /workspace

# Faz o RStudio Server abrir /workspace (onde o projeto é montado) em vez de /home/rstudio
RUN echo "session-default-working-dir=/workspace" >> /etc/rstudio/rsession.conf \
    && echo "session-default-new-project-dir=/workspace" >> /etc/rstudio/rsession.conf