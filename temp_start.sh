ETC_PATH=/Users/Krittin/Code/sinonkt/docker-slurm-simulator/reg_testing/micro_cluster/etc
TRACES_PATH=/Users/Krittin/Code/sinonkt/docker-slurm-simulator/reg_testing/micro_cluster/traces
docker run --cap-add=SYS_ADMIN -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v $ETC_PATH:/opt/slurm/etc -v $TRACES_PATH:/traces dss &