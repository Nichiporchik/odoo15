# This file based on https://github.com/odoo/docker/blob/master/14.0/Dockerfile
FROM debian:buster-slim

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl-dev \
        node-less \
        npm \
        python3-num2words \
        python3-pdfminer \
        python3-pip \
        python3-phonenumbers \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-setuptools \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        xz-utils \
        # Dependencies for building odoo
        build-essential \
        python3-dev \
        libxml2-dev \
        libxslt1-dev \
        libldap2-dev \
        libsasl2-dev \
        # Advanced reports \
        libreoffice \
        fonts-freefont-ttf \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb \
    && echo 'ea8277df4297afc507c61122f3c349af142f31e5 wkhtmltox.deb' | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# install latest postgresql-client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update  \
    && apt-get install --no-install-recommends -y postgresql-client \
    && rm -f /etc/apt/sources.list.d/pgdg.list \
    && rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian buster)
RUN npm install -g rtlcss

# Create app user & folders
RUN useradd --create-home --home-dir /opt/odoo --no-log-init odoo

# Expose Odoo services
EXPOSE 8069 8072
# Set the default config file
ENV ODOO_RC /opt/odoo/odoo.conf
# Set the default odoo paths
ENV ODOO_CMD "/opt/odoo/odoo/odoo-bin"

RUN pip3 install --upgrade pip
# Odoo requirements
COPY odoo-src/odoo/requirements.txt /requirements_odoo.txt
RUN pip3 install --no-cache-dir wheel -r /requirements_odoo.txt \
    && rm -rf requirements_odoo.txt
# Advanced development features
RUN pip3 install --no-cache-dir coverage wdb odoo_test_helper mock
# Custom addons requirements
COPY addons/*/requirements.txt /requirements_addons.txt
RUN pip3 install --no-cache-dir -r /requirements_addons.txt \
    && rm -rf requirements*.txt

# Copy running scripts
COPY ./wait-for-psql.py /usr/local/bin/wait-for-psql.py
COPY ./entrypoint.sh /

USER odoo
RUN /bin/bash -c "mkdir -p /opt/odoo/{data,addons}"
# Copy default configuration
COPY ./odoo.conf /opt/odoo/odoo.conf
WORKDIR /opt/odoo
VOLUME ["/opt/odoo/data"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
