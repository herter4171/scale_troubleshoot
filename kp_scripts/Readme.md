# kp_scripts
This directory contains scripts used to drive the Docker image build, so simply modify them to change the behavior.  In order of use, we have
* [yum_installs.sh](yum_installs.sh) to install dependencies from the system package manager
* [ompi_install.sh](ompi_install.sh) builds and installs OpenMPI with the tag defined in [Dockerfile](../Dockerfile)
* [scale_install.sh](scale_install.sh) builds and installs SCALE
    * If SCALE source is in a Git repo, replace `URL` at the end of the `git clone` line with your actual URL sans `https://`
    * Otherwise, add a `COPY` directive to [Dockerfile](../Dockerfile), and remove the `git clone` line entirely
    * To have the SCALE source and build artifacts in the resulting image, comment out the `rm` command at the bottom