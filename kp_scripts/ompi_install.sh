#!/bin/bash

# Stop at first failure
set -e

# Get OpenMPI cloned with our desired tag checked out
git clone -b $OMPI_TAG https://github.com/open-mpi/ompi.git
cd ompi 

# Configure and install
export AUTOMAKE_JOBS=`nproc` 
./autogen.pl 
./configure --prefix=/usr/local 
make -j `nproc` all 
make install 

# Keep source out of this layer
cd ..
rm -rf ompi