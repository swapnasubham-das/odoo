# Dockerfile to build and run this Odoo source tree (Odoo 19.0)
FROM python:3.12-slim-bookworm

LABEL maintainer="Odoo"

ENV LANG=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive

# System dependencies needed to build/run Odoo's python requirements
# (psycopg2, lxml, Pillow, gevent, libsass, cryptography, python-ldap, ...),
# render PDF reports (wkhtmltopdf) and convert CSS for RTL languages (rtlcss).
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        fonts-dejavu-core \
        fonts-freefont-ttf \
        fonts-inconsolata \
        gsfonts \
        libffi-dev \
        libjpeg-dev \
        libldap2-dev \
        libpq-dev \
        libsasl2-dev \
        libssl-dev \
        libxml2-dev \
        libxslt1-dev \
        nodejs \
        npm \
        postgresql-client \
        wkhtmltopdf \
        xfonts-75dpi \
        xfonts-base \
        zlib1g-dev \
    ; \
    npm install -g rtlcss; \
    rm -rf /var/lib/apt/lists/*

# Create the odoo system user and required directories
RUN adduser --system --home=/var/lib/odoo --group odoo \
    && mkdir -p /var/lib/odoo /etc/odoo /odoo \
    && chown -R odoo:odoo /var/lib/odoo /etc/odoo

WORKDIR /odoo

# Install python dependencies first to leverage Docker layer caching
COPY requirements.txt /odoo/requirements.txt
RUN pip install --no-cache-dir --upgrade pip wheel setuptools \
    && pip install --no-cache-dir -r requirements.txt

# Copy the Odoo source code (core + addons) into the image.
# CACHEBUST forces this layer (and everything after it) to be re-evaluated on
# every build, so source/config edits are never served from a stale cache.
ARG CACHEBUST=1
COPY . /odoo

COPY docker/odoo.conf /etc/odoo/odoo.conf
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /odoo/odoo-bin \
    && chown -R odoo:odoo /odoo /etc/odoo/odoo.conf

USER odoo

EXPOSE 8069 8072

VOLUME ["/var/lib/odoo"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
