#!/bin/bash

# Stop at first failure
set -e

# Clone SCALE source repository using given credentials
# Per docs, update URL to actual sans "https://" or use 
# a COPY directive in ../Dockerfile and remove the "git clone"
git clone https://${GHE_CREDS_USR}:${GHE_CREDS_PSW}@URL 
mkdir -p $SCALE_BLD_DIR 
cd $SCALE_BLD_DIR 

# Set paths in config shell script, and run configuration steps
# NOTE: Anasazi ASSERT_DEFINED lines are commented out in KP SCALE source repo
cp ../../script/$SCALE_CFG_SH . 
chmod u+x $SCALE_CFG_SH 
sed -i 's|^LAPACK=.*$|LAPACK=/usr/lib64/|g' $SCALE_CFG_SH 
sed -i 's|^MPI=.*$|MPI=/usr/local|g' $SCALE_CFG_SH 
./$SCALE_CFG_SH ../.. --install-prefix /usr/local

# Build and install
make -j `nproc`  
make install

# Clean up source to prevent caching in this layer
cd /opt 
rm -rf $SCALE_SRC