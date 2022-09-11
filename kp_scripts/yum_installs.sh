#!/bin/bash

# Stop at first failure
set -e

amazon-linux-extras install -y java-openjdk11
amazon-linux-extras enable java-openjdk11
        
yum install -y \
blas \
blas-devel \
lapack \
lapack-devel \
libtool-ltdl-devel \
qt \
qt-devel
