#!/bin/bash

ip_num=`ifconfig ens33 | awk -F " " 'NR==2{print $2}'`
use_num=50
FREE_NUM=`df -Ph | grep -v sr0 | awk '{print int($5)}'`
for i in $FREE_NUM
do
	if [ $i -ge $use_num ]
then
	echo "${ip_num}的磁盘使用率已经超过了${use_num}%，请及时处理"
	fi
done
