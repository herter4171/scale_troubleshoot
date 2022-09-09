# scale_troubleshoot_ornl
This repository contains the generic instructions to build SCALE from source with MPI enabled in a Docker image based on Amazon Linux 2 with some common tooling installed.

# Image Building
What can't be encapsulated here is how to load the source into the image, and there are two options.

1. Specify a URL in place of `URL` in [Dockerfile](Dockerfile) and supply build arguments to allow cloning
    ```
    docker build \
        --build-arg GHE_CREDS_USR=username \
        --build-arg GHE_CREDS_PSW=password \
        -t scale_mpi .
    ```
1. Replace cloning with a `COPY` directive directly above where SCALE source gets loaded in similar to the following, then use the build command above with the `--build-arg` portions absent.
    ```
    COPY [path to scale source directory] $SCALE_SRC
    ```
    > NOTE: Using `COPY` should only be used for testing, because it will cache the source in an image layer even if it's "deleted" in a subsequent layer.  Cloning and removing source in a single `RUN` directive ensures that the image won't have source code embedded in its layers.

# Image Use
For our SCALE image named `scale_mpi`, to get a shell in, you need to specify
1. Mapping in the SCALE data (outer path on left and in-container on the right)
1. Mapping in where the files to run are
1. Specifying your working directory the same as where files are
1. Ensure MPI has enough shared memory, since Docker defaults to 64 MB

The command should look similar to the following with the items above given in order.
```
docker run -ti \
    -v /scale/SCALE_DATA/data:/scale_data \
    -v `pwd`/test:/root/run \
    -w /root/run \
    --shm-size="4g" \
    scale_mpi
```

Once you have your shell in, you are `root` by default, which is fine for testing.  Just run your test input like so.
```
mpiexec --allow-run-as-root scalerte [input]
```

Once you are done testing, you will want to `chown -R` your working directory to match your external UID and GID so that your permissions are how they should be again.  Assuming your inputs were created external to the container, the following will do the trick.
```
chown -R `ls -lan *.inp | head -n 1 | awk '{print $3":"$4}'` .
```

## Notes and Current Status
When you launch a container with the image you just built, either put no arguments after the image name or `/bin/bash -l`.  For some reason SCALE only works with a login shell (perhaps due to SSHD not running otherwise?), which is the default for the given base image.  How we are building and installing has worked outside of Docker since day one on instances with the same OS, compilers, package version, and procedures from the top down.

Currently, it runs our sample model that can't be shared due to company IP for about a half hour without running out of memory RAM, or disk, and the test problem from support crashes after running for a bit in the same manner.  Neither crash when `mpiexec` is not used, and our `scalerte` doesn't seem to invoke MPI based on running single core when it's not prepended.  Controlling core count only works with `mpiexec -np [cores]`, and the `-N` flag for `scalerte` does not impact process count.

The main constraint to trying things out is that the Qt and OpenMPI dependencies lag behind what's available via package manager on a recent Linux distro, and building them from source has been an endless rabbit hole.  OpenMPI encourages using external dependencies to avoid pitfalls, but its dependencies are too recent for SCALE.  MPICH 3.3 was also tried, but in spite of us running Docker images for codes built on MPICh for years, it failed after half hour as well.

Bumping up the size of `/dev/shm` from the default of 64 MB via ` docker run --shm-size="4g"` followed by 8 GB did not help, but it should likely be specified.

<!-- TODO: SHARE NON DOCKER RESULT -->

### Representative Error Output
The `*.msg` file and `*.out` file do not contain any error messages.  All we are getting is a non-zero exit, and the following printed to the terminal.
```
--------------------------------------------------------------------------
mpiexec has exited due to process rank 0 with PID 0 on
node cb99fdf2eb81 exiting improperly. There are three reasons this could occur:

1. this process did not call "init" before exiting, but others in
the job did. This can cause a job to hang indefinitely while it waits
for all processes to call "init". By rule, if one process calls "init",
then ALL processes must call "init" prior to termination.

2. this process called "init", but exited without calling "finalize".
By rule, all processes that call "init" MUST call "finalize" prior to
exiting or it will be considered an "abnormal termination"

3. this process called "MPI_Abort" or "orte_abort" and the mca parameter
orte_create_session_dirs is set to false. In this case, the run-time cannot
detect that the abort call was an abnormal termination. Hence, the only
error message you will receive is this one.

This may have caused other processes in the application to be
terminated by signals sent by mpiexec (as reported here).

You can avoid this message by specifying -quiet on the mpiexec command line.
--------------------------------------------------------------------------
```