#!/bin/bash
#network
#################################
ifcfg_name=ens33
ifcfg=eth0
ip_4=("100" "101"  "102" "103" "104")
ip_b3="192.168.1"
ip_new=("80" "81" "82" "83" "84")
ip_new_b3="192.168.31"

for i in "${ip_4[@]}";
do 
    scp /etc/sysconfig/network-scripts/ifcfg-${ifcfg_name} ${ip_b3}.${i}:/etc/sysconfig/network-scripts/ifcfg-${ifcfg}
    if [ $? -eq 0 ];then
        echo "scp ifcfg-${ifcfg_name} to ${ip_b3}.${i} success!"
    else
        echo "scp ifcfg-${ifcfg_name} to ${ip_b3}.${i} failed!"
    fi
        for j in "${ip_new[@]}";
        do 
            ssh ${ip_b3}.${i} "sed -i 's/IPADDR=.*/IPADDR=${ip_new_b3}.${j}/g' /etc/sysconfig/network-scripts/ifcfg-${ifcfg}"
            ssh ${ip_b3}.${i} "sed -i 's/DEVICE=.*/DEVICE=${ifcfg}/g' /etc/sysconfig/network-scripts/ifcfg-${ifcfg}"
            if [ $? -eq 0 ];then
                echo "修改 IP 地址成功 on ${ip_b3}.${i}!"
                systemctl restart network
            else
                echo "修改 IP 地址失败 on ${ip_b3}.${i}!"
            fi
        done
done
