#! /bin/bash
# by daichangjiang
#2024-4-11 18:00
#虚拟机初始化配置
##############################
fire=$(systemctl status firewalld | grep Active | awk '{print $3}'  | tr -d "( )")
selinux_get=`getenforce`
timedate_get=$(timedatectl | grep Time | awk '{print $3}')
timedate_set=Asia/Shanghai
##############################
#关闭防火墙
    if [ $fire == running ] ;then
        echo "设置关闭防火墙"
        systemctl stop firewalld
        echo "设置禁止开机自启防火墙"
        systemctl disable firewalld &> /dev/null
    elif [ $fire == dead ] ;then
        echo "防火墙已处于关闭状态"
    else
        echo "防火墙关闭失败"
    fi
#关闭selinux
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

#设置时区为shanghai
    if [ "$timedate_get" != "${timedate_set}" ] ;then
        echo "当前系统设置的时区为${timedate_get}"
        echo "正在将时区更改为${timedate_set}"
        timedatectl set-tiamzone ${timedate_set}
    elif [ "$timedate_get" == "${timedate_set}" ] ;then
        echo "当前系统时区为${timedate_set}"
    else
        echo "时区设置失败"
fi

#创建光盘挂载目录
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

#设置永久挂载
cat /etc/fstab | grep /dev/sr0  &> /dev/null
if [ $? -eq 0 ] ;then
    echo "/dev/sr0已永久挂载"
else
    echo "/dev/sr0未挂载，正在挂载"
    mount /dev/sr0  /mnt/cdrom  &> /dev/null
    echo "/dev/sr0               /mnt/cdrom               iso9660 defaults        0 0" >> /etc/fstab
fi

#配置本地yum源
cat << eof >/etc/yum.repos.d/centos.repo
[centos7]
name=centos7
baseurl=file:///mnt/cdrom
enabled=1
gpgcheck=0  
 
eof
if [ $? -eq 0 ] ;then
    echo "本地yum源配置成功"
else
    echo "本地yum源配置失败"
fi

mount -a &> /dev/null
df -h | grep /dev/sr0  &> /dev/null
    if [ $? -eq 0 ] ;then
        echo "永久挂载设置成功"
    else
        echo "永久挂载设置失败"
    fi
#92 - 169 行是配置本地yum源，可根据需要自行修改
# #安装createrepo插件 
#  yum -y install createrepo &> /dev/null 
#     if [ $? -eq 0 ] ;then
#         echo "已安装createrepo插件"
#     else
#         echo "createrepo插件安装失败"    
#     fi   

# # #创建本地源仓库
# mkdir dcj
#     if [ $? -eq 0 ] ;then
#     echo "本地源目录创建成功"
#     else
#     echo "本地源目录创建失败"
#     fi

# mv /etc/yum.repos.d/*  /opt
#     if [ $? -eq 0 ] ;then
#         echo "系统源备份成功"
#     else
#         echo "系统源备份失败"
#     fi

# cp /mnt/cdrom/Packages/tree-1.6.0-10.el7.x86_64.rpm  /root/dcj
#     if [ $? -eq 0 ] ;then
#         echo "已将tree安装包移至本地源目录"
#     else
#         echo "tree安装包移至本地源失败"
#     fi

# createrepo /root/dcj/  &> /dev/null 
#     if [ $? -eq 0 ] ;then
#         echo "已经本地源目录设置为本地源仓库"
#     else 
#         echo "本地源目录设置本地源仓失败"
#     fi

# cat << eof >/etc/yum.repos.d/dcj.repo
# [centos7]
# name=dcj_centos7
# baseurl=file:///root/dcj
# enabled=1
# gpgcheck=0  
 
# eof
# if [ $? -eq 0 ] ;then
#     echo "本地yum源配置成功"
# else
#     echo "本地yum源配置失败"
#     fi 


# #安装软件测试包，清除缓存
# yum -y install tree  &> /dev/null
#     if [ $? -eq 0 ] ;then
#         echo "tree插件已安装"
#         yum clean all &> /dev/null
#         echo "清理本地源缓存"
#     else
#         echo "安装软件包测试失败"
#     fi

# yum repolist | grep dcj &> /dev/null
# sleep 5
#     if [ $? -eq 0 ] ;then   
#         echo "本地源仓库创建成功"
#     else 
#         echo "本地源仓库创建失败"
#     fi

# #将系统yum源移回yum.repos.d目录
# mv /opt/* /etc/yum.repos.d/
#     if [ $? -eq 0 ] ;then
#         echo "已将系统yum源移至yum.repos.d目录"
#         echo "虚拟机初始化设置成功"
#     else 
#         ehco "将系统yum源移至yum.repos.d目录失败"
#     fi

#配置网络源
ping www.baidu.com -c 3 &>/dev/null
if [ $? -eq 0 ];then
    echo "网络正常"
    echo "准备安装基础工具"
    yum install -y vim wget net-tools lrzsz gcc gcc-c++ &>/dev/null
    
    wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo &>/dev/null
    wget   -O   /etc/yum.repos.d/epel.repo  http://mirrors.aliyun.com/repo/epel-7.repo & >>/dev/null
    echo "网络源配置完成"
    # yum install -y epel-release &>/dev/null
   
    echo "扩展源配置成功"
    yum clean all &>/dev/null
    yum repolist &>/dev/null
    yum makecache &>/dev/null
    echo "缓存更新完成"

#下载安装必备软件
    yum update -y &>/dev/null
    yum groupinstall -y "Development Tools" &>/dev/null
    yum install -y kernel-devel &>/dev/null
    yum install -y htop iotop nmon &>/dev/null
    yum install -y lrzsz &>/dev/null
else
    echo "当前无网络，请手动下载必备软件以及yum源"
fi
#配置ssh免密登录
sed -i '/#UseDNS yes/c UseDNS no' /etc/ssh/sshd_config
systemctl restart sshd
echo "ssh免密登录配置成功"

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