#!/bin/bash
hostname=$1
flavor=mash.memory.small
image="coreos_stable"
key_name=labnc_186

echo -n "building vm "
supernova -q dev boot --flavor $flavor --key-name $key_name --image "$image" --config-drive=true $hostname > /dev/null 2>&1
until [ $(supernova dev show $hostname | grep status | awk '{print $4}') = "ACTIVE" ]; do echo -n "." ; sleep 3; done

next_ip=$(supernova dev floating-ip-list|grep -v "172.16." | grep "10.0.141"|head -1|awk '{print $4}')
supernova -q dev add-floating-ip $hostname $next_ip

until [ $(ssh -o ConnectTimeout=1 mashuser@${next_ip} 'exit' 2>&1 | grep "timed out" | wc -l) = 0 ]; do echo -n "."; done
sleep 30

echo "  -- ssh $next_ip --"
