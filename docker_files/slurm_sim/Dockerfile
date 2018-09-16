FROM centos:7

LABEL maintainer="oatkrittin@gmail.com"

ENV SLURM_VERSION=17.11.9-2 \
    MUNGE_VERSION=0.5.13 \
    LMOD_VERSION=7.8 \
    USER_DEV=dev \
    ROOT_HOME=/root \
    ROOT_RPMS=/root/rpmbuild/RPMS/x86_64 \
    APPS_ROOT_PATH=/opt/apps \
    MODULES_DIR=/home/modules \
    EASYBUILD_PREFIX=home/modules

# Fixed systemd, activate systemd as suggested by official centos:7,centos:latest 
ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]

WORKDIR ${ROOT_HOME} 
# Create users, set up SSH keys (for MPI), add sudoers
# -r for system account, -s for route shell to none bash one, -m for make home.
# Explicitly state UID & GID for synchronsization across cluster 
ADD etc/sudoers /etc/sudoers
RUN groupadd -r -g 3333 slurm && \
    useradd -r -u 3333 -g 3333 -s /bin/false slurm && \
    useradd -u 6666 -ms /bin/bash $USER_DEV && \
    usermod -aG wheel $USER_DEV

# Add .ssh and correct permissions.
ADD home/${USER_DEV}/ssh /home/${USER_DEV}/.ssh
RUN chown -R ${USER_DEV}:wheel /home/${USER_DEV} && \
    chmod 700 /home/${USER_DEV}/.ssh && \
    chmod 600 /home/${USER_DEV}/.ssh/*

# Install dependencies
# epel-repository
# Development Tools included gcc, gcc-c++, rpm-guild, git, svn, etc.
# bzip2-devel, openssl-devel, zlib-devel needed by munge
# readline-devel, openssl, perl-ExtUtils-MakeMaker, pam-devel, mysql-devel needed by slurm
# lua-posix lua lua-filesystem lua-devel tcl needed by Lmod
# which needed by easybuild
# wget, net-tools, bind-tools(nslookup), telnet for debugging
RUN yum -y update && \
    yum -y install epel-release && \
    yum -y groupinstall "Development Tools" && \
    yum -y install \
    wget \
    ntp \
    openssh-server \
    supervisor \
    bzip2-devel \
    openssl-devel \
    zlib-devel \
    readline-devel \
    openssl \
    perl-ExtUtils-MakeMaker \
    pam-devel \
    mysql-devel \
    lua-posix \
    lua \
    lua-filesystem \
    lua-devel \
    tcl \
    which \
    net-tools \
    telnet \
    bind-utils \
    && \
    yum clean all && \
    rm -rf /var/cache/yum/*


# Create user `munge`
RUN groupadd -g 981 munge && \
    useradd  -m -d /var/lib/munge -u 981 -g munge  -s /sbin/nologin munge

# Install munge
RUN wget https://github.com/dun/munge/releases/download/munge-${MUNGE_VERSION}/munge-${MUNGE_VERSION}.tar.xz && \
    rpmbuild -tb --clean munge-${MUNGE_VERSION}.tar.xz && \ 
    rpm -ivh ${ROOT_RPMS}/munge-${MUNGE_VERSION}-1.el7.x86_64.rpm \
        ${ROOT_RPMS}/munge-libs-${MUNGE_VERSION}-1.el7.x86_64.rpm \
        ${ROOT_RPMS}/munge-devel-${MUNGE_VERSION}-1.el7.x86_64.rpm && \
    rm -f munge-${MUNGE_VERSION}.tar.xz 

# Configure munge (for SLURM authentication)
ADD etc/munge/munge.key /etc/munge/munge.key
RUN chown munge:munge /var/lib/munge && \
    chown munge:munge /etc/munge/munge.key && \
    chown munge:munge /etc/munge && chmod 600 /var/run/munge && \
    chmod 755 /run/munge && \
    chmod 600 /etc/munge/munge.key
ADD etc/supervisord.d/munged.ini /etc/supervisord.d/munged.ini

# Build Slurm-* rpm packages ready for variant to pick and install
RUN wget https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2 && \
    rpmbuild -ta --clean slurm-${SLURM_VERSION}.tar.bz2 && \
    rm -f slurm-${SLURM_VERSION}.tar.bz2

# Install Lmod
RUN wget https://sourceforge.net/projects/lmod/files/Lmod-${LMOD_VERSION}.tar.bz2 && \
    tar -xvjf Lmod-${LMOD_VERSION}.tar.bz2 && \
    cd Lmod-${LMOD_VERSION} && \
    ./configure --prefix=${APPS_ROOT_PATH} && \
    make install && \
    ln -s ${APPS_ROOT_PATH}/lmod/lmod/init/profile        /etc/profile.d/z00_lmod.sh && \
    ln -s ${APPS_ROOT_PATH}/lmod/lmod/init/cshrc          /etc/profile.d/z00_lmod.csh && \
    rm -f ../Lmod-${LMOD_VERSION}.tar.bz2 
#ln -s ${APPS_ROOT_PATH}/lmod/lmod/init/profile.fish   /etc/fish/conf.d/z00_lmod.fish && \

# Create Modules user & Easybuild init script. Practices by dtu.dk
# https://wiki.fysik.dtu.dk/niflheim/EasyBuild_modules#installing-easybuild specify MODULES_HOME
RUN groupadd -g 983 modules && \
    mkdir -p $MODULES_DIR && \
    useradd -m -c "Modules user" -d $MODULES_DIR -u 983 -g modules -s /bin/bash modules && \
    chown -R modules:modules ${MODULES_DIR} && \
    chmod a+rx ${MODULES_DIR}
ADD etc/profile.d/z01_EasyBuild.sh /etc/profile.d/z01_EasyBuild.sh

# Configure OpenSSH
# Also see: https://docs.docker.com/engine/examples/running_ssh_service/
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
RUN mkdir /var/run/sshd
RUN echo 'dev:dev' | chpasswd
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ADD etc/ssh/sshd_config /etc/ssh/sshd_config
ADD etc/supervisord.d/sshd.ini /etc/supervisord.d/sshd.ini
RUN cd /etc/ssh/ && \
    ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key -N ''

VOLUME [ "/etc/slurm" ]

EXPOSE 22

FROM sinonkt/docker-slurmbase

LABEL maintainer="oatkrittin@gmail.com"

ENV ROOT_RPMS=/root/rpmbuild/RPMS/x86_64 \
    EASYBUILD_PREFIX=/home/modules \
    MODULES_DIR=${EASYBUILD_PREFIX} \
    MODULEPATH=${MODULES_DIR}/modules/all:$MODULEPATH

# Install slurm, slurmctld, slurm-perlapi
RUN rpm -ivh ${ROOT_RPMS}/slurm-${SLURM_VERSION}.el7.x86_64.rpm \
  ${ROOT_RPMS}/slurm-slurmctld-${SLURM_VERSION}.el7.x86_64.rpm \
  ${ROOT_RPMS}/slurm-perlapi-${SLURM_VERSION}.el7.x86_64.rpm && \
  rm -rf ${ROOT_RPMS}/*

# Fixed ownership and permission of Slurm
RUN mkdir /var/spool/slurmctld /var/log/slurm && \
  chown slurm: /var/spool/slurmctld /var/log/slurm && \
  chmod 755 /var/spool/slurmctld /var/log/slurm && \
  touch /var/log/slurm/slurmctld.log && \
  chown slurm: /var/log/slurm/slurmctld.log
ADD etc/supervisord.d/slurmctld.ini /etc/supervisord.d/slurmctld.ini

# Switch to user `modules` to install EasyBuild
USER modules
WORKDIR /home/modules

# Install EasyBuild, Simulate source profile when we ssh
RUN source /etc/profile.d/z00_lmod.sh && \
    wget https://raw.githubusercontent.com/easybuilders/easybuild-framework/develop/easybuild/scripts/bootstrap_eb.py && \
    python bootstrap_eb.py $EASYBUILD_PREFIX && \
    rm -f bootstrap_eb.py

# Switch to root before run script
USER root

VOLUME [ "/sys/fs/cgroup", "/etc/slurm" ]

EXPOSE 22 6817

CMD ["/usr/bin/supervisord", "--nodaemon"]