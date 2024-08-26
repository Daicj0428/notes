#! /bin/bash

#######################
echo -e "\e[33;1m 请再10s内输入相关内容 \e[0m"
read -t 10 -p "请输入开始的数字：" num_s
if [ -z ${num_s} ] ;then
	echo ""
	echo "输入超时，退出"
	exit
fi
read -t 10 -p "请输入结束的数字：" num_t
if [ -z ${num_t} ] ;then
	echo ""
	echo "输入超时，退出"
	exit
fi
if [ $[$num_s%2] -eq 0 ];then	
	num_s=$[unm_s+1]
fi
sum=0
for i in $(seq $num_s 2 $num_t )
do
	echo $[sum+=$i] &> /dev/null
done	
	echo -e "\e[33;1m $num_s-$num_t的奇数和：$sum \e[0m"
