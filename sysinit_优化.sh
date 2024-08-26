#! /bin/bash
# by daichangjiang
#2024-4-15 18:00
#虚拟机初始化配置优化重置版
##############################
fire=$(systemctl status firewalld | grep Active | awk '{print $3}'  | tr -d "( )")
selinux_get=`getenforce`
timedate_get=$(timedatectl | grep Time | awk '{print $3}')
timedate_set=Asia/Shanghai
logfile="/root/sysinit.log"
colour=(31 32)
ruslt=("失败!" "成功!")
messages=("关闭防火墙" "关闭selinux" "设置时区" "创建光盘挂载目录" "设置永久挂载" "安装createrepo插件" "创本地源目录创建" "系统源备份" "tree安装包移至本地源目录" "将本地目录变为本地yum源" "配置本地yum源" "安装软件包测试" "本地源仓库创建" "将系统yum源移移回" )
##############################
delimiter(){
    echo -e "\e[33;1m##################################\e[0m" 
}
echoinfo(){
    echo -e "\e[36;1m$1\e[0m"    
}
echoresult(){
    echo -e "\e[$1;1m$2$3\e[0m"
}
if_test(){
    if [ $? == 0 ];then
        echoresult ${colour[1]} $1 ${ruslt[1]}
    else
        echoresult ${colour[0]} $1 ${ruslt[0]}
        exit
    fi
}
delimiter | tee -a $logfile
echoinfo ${messages[0]} | tee -a $logfile
        systemctl stop firewalld
        systemctl disable firewalld &> /dev/null
if_test ${messages[0]}

delimiter | tee -a $logfile
echoinfo ${messages[1]} | tee -a $logfile
    if [ $selinux_get == Enforcing ] ;then
        echo "selinux处于开启状态"
        setenforce 0
        echo "已经临时关闭selinux"
    elif [ $selinux_get == Permissive ] ;then
        echo "selinux处于宽容状态"
    elif [ $selinux_get == Disabled ] ;then
        echo "selinux处于关闭状态"
    else    
        echo "selinux关闭失败"
    fi
if_test ${messages[1]}

delimiter | tee -a $logfile
echoinfo ${messages[2]} | tee -a $logfile
    if [ "$timedate_get" != "${timedate_set}" ] ;then
        echo "当前系统设置的时区为${timedate_get}"
        echo "正在将时区更改为${timedate_set}"
        timedatectl set-tiamzone ${timedate_set}
    elif [ "$timedate_get" == "${timedate_set}" ] ;then
        echo "当前系统时区为${timedate_set}"
    else
        echo "时区设置失败"
fi
if_test ${messages[2]}

delimiter | tee -a $logfile
echoinfo ${messages[3]} | tee -a $logfile
    if [ ! -d /mnt/cdrom ] ;then
    echo "挂载目录不在"
    mkdir /mnt/cdrom
        if [ $? -eq 0 ] ;then
        echo "挂载目录创建成功"
        else
        echo "挂载目录创建失败"
        fi
    else
        echo "挂载目录已创建"
fi
if_test ${messages[3]}

delimiter | tee -a $logfile
echoinfo ${messages[4]} | tee -a $logfile
mount /dev/sr0  /mnt/cdrom &> /dev/null
echo "/dev/sr0               /mnt/cdrom               iso9660 defaults        0 0" >> /etc/fstab
mount -a &> /dev/null
df -h | grep /dev/sr0  &> /dev/null
if_test ${messages[4]}

delimiter | tee -a $logfile
echoinfo ${messages[5]} | tee -a $logfile
yum -y install createrepo &> /dev/null 
if_test ${messages[5]}

delimiter | tee -a $logfile
echoinfo ${messages[6]} | tee -a $logfile
mkdir dcj
if_test ${messages[6]}

delimiter | tee -a $logfile
echoinfo ${messages[7]} | tee -a $logfile
mv /etc/yum.repos.d/*  /opt 
if_test ${messages[7]}

delimiter | tee -a $logfile
echoinfo ${messages[8]} | tee -a $logfile
cp /mnt/cdrom/Packages/tree-1.6.0-10.el7.x86_64.rpm  /root/dcj
if_test ${messages[8]}


delimiter | tee -a $logfile
echoinfo ${messages[9]} | tee -a $logfile
createrepo /root/dcj/  &> /dev/null
if_test ${messages[9]}

delimiter | tee -a $logfile
echoinfo ${messages[10]} | tee -a $logfile
cat << eof >/etc/yum.repos.d/dcj.repo
[centos7]
name=dcj_centos7
baseurl=file:///root/dcj
enabled=1
gpgcheck=0  
 
eof
if_test ${messages[10]}

delimiter | tee -a $logfile
echoinfo ${messages[11]} | tee -a $logfile
yum -y install tree  &> /dev/null
if_test ${messages[11]}

yum clean all &>/dev/unll
    echo "清理本地源缓存"

delimiter | tee -a $logfile
echoinfo ${messages[12]} | tee -a $logfile
yum repolist | grep dcj  &> /dev/null
if_test ${messages[12]}

delimiter | tee -a $logfile
echoinfo ${messages[13]} | tee -a $logfile
mv /opt/* /etc/yum.repos.d/  &> /dev/null
if_test ${messages[13]}
########################################
echo "虚拟机初始化设置成功"
   
#设置系统重启
echo -e "\e[33;5;1m 请在10s内输入相关内容 \e[0m"
read -t 10 -p "是否需要重新启动虚拟机(yes/no):" change
if [  -z "$change" ]; then
      echo " "
      echo "输入超时，请稍后手动重启"  
      exit 1
    elif  [ $change == yes ] ;then
    shutdown -r 1 &> /dev/null
    echo "系统将在一分钟后重启"
    else
    echo "请稍后手动重启"
fi