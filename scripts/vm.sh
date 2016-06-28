#!/bin/bash
hostname=$1
flavor=mash.memory.small
image="CentOS 7.latest"
key_name=labnc_186

echo -n "building vm "
supernova -q dev boot --flavor $flavor --key-name $key_name --image "$image" $hostname > /dev/null 2>&1
until [ $(supernova dev show $hostname | grep status | awk '{print $4}') = "ACTIVE" ]; do echo -n "." ; sleep 3; done
echo ""

next_ip=$(supernova dev floating-ip-list|grep -v "172.16." | grep "10.0.141"|head -1|awk '{print $4}')
supernova -q dev add-floating-ip $hostname $next_ip

until [ $(ssh -o ConnectTimeout=1 mashuser@${next_ip} 'exit' 2>&1 | grep "timed out" | wc -l) = 0 ]; do echo -n "."; done
echo ""
sleep 30

echo "setting up docker"
ssh mashuser@$next_ip 'curl -s 10.0.141.58/scripts/docker_install.sh | sudo bash' > /dev/null 2>&1

echo "-- ssh $next_ip --"
