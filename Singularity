Bootstrap: docker

From: centos:7

%labels
    maintainer="oatkrittin@gmail.com"

%files
    default/sim.conf /default/sim.conf
    default/slurm.conf /default/slurm.conf
    default/slurmdbd.conf /default/slurmdbd.conf
    scripts/hostlist.py /usr/bin/hostlist.py
    scripts/slurm_parser.py /usr/bin/slurm_parser.py
    scripts/simulate /usr/bin/simulate
    scripts/process_sdiag.py /usr/bin/process_sdiag
    scripts/process_simstat.py /usr/bin/process_simstat
    scripts/process_sinfo.py /usr/bin/process_sinfo
    scripts/process_sprio.py /usr/bin/process_sprio
    scripts/process_squeue.py /usr/bin/process_squeue
    scripts/get_slurm_conf.py /usr/bin/get_slurm_conf
    scripts/overide_conf.py /usr/bin/overide_conf
    
%post
    SLURM_SIMULATOR_SOURCE_REPO=https://github.com/ubccr-slurm-simulator/slurm_simulator.git \
    SLURM_SIMULATOR_BRANCH=slurm-17-11_Sim
    SLURM_HOME=/opt/slurm
    SLURM_ETC=${SLURM_HOME}/etc
    TRACES_DIR=/traces
    NOTVISIBLE="in users profile"
    PATH=${SLURM_HOME}/bin:${SLURM_HOME}/sbin:$PATH
    export SLURM_SIMULATOR_SOURCE_REPO \
        SLURM_SIMULATOR_BRANCH \
        SLURM_HOME \
        SLURM_ETC \
        TRACES_DIR \
        PATH \
        NOTVISIBLE
   
    # Create users, set up SSH keys (for MPI), add sudoers
    # -r for system account, -s for route shell to none bash one, -m for make home.
    # Explicitly state UID & GID for synchronsization across cluster 
    groupadd -r -g 3333 slurm
    useradd -r -u 3333 -g 3333 -s /bin/bash -m -d /home/slurm slurm

    # Install dependencies
    # epel-repository
    # Development Tools included gcc, gcc-c++, rpm-guild, git, svn, etc.
    # readline-devel, openssl, perl-ExtUtils-MakeMaker, pam-devel, mysql-devel needed by slurm
    # mariadb-server mariadb-devel for mysql slurm account db
    yum -y update
    yum -y install epel-release
    yum -y install \
        git \
        gcc-c++ \
        python34 \
        python34-libs \
        python34-devel \
        python34-numpy \
        python34-scipy \ 
        python34-pip
    pip3 install pymysql pandas
    yum -y install \
        ntp \
        openssh-server \
        readline-devel \
        openssl \
        perl-ExtUtils-MakeMaker \
        pam-devel \
        mysql-devel \
        mariadb-server \
        mariadb-devel
    yum clean all
    rm -rf /var/cache/yum/*

    # follow ubccr-slurm-simulator/slurm-simulator guide
    # Switch to slurm user so the next directories made are owned by slurm
    # USER slurm 

    # installing slurm simulator
    cd /home/slurm
    git clone --single-branch -b $SLURM_SIMULATOR_BRANCH $SLURM_SIMULATOR_SOURCE_REPO
    cd slurm_simulator
    ./configure \
        --prefix=$SLURM_HOME \
        --enable-simulator \
        --enable-pam \
        --without-munge \
        --enable-front-end \
        --with-mysql-config=/usr/bin/ \
        --disable-debug \
        CFLAGS="-g -O3 -D NDEBUG=1"
    make -j install

    # Configure OpenSSH
    # Also see: https://docs.docker.com/engine/examples/running_ssh_service/
    echo "export VISIBLE=now" >> /etc/profile
    mkdir /var/run/sshd
    echo 'slurm:slurm' | chpasswd

    # SSH login fix. Otherwise user is kicked off after login
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
    cd /etc/ssh/
    ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key -N ''

    # Fixed ownership and permission of Slurm
    mkdir /var/spool/slurmctld /var/log/slurm
    chown slurm: /var/spool/slurmctld /var/log/slurm
    chmod 755 /var/spool/slurmctld /var/log/slurm
    touch /var/log/slurm/slurmctld.log
    chown slurm: /var/log/slurm/slurmctld.log

    # Initialize mysql db and Fixed permission.
    # after this we are ready to start daemon.
    chmod g+rw /var/lib/mysql /var/log/mariadb /var/run/mariadb
    mysql_install_db
    chown -R mysql:mysql /var/lib/mysql 
        
    chmod u+x \
        /usr/bin/simulate \
        /usr/bin/process_sdiag \
        /usr/bin/process_simstat \
        /usr/bin/process_sinfo \
        /usr/bin/process_sprio \
        /usr/bin/process_squeue \
        /usr/bin/get_slurm_conf \
        /usr/bin/overide_conf
    mkdir -p $SLURM_ETC
    mkdir -p /default