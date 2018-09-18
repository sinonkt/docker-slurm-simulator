#!/bin/bash

# This script populates the slurmdb with "users" that submit jobs

# populating SlurmDB using Slurm sacctmgr utility
#export SLURM_CONF=/home/slurm/slurm_sim_ws/sim/micro/baseline/etc/slurm.conf
#SACCTMGR=/home/slurm/slurm_sim_ws/slurm_opt/bin/sacctmgr
mysql -e "create user 'slurm'@'localhost' identified by 'slurm';"
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'slurm'@'localhost' IDENTIFIED BY 'slurm';"

slurmdbd -Dvvv &
# add QOS
sacctmgr -i modify QOS set normal Priority=0
sacctmgr -i add QOS Name=supporters Priority=100

# add cluster
sacctmgr -i add cluster Name=micro Fairshare=1 QOS=normal,supporters

# add accounts
sacctmgr -i add account name=account1 Fairshare=100
sacctmgr -i add account name=account2 Fairshare=100

# add users
sacctmgr -i add user name=user1 DefaultAccount=account1 MaxSubmitJobs=1000
sacctmgr -i add user name=user2 DefaultAccount=account1 MaxSubmitJobs=1000
sacctmgr -i add user name=user3 DefaultAccount=account1 MaxSubmitJobs=1000
sacctmgr -i add user name=user4 DefaultAccount=account2 MaxSubmitJobs=1000
sacctmgr -i add user name=user5 DefaultAccount=account2 MaxSubmitJobs=1000

sacctmgr -i modify user set qoslevel="normal,supporters"

#unset SLURM_CONF
