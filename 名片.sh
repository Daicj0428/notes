#!/bin/bash
#by daichangjiang
#read
#2024-4-10 19:00
############################
echo -e "\e[33;5;1m 请在10s内输入相关内容 \e[0m"
read -t 10 -p "请输入你的名字：" name
if [  -z "$name" ]; then 
      echo " "
      echo "未检测到内容，自动退出"  
      exit 1
fi
read -t 10 -p "请输入你的年纪：" age
if [  -z "$age" ]; then 
      echo " "
      echo "未检测到内容，自动退出"  
      exit 1
fi
read -t 10 -p "请输入你的电话：" phone
if [  -z "$phone" ]; then 
      echo " "
      echo "未检测到内容，自动退出"  
      exit 1
fi
read -t 10 -p "请输入你的QQ号：" QQ
if [  -z "$QQ" ]; then 
      echo " "
      echo "未检测到内容，自动退出"  
      exit 1
fi

 cat << eof >> read.log
**********************************
 $(date "+%x%X")
姓名：$name                      
年纪：$age                       
电话：$phone         
QQ号：$QQ                       
**********************************

eof
 
