#! /bin/bash
read -t 5 -p "请输入第一个计算的数（1-9）： " num1
read -t 5 -p "请输入第二个计算的数（1-9）： " num2
	if [ $num1 -gt 10 -o $num1 -lt 1 ] || [ $num2 -gt 10 -o $num2 -lt 1 ] ; then
	echo "超出小霸王计算范围"
	else
	echo "${num1}x${num2}的值为$[ num1 * num2 ]"
	fi