#!/usr/bin/bash
#NEW ingest script - ac 3/3/16
PREFIX="/var/docker/tmp"
DESTINATION="/var/www/html/partshop/Docker"
U2CHOST="10.0.33.60"
LOGIN="lab24_186"
image_list="rancher/agent rancher/agent-instance rancher/hadoop-base rancher/hadoop-config logstash kibana \
rancher/hadoop-followers-config rancher/convoy-agent ruby alpine swarm nginx mattermost/platform registry redis \
glyptodon/guacamole glyptodon/guacd crate tomcat mongo prom/prometheus consul wordpress postgres mariadb \
google/cadvisor piwik node rails grafana/grafana"

#cleanup
ssh -t $LOGIN@$U2CHOST "rm -f $DESTINATION/*"  > /dev/null 2>&1

for image in $image_list; do
  tag=$(curl -sk --connect-timeout 300 https://registry.hub.docker.com/v1/repositories/$image/tags |/usr/bin/jq -r .[].name|sed -e '/32bit/d' -e '/^[a-z]-.*/d' -e '/\(rc\)\|\(pre\)/d' -e '/latest/d' -e '/dev/d' -e '/alpine/d' -e '/master/d' -e '/slim/d' -e '/onbuild/d' -e '/wheezy/d' -e '/edge/d' -e '/stable/d' -e '/alpha/d' -e '/beta/d' -e '/apache/d' -e '/fpm/d' -e '/argon/d'| sort -rV | head -1)
  filename=$(echo $image|sed 's#/#_#g')
  if [ ! -f $PREFIX/$filename"_"$tag.tar ]; then
    echo - $image:$tag is new
    rm -rf $PREFIX/$filename*.tar
    docker rmi $(docker images|grep -w $image|awk '{print $3}')
    docker pull $image:$tag > /dev/null 2>&1
    docker save -o $PREFIX/$filename"_"$tag.tar $image:$tag
  fi
done

# And the even more special children, those images where we need old versions...the one-offs
docker pull centos:6.7 > /dev/null 2>&1
docker save -o $PREFIX/centos_6.7.tar centos:6.7
docker pull centos:latest > /dev/null 2>&1
docker save -o $PREFIX/centos_latest.tar centos:latest
docker pull ubuntu:14.04.4 > /dev/null 2>&1
docker save -o $PREFIX/ubuntu_14.04.tar ubuntu:14.04.4
docker pull ubuntu:16.04 > /dev/null 2>&1
docker save -o $PREFIX/ubuntu_16.04.tar ubuntu:16.04
docker pull gliderlabs/logspout:master > /dev/null 2>&1
docker save -o $PREFIX/logspout_master.tar gliderlabs/logspout:master
docker pull spotify/kafka > /dev/null 2>&1
docker save -o $PREFIX/spotify_kafka.tar spotify/kafka
docker pull spotify/cassandra > /dev/null 2>&1
docker save -o $PREFIX/spotify_cassandra.tar spotify/cassandra
docker pull rancher/server:v1.0.1 > /dev/null 2>&1
docker save -o $PREFIX/rancher_server_v1.0.1.tar rancher/server:v1.0.1
docker pull elasticsearch:2.3.1 > /dev/null 2>&1
docker save -o $PREFIX/elasticsearch_2.3.1.tar elasticsearch:2.3.1
docker pull docker/docker-bench-security > /dev/null 2>&1
docker save -o $PREFIX/docker-bench-security.tar docker/docker-bench-security

docker pull prom/node-exporter > /dev/null 2>&1
docker save -o $PREFIX/prom_node-exporter.tar prom/node-exporter
docker pull prom/alertmanager > /dev/null 2>&1
docker save -o $PREFIX/prom_alertmanager.tar prom/alertmanager
docker pull prom/pushgateway > /dev/null 2>&1
docker save -o $PREFIX/prom_pushgateway.tar prom/pushgateway

#custom for team here that has built this!
docker pull jupytergallery/base > /dev/null 2>&1
docker save -o $PREFIX/jupytergallery_base.tar jupytergallery/base
docker pull jupytergallery/cling > /dev/null 2>&1
docker save -o $PREFIX/jupytergallery_cling.tar jupytergallery/cling


#snowflakes
RANCHER_FILE=$(curl -v --silent https://github.com/rancher/rancher-compose/releases 2>&1 | grep tar.gz | grep amd64 | sed -e "/-rc.*/d" -e "/^\s\+tar/d" -e 's/\s\+<a href=\"/https:\/\/github.com/g' -e '/^\s/d'| awk -F'"' {'print $1'} | sort -dr | head -n 1)
RANCHER_NAME=$(curl -v --silent https://github.com/rancher/rancher-compose/releases 2>&1 | grep tar.gz | grep amd64 | sed -e '/-rc.*/d' -e '/^\s\+tar/d' -e 's/\s\+<a href=\"/https:\/\/github.com/g' -e '/^\s/d'| awk -F'"' {'print $1'} | sort -dr | head -n 1 | sed -e 's/.*\///')
if [ ! -f $PREFIX/$RANCHER_NAME ]; then
  rm -rf $PREFIX/rancher-compose*
  wget -O $PREFIX/$RANCHER_NAME $RANCHER_FILE
fi

machine_ver=$(curl -s https://github.com/docker/machine/tags 2>&1 | grep tar.gz | sed -e "/-rc.*/d" -e "/^\s\+tar/d" -e 's/\s\+<a href=\"/https:\/\/github.com/g' | awk -F'"' {'print $1'} | sort -dr | head -n 1|awk -F"/" '{print $7}'|sed 's/.tar.gz//')
if [ ! -f $PREFIX/docker-machine-$machine_ver ]; then
  rm -rf $PREFIX/docker-machine*
  wget -O $PREFIX/docker-machine-$machine_ver https://github.com/docker/machine/releases/download/$machine_ver/docker-machine-`uname -s`-`uname -m`
fi

DOCKER_COMPOSE_FILE=$(curl -v --silent https://github.com/docker/compose/releases 2>&1 | grep 'docker-compose-Linux' |sed -e "/rc[0-9].*/d" -e "/^\s\+tar/d" -e 's/\s\+<a href=\"/https:\/\/github.com/g' -e '/^\s/d' | awk -F'"' {'print $1'} | sort -dr | head -n 1)
DCFOO=$(curl -v --silent https://github.com/docker/compose/releases 2>&1 | grep 'docker-compose-Linux' |sed -e "/rc[0-9].*/d" -e "/^\s\+tar/d" -e 's/\s\+<a href=\"/https:\/\/github.com/g' -e '/^\s/d' | awk -F'"' {'print $1'} | sort -dr | head -n 1 | grep -o "[0-9].[0-9].[0-9]")
DOCKER_COMPOSE_NAME=docker-compose-x86_64-$DCFOO
if [ ! -f $PREFIX/$$DOCKER_COMPOSE_NAME ]; then
  rm -rf $PREFIX/docker-compose*
  wget -O $PREFIX/$DOCKER_COMPOSE_NAME $DOCKER_COMPOSE_FILE
fi

#CoreOS
cver=$(curl -s https://coreos.com/releases/| sed -e 's/<[^>]\+>//g' -e '/^$/d'|grep -C1 "Beta channel"|head -1)
if [ ! -f $PREFIX/coreos_$cver.img.bz2 ]; then
  rm -rf $PREFIX/coreos*.bz2
  wget -O $PREFIX/coreos_$cver.img.bz2 http://beta.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2
fi

#rancheros
#rancherosver=$(curl -s https://github.com/rancher/os/tags | sed -e 's/<[^>]*>//g' -e '/^\s*$/d' -e '/^$/d' -e 's/^[ \t]*//'|grep v0|grep -v rc|uniq |head -1)
#wget -O $PREFIX/rancheros-$rancherosver.img https://releases.rancher.com/os/$rancherosver/rancheros-openstack.img

#jenins
wget -O $PREFIX/jenkins.war http://ftp-chi.osuosl.org/pub/jenkins/war/2.0/jenkins.war

# permission to read all the things
chmod -R 0775 $PREFIX/*

#rsync files over
rsync -avP --delete $PREFIX/* $LOGIN@$U2CHOST:$DESTINATION/

#cleanup locally
docker rmi $(docker images |grep "<none>"|awk '{print $3}')


