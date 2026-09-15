#!/bin/sh
# Module: use a nearby Debian mirror for bootstrap package installation.
# Debian Release files are signature-verified by APT, including over HTTP.

# Aliyun's Asia CDN has proved substantially faster for package archives than
# the Japanese Debian mirror on the deployment route. Override either variable
# in a client's .env if its server has a better local mirror.
APT_MIRROR="${APT_MIRROR:-https://mirrors.aliyun.com/debian}"
APT_SECURITY_MIRROR="${APT_SECURITY_MIRROR:-https://mirrors.aliyun.com/debian-security}"

if ! command -v apt-get >/dev/null 2>&1; then
    exit 0
fi

if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    sed -i \
        -e "s|http://deb.debian.org/debian-security|$APT_SECURITY_MIRROR|g" \
        -e "s|http://deb.debian.org/debian|$APT_MIRROR|g" \
        -e "s|http://security.debian.org/debian-security|$APT_SECURITY_MIRROR|g" \
        /etc/apt/sources.list.d/debian.sources
fi

if [ -f /etc/apt/sources.list ]; then
    sed -i \
        -e "s|http://deb.debian.org/debian-security|$APT_SECURITY_MIRROR|g" \
        -e "s|http://deb.debian.org/debian|$APT_MIRROR|g" \
        -e "s|http://security.debian.org/debian-security|$APT_SECURITY_MIRROR|g" \
        /etc/apt/sources.list
fi
