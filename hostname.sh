#!/bin/bash
# 批量修改主机名
########################
ip_4=("29" "28" "27" "26")
ip_b3="192.168.1"
hostfqdn=("dai29" "dai28" "dai27" "dai26")
user="root"

for i in `seq 0 3`
do
    ip="$ip_b3.${ip_4[$i]}"
    host="${hostfqdn[$i]}"
    echo "Modifying hostname of $ip to $host"
    ssh $user@$ip "hostnamectl set-hostname $host"
done
