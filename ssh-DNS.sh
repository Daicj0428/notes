#!/bin/bash
#修改主机名

##################################
ip_4=("100" "101"  "102" "103" "104")
ip_b3="192.168.1"

for i in  ${ip_4};
do 
    ssh ${ip_b3}.$i "sed -i '/#UseDNS yes/c UseDNS no' /etc/ssh/sshd_config
    systemctl restart sshd
done