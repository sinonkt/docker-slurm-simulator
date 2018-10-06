Bootstrap: docker

From: centos/systemd:latest

%labels
    maintainer="oatkrittin@gmail.com"

%environment
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
        PATH

%files
    etc/ssh/sshd_config /etc/ssh/sshd_config
    etc/systemd/system/supervisord.service /etc/systemd/system/supervisord.service 
    scripts/simulate /usr/bin/simulate
    
%post
    # Create users, set up SSH keys (for MPI), add sudoers
    # -r for system account, -s for route shell to none bash one, -m for make home.
    # Explicitly state UID & GID for synchronsization across cluster 
    groupadd -r -g 3333 slurm
    useradd -r -u 3333 -g 3333 -s /bin/bash -m -d /home/slurm slurm

    # Install dependencies
    # epel-repository
    # Development Tools included gcc, gcc-c++, rpm-guild, git, svn, etc.
    # readline-devel, openssl, perl-ExtUtils-MakeMaker, pam-devel, mysql-devel needed by slurm
    # which, wget, net-tools, bind-tools(nslookup), telnet for debugging
    # mariadb-server mariadb-devel for mysql slurm account db
    yum -y update
    yum -y install epel-release
    yum -y groupinstall "Development Tools"
    yum -y install \
        ntp \
        openssh-server \
        supervisor \
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

    # Enable MariaDB service
    ln -s /usr/lib/systemd/system/mariadb.service /etc/systemd/system/multi-user.target.wants/mariadb.service
    
    # Poppulate SlumDbd script.
    chmod u+x /usr/bin/simulate
    rm -rf $SLURM_ETC