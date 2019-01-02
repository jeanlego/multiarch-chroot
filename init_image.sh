#!/bin/bash
LC_ALL=C 
export DEBIAN_FRONTEND=noninteractive

apt-setup

echo "\
#------------------------------------------------------------------------------#
#                   OFFICIAL DEBIAN REPOS                    
#------------------------------------------------------------------------------#

###### Debian Main Repos
deb http://deb.debian.org/debian/ stable main contrib non-free
deb-src http://deb.debian.org/debian/ stable main contrib non-free

deb http://deb.debian.org/debian/ stable-updates main contrib non-free
deb-src http://deb.debian.org/debian/ stable-updates main contrib non-free

deb http://deb.debian.org/debian-security stable/updates main
deb-src http://deb.debian.org/debian-security stable/updates main

deb http://ftp.debian.org/debian stretch-backports main
deb-src http://ftp.debian.org/debian stretch-backports main
" > /etc/apt/sources.list

sed -i '/en_US.UTF-8/s/^#[[:space:]]*//g' /etc/locale.gen
cd /usr/share/i18n/charmaps
gzip -d UTF-8.gz
locale-gen
gzip UTF-8

apt-get update -qq
apt-get install -y \
    build-essential \
    git \
    cmake \
    automake \
    ditcc \
    llvm \
    clang \
    gcc \
    bison \
    flex \
    python \
    sed \
    wget \
    curl \
    vim

