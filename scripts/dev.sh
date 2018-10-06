DEV_HOME=/home/dev/Code
DEV_IMAGE=sinonkt/docker-centos7-singularity-nextflow:singularity-2.6.0

# docker run -it --privileged $DEV_IMAGE 
#   -u root \ 
docker run -it --cap-add=SYS_ADMIN \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v $(pwd):$DEV_HOME $DEV_IMAGE /bin/bash