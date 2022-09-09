# TODO: Put a base image on Docker Hub
FROM harbor.kairospower.com/core-design/amazonlinux-base:ssh

# Specify OpenMPI version and that we're building in /opt
ARG OMPI_TAG=v2.1.6
WORKDIR /opt

# Copy shell scripts and cluster directory owned by dev for multi-node
COPY kp_scripts kp_scripts
COPY --chown=dev:dev cluster /opt/cluster

# Install packages needed to build things
RUN /bin/bash kp_scripts/yum_installs.sh

# Clone OpenMPI
RUN git clone -b $OMPI_TAG https://github.com/open-mpi/ompi.git ; \
cd ompi ; \
# Configure and install
export AUTOMAKE_JOBS=`nproc` ; \
./autogen.pl ; \
./configure --prefix=/usr/local ; \
make -j `nproc` all ; \
make install ; \
# Keep source out of this layer
cd /opt ; \
rm -rf ompi

# Specify MPI compilers, SCALE data directory, and misc paths for building
ENV CC=mpicc \
CXX=mpicxx \
F90=mpif90 \
DATA=/scale_data \
SCALE_SRC=/opt/scale_source \
SCALE_CFG_SH=configure_scale_mpi.sh
ENV SCALE_BLD_DIR=${SCALE_SRC}/build/gcc

# Credentials to clone the SCALE source repo from GHE
ARG GHE_CREDS_USR \
GHE_CREDS_PSW

# Clone SCALE source, and go to newly established build directory
# Either use args and replace "URL" with a Git server, or use a COPY directive to populate the source folder
# NOTE: Anasazi ASSERT_DEFINED lines are commented out in KP SCALE source repo
RUN git clone https://${GHE_CREDS_USR}:${GHE_CREDS_PSW}@URL ; \
mkdir -p $SCALE_BLD_DIR ; \
cd $SCALE_BLD_DIR ; \
# Set paths in config shell script, and run configuration steps
cp ../../script/$SCALE_CFG_SH . ; \
chmod u+x $SCALE_CFG_SH ; \
sed -i 's|^LAPACK=.*$|LAPACK=/usr/lib64/|g' $SCALE_CFG_SH ; \
sed -i 's|^MPI=.*$|MPI=/usr/local|g' $SCALE_CFG_SH ; \
./$SCALE_CFG_SH ../.. --install-prefix /usr/local ; \
# Build and install
make -j `nproc` ; \ 
make install ; \
# Clean up source to prevent caching in this layer
cd /opt ; \
rm -rf $SCALE_SRC