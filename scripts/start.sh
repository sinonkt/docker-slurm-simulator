PROJECT_DIR=/Users/Krittin/Code/sinonkt/docker-slurm-simulator/
ETC_PATH=${PROJECT_DIR}/test/etc
TRACES_PATH=${PROJECT_DIR}/test/traces
LOG_PATH=${PROJECT_DIR}/logs

docker run --cap-add=SYS_ADMIN \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v $LOG_PATH:/var/log/slurm \
  -v $ETC_PATH:/slurm/etc \
  -v $TRACES_PATH:/traces sinonkt/docker-slurm-simulator:latest &