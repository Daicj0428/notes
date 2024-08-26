#! /bin/bash

#######################
passwd="123456"
######################
if [ ! -s /root/userradd.txt ];then
	echo "账户文件内容为空"
	exit 
fi
for i in `cat /root/userradd.txt`
do	
	id $! &> /dev/null
	if [ $? -eq 0 ];then
	echo "$i 用户已经创建过了"
	else
	echo "正在创建$1 用户"
	useradd $i
	echo "正在设置初始化密码"
	echo "$i:$passwd" | chpasswd &> /dev/null
		if [ $? -eq o ];then
		echo "用户账号密码创建成功，并强制要求下次登陆时修改密码"
		change -d 0 $i
		else 
		useradd -r $i &> /dev/null
		fi
	fi	
done
