FROM harbor.kairospower.com/core-design/amazonlinux-base:ssh

# Top-level directory for our builds
WORKDIR /opt

# Copy shell scripts
COPY kp_scripts kp_scripts

# Install packages needed to build things
RUN /bin/bash kp_scripts/yum_installs.sh

# Build and install OpenMPI using provided tag
ARG OMPI_TAG=v2.1.6
RUN /bin/bash kp_scripts/ompi_install.sh

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

# Either use args above and replace "URL" with a Git server, a COPY directive 
# to populate the source folder instead of a "git clone"
RUN /bin/bash kp_scripts/scale_install.sh