cluster=$(get_slurm_conf --config slurm.conf --parameter ClusterName)

echo "ClusterName:$cluster"
process_sinfo --sinfo sinfo.out -c micro
process_squeue --squeue squeue.out --cluster $cluster
