FROM centos/systemd:latest

LABEL maintainer="oatkrittin@gmail.com"

ENV SLURM_SIMULATOR_SOURCE_REPO=https://github.com/ubccr-slurm-simulator/slurm_simulator.git \
    SLURM_SIMULATOR_BRANCH=slurm-17-11_Sim \
    SLURM_HOME=/opt/slurm \
    SLURM_ETC=/opt/slurm/etc \
    TRACES_DIR=/traces \
    PATH=/opt/slurm/bin:/opt/slurm/sbin:$PATH

# Create users, set up SSH keys (for MPI), add sudoers
# -r for system account, -s for route shell to none bash one, -m for make home.
# Explicitly state UID & GID for synchronsization across cluster 
RUN groupadd -r -g 3333 slurm && \
    useradd -r -u 3333 -g 3333 -s /bin/bash -m -d /home/slurm slurm

# Install dependencies
# epel-repository
# Development Tools included gcc, gcc-c++, rpm-guild, git, svn, etc.
# readline-devel, openssl, perl-ExtUtils-MakeMaker, pam-devel, mysql-devel needed by slurm
# mariadb-server mariadb-devel for mysql slurm account db
RUN yum -y update && \
    yum -y install epel-release && \
    yum -y groupinstall "Development Tools" && \
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
    mariadb-devel \
    && \
    yum clean all && \
    rm -rf /var/cache/yum/*


# follow ubccr-slurm-simulator/slurm-simulator guide
# Switch to slurm user so the next directories made are owned by slurm
# USER slurm 

# installing slurm simulator
RUN cd /home/slurm && \
  git clone --single-branch -b $SLURM_SIMULATOR_BRANCH $SLURM_SIMULATOR_SOURCE_REPO && \
  cd slurm_simulator && \
  ./configure \
    --prefix=$SLURM_HOME \
    --enable-simulator \
    --enable-pam \
    --without-munge \
    --enable-front-end \
    --with-mysql-config=/usr/bin/ \
    --disable-debug \
    CFLAGS="-g -O3 -D NDEBUG=1" \
    && \
  make -j install

# Configure OpenSSH
# Also see: https://docs.docker.com/engine/examples/running_ssh_service/
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
RUN mkdir /var/run/sshd
RUN echo 'slurm:slurm' | chpasswd

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ADD etc/ssh/sshd_config /etc/ssh/sshd_config
RUN cd /etc/ssh/ && \
    ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key -N ''

# Fixed ownership and permission of Slurm
RUN mkdir /var/spool/slurmctld /var/log/slurm && \
  chown slurm: /var/spool/slurmctld /var/log/slurm && \
  chmod 755 /var/spool/slurmctld /var/log/slurm && \
  touch /var/log/slurm/slurmctld.log && \
  chown slurm: /var/log/slurm/slurmctld.log

# Enable MariaDB service
RUN ln -s /usr/lib/systemd/system/mariadb.service /etc/systemd/system/multi-user.target.wants/mariadb.service

# Configure supervisord as one of systemd service
ADD etc/systemd/system/supervisord.service /etc/systemd/system/supervisord.service 
RUN chmod 664 /etc/systemd/system/supervisord.service && \
    ln -s /etc/systemd/system/supervisord.service /etc/systemd/system/multi-user.target.wants/supervisord.service

# Poppulate SlumDbd script.
ADD scripts/simulate /usr/bin/simulate
RUN chmod u+x /usr/bin/simulate && \
    rm -rf $SLURM_ETC

VOLUME [ "/sys/fs/cgroup", "/var/log/slurm" ]

EXPOSE 22 6817 3306
