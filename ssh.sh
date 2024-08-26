 #!/bin/bash
 #by dcj
 #2024-7-15
 # 生成ssh key
 if [[ ! -f "/root/.ssh/id_rsa" ]]
 then
         echo "gen ssh key"
         ssh-keygen -t rsa -q -N ""
 fi
 # 检测是否安装了 expect
 if ! expect -v &>/dev/null   # expect -v  查看expect版本
 then
         echo "install expect"
         yum install  -y expect
 fi
 # 循环文件中的ip   #host.txt文件 格式为IP:password
 for p in $(cat host.txt|grep -v '#')
 do
         ip=$(echo "$p"|cut -f1 -d":")            # 取出当前IP
         password=$(echo "$p"|cut -f2 -d":")     # 取出当前密码
 # expect 交互过程
  expect -c "
                 spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@$ip 
         expect {
                 \"*yes/no*\" {send \"yes\r\"; exp_continue} 
                 \"*password*\" {send \"$password\r\"; exp_continue} 
                 \"*Password*\" {send \"$password\r\";} 
        } "
 done