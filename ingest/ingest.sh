#!/usr/bin/bash
#NEW ingest script - ac 5/13/16
#v2!

PREFIX="/var/docker/tmp"
DESTINATION="/var/www/html/partshop/Docker"
U2CHOST="10.0.33.60"
LOGIN="lab24_186"
image_list="rancher/agent rancher/agent-instance rancher/hadoop-base \
rancher/hadoop-config library/logstash library/kibana \
rancher/hadoop-followers-config rancher/convoy-agent library/ruby \
library/alpine library/swarm library/nginx mattermost/platform \
library/registry library/redis glyptodon/guacamole glyptodon/guacd \
library/crate library/tomcat library/mongo prom/prometheus library/consul \
library/wordpress library/postgres library/mariadb \
google/cadvisor library/piwik library/node library/rails grafana/grafana rancher/server"

gcr_list="etcd pause heapster heapster_influxdb heapster_grafana skydns kube2sky exechealthz"

snowflake_list="centos:6.7 centos:latest ubuntu:14.04.4 ubuntu:16.04 gliderlabs/logspout:master \
spotify/kafka spotify/cassandra elasticsearch:2.3.2 docker/docker-bench-security \
prom/node-exporter prom/alertmanager prom/pushgateway jupytergallery/base jupytergallery/cling"

###################### stop editing ############################

#cleanup
ssh -t $LOGIN@$U2CHOST "rm -f $DESTINATION/*"  > /dev/null 2>&1

#docker
for image in $image_list; do
  token=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$image:pull"|jq -r .token)
  tag=$(curl -s -H "Authorization: Bearer $token" "https://registry-1.docker.io/v2/$image/tags/list"|jq -r .tags[]|sed -e '/32bit/d' -e '/^[a-z]-.*/d' -e '/\(rc\)\|\(pre\)/d' -e '/latest/d' -e '/dev/d' -e '/alpine/d' -e '/master/d' -e '/slim/d' -e '/onbuild/d' -e '/wheezy/d' -e '/edge/d' -e '/stable/d' -e '/alpha/d' -e '/beta/d' -e '/apache/d' -e '/fpm/d' -e '/argon/d'|sort -rV|head -1)

  filename=$(echo $image"_"$tag|sed -e 's#library/##g' -e 's#/#_#g')
  if [ ! -f $PREFIX/$filename.tar ]; then
    echo - $image:$tag is new
  echo  rm -rf $PREFIX/$filename*.tar
    docker rmi $(docker images|grep -w $image|awk '{print $3}')
  echo  docker pull $image:$tag > /dev/null 2>&1
  echo  docker save -o $PREFIX/$filename.tar $image:$tag
  fi
done

#gcr
for image in $gcr_list; do
  tag=$(curl -sk https://gcr.io/v2/google_containers/$image/tags/list|jq -r .tags[]|sed -e '/v2.0.3/d' -e '/2015/d' -e '/thtest/d' -e '/go/d' -e '/latest/d' -e '/beta/d' |sort -rV|head -1)
  filename=$(echo $image"_"$tag|sed 's#/#_#g')
  if [ ! -f $PREFIX/$filename.tar ]; then
    echo - $image:$tag is new
    rm -rf $PREFIX/$filename*.tar
    docker rmi $(docker images|grep "gcr.io"|grep -w $image|awk '{print $3}')
    docker pull gcr.io/google_containers/$image:$tag > /dev/null 2>&1
    docker save -o $PREFIX/$filename.tar gcr.io/google_containers/$image:$tag
  fi
done

for image in $snowflake_list; do
  docker pull $image > /dev/null 2>&1
  docker save -o $PREFIX/$(echo $image|sed -e 's#/#_#g' -e 's/:/_/g').tar $image
done

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
