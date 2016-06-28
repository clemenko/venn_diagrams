#!/bin/bash
yum install -y cloud-utils-growpart
growpart -u auto /dev/vda 2 
pvresize /dev/vda2

lvextend /dev/mapper/vg_sys-lv_root -r -L +5G
lvextend /dev/mapper/vg_sys-lv_var -r -l 100%FREE

cat >> /etc/yum.repos.d/docker.repo << EOF
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
yum-config-manager --enable elrepo-kernel
yum-config-manager --disable elrepo

yum update -y
yum install -y docker-engine vim jq

yum remove -y kernel-headers-3.10.0 kernel-tools-libs kernel-tools-3.10
yum install -y kernel-lt kernel-lt-headers kernel-lt-tools kernel-lt-tools-libs kernel-lt-tools-libs-devel
grub2-set-default 0

#groupadd docker
#usermod -G docker mashuser

#sed -i 's/daemon -H/daemon --storage-driver=overlay -H/g' /lib/systemd/system/docker.service
#systemctl daemon-reload
#systemctl enable docker
#systemctl start docker

#docker compose
#yum install -y python-pip
#pip install --upgrade pip
#pip install docker-compose

reboot
