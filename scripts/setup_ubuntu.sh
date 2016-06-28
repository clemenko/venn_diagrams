#!/bin/bash
growpart -u auto /dev/vda 2
pvresize /dev/vda2
lvextend /dev/vg_sys/lv_root -r -L +7G
lvextend /dev/vg_sys/lv_var -r -l 100%FREE
export PATH=$PATH:/sbin/

#mate
#apt-add-repository ppa:ubuntu-mate-dev/ppa
#apt-add-repository ppa:ubuntu-mate-dev/trusty-mate

#apt install -y  xrdp gnome-icon-theme-full tango-icon-theme
#apt install -y --no-install-recommends ubuntu-mate-core ubuntu-mate-desktop xrdp

#docker
apt install -y apt-transport-https ca-certificates
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list

apt update; apt upgrade -y
apt install -y docker-engine 

useradd -d /home/clemenko -s /bin/bash clemenko

