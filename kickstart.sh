#/bin/bash
#无人值守自动安装脚本
#by daichangjiang
#日期：2024-4-26


#######################################
#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

#关闭selinux
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
getenforce

#配置本地yum源
mv /etc/yum.repos.d/* /opt/
mkdir /mnt/cdrom
mount /dev/cdrom /mnt/cdrom
echo -e "[centos]\nname=centos7\nbaseurl=file:///mnt/cdrom\ngpgcheck=0\nenabled=1" > /etc/yum.repos.d/centos7.repo
df -h |grep sr0
if [ $? -eq 0 ];then
    echo "已安装本地yum源"
else
    echo "本地源yum源安装失败，请手动安装"
    exit 
fi

#安装dhcp服务
yum install dhcp -y &> /dev/null

#配置dhcp服务
cat > /etc/dhcp/dhcpd.conf << EOF
option domain-name "example.org";
option domain-name-servers 114.114.114.114, 8.8.8.8;
default-lease-time 600;
max-lease-time 7200;
log-facility local7;
subnet 192.168.1.0 netmask 255.255.255.0 {
  range  192.168.1.100 192.168.1.200;
  option routers 192.168.1.2;          
  next-server 192.168.1.31;         
  filename "pxelinux.0"; 
}

EOF
#开启并设置开机自启dhcp服务
systemctl start dhcpd
systemctl enable dhcpd

# dchp_status=`systemctl status dhcpd | sed -n '/Active/p' | awk '{print $3}' | tr -d '( )'`
# if [ ${dhcp_status} == "running" ];then
#     echo "dhcp服务启动成功"
# else
#     echo "dhcp服务启动失败，请检查配置" 
# fi

#配置tftp服务
yum install  -y tftp-server xinetd &> /dev/null
 > /etc/xinetd.d/tftp
cat > /etc/xinetd.d/tftp << EOF
    service tftp
    {
            socket_type             = dgram
            protocol                = udp
            wait                    = yes
            user                    = root
            server                  = /usr/sbin/in.tftpd
            server_args             = -s /var/lib/tftpboot
            disable                 = no
            per_source              = 11
            cps                     = 100 2
            flags                   = IPv4
    }
EOF
systemctl start xinetd
systemctl enable xinetd
systemctl status xinetd &> /dev/null
systemctl start tftp

#安装lsof服务
yum install -y lsof &> /dev/null
lsof -i:69
if [ $? -eq 0 ];then
    echo "tftp服务启动成功"
else
    echo "tftp服务启动失败，请检查配置" 
fi

#配置使用PXE启动所需的相关文件
yum install -y system-config-kickstart syslinux &> /dev/null
mkdir /var/lib/tftpboot/pxelinux.cfg
cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot
cp /mnt/cdrom/images/pxeboot/* /var/lib/tftpboot/
cp /mnt/cdrom/isolinux/isolinux.cfg /var/lib/tftpboot/pxelinux.cfg/default

#修改default配置文件

cat > /var/lib/tftpboot/pxelinux.cfg/default << EOF
default linux
timeout 600

display boot.msg

# Clear the screen when exiting the menu, instead of leaving the menu displayed.
# For vesamenu, this means the graphical background is still displayed without
# the menu itself for as long as the screen remains in graphics mode.
menu clear
menu background splash.png
menu title CentOS 7
menu vshift 8
menu rows 18
menu margin 8
#menu hidden
menu helpmsgrow 15
menu tabmsgrow 13

# Border Area
menu color border * #00000000 #00000000 none

# Selected item
menu color sel 0 #ffffffff #00000000 none

# Title bar
menu color title 0 #ff7ba3d0 #00000000 none

# Press [Tab] message
menu color tabmsg 0 #ff3a6496 #00000000 none

# Unselected menu item
menu color unsel 0 #84b8ffff #00000000 none

# Selected hotkey
menu color hotsel 0 #84b8ffff #00000000 none

# Unselected hotkey
menu color hotkey 0 #ffffffff #00000000 none

# Help text
menu color help 0 #ffffffff #00000000 none

# A scrollbar of some type? Not sure.
menu color scrollbar 0 #ffffffff #ff355594 none

# Timeout msg
menu color timeout 0 #ffffffff #00000000 none
menu color timeout_msg 0 #ffffffff #00000000 none

# Command prompt text
menu color cmdmark 0 #84b8ffff #00000000 none
menu color cmdline 0 #ffffffff #00000000 none

# Do not display the actual menu unless the user presses a key. All that is displayed is a timeout message.

menu tabmsg Press Tab for full configuration options on menu items.

menu separator # insert an empty line
menu separator # insert an empty line

label linux
  menu label ^Install CentOS 7
  kernel vmlinuz
  append initrd=initrd.img inst.repo=ftp://192.168.1.31/pub inst.ks=ftp://192.168.1.31/ks.cfg

label check
  menu label Test this ^media & install CentOS 7
  menu default
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=CentOS\x207\x20x86_64 rd.live.check quiet

menu separator # insert an empty line

# utilities submenu
menu begin ^Troubleshooting
  menu title Troubleshooting

label vesa
  menu indent count 5
  menu label Install CentOS 7 in ^basic graphics mode
  text help
	Try this option out if you're having trouble installing
	CentOS 7.
  endtext
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=CentOS\x207\x20x86_64 xdriver=vesa nomodeset quiet

label rescue
  menu indent count 5
  menu label ^Rescue a CentOS system
  text help
	If the system will not boot, this lets you access files
	and edit config files to try to get it booting again.
  endtext
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=CentOS\x207\x20x86_64 rescue quiet

label memtest
  menu label Run a ^memory test
  text help
	If your system is having issues, a problem with your
	system's memory may be the cause. Use this utility to
	see if the memory is working correctly.
  endtext
  kernel memtest

menu separator # insert an empty line

label local
  menu label Boot from ^local drive
  localboot 0xffff

menu separator # insert an empty line
menu separator # insert an empty line

label returntomain
  menu label Return to ^main menu
  menu exit

menu end

EOF
#安装ftp服务
yum install -y vsftpd &> /dev/null
systemctl start vsftpd
systemctl enable vsftpd
vsftpd_us=`systemctl status vsftpd | sed -n '/Active/p' | awk '{print $3}' | tr -d '( )'`
if [ ${vsftpd_us} == "running" ];then
    echo "ftp服务启动成功"
else
    echo "ftp服务启动失败，请检查配置"  
fi

#配置ftp软件仓库
echo "/dev/sr0    /var/ftp/pub     iso9660     defaults        0 0" >> /etc/fstab
mount -a

#修改本地yum源名字
sed -i 's/centos/development/g' /etc/yum.repos.d/centos7.repo
yum clean all &> /dev/null
yum repolist

#配置kickstart文件
cat > /var/ftp/ks.cfg << EOF
#platform=x86, AMD64, 或 Intel EM64T
#version=DEVEL
# Install OS instead of upgrade
install
# Keyboard layouts
keyboard 'us'
# Root password
rootpw --plaintext 123456
# System language
lang zh_CN
# System authorization information
auth  --passalgo=sha512
# Use graphical install
graphical
# SELinux configuration
selinux --disabled
# Do not configure the X Window System
skipx


# Firewall configuration
firewall --disabled
# Network information
network  --bootproto=dhcp --device=ens33
# Halt after installation
halt
# System timezone
timezone Asia/Shanghai
# Use network installation
url --url="ftp://192.168.1.31/pub"
# System bootloader configuration
bootloader --location=mbr
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part /boot --fstype="xfs" --size=200
part swap --fstype="swap" --size=4096
part / --fstype="xfs" --grow --size=1

%post --interpreter=/bin/bash
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
mount /dev/sr0  /mnt/cdrom
echo "/dev/sr0               /mnt/cdrom               iso9660 defaults        0 0" >> /etc/fstab

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
#安装createrepo插件
 yum -y install createrepo &> /dev/null 
    if [ $? -eq 0 ] ;then
        echo "已安装createrepo插件"
    else
        echo "createrepo插件安装失败"    
    fi   

#创建本地源仓库
mkdir dcj
    if [ $? -eq 0 ] ;then
    echo "本地源目录创建成功"
    else
    echo "本地源目录创建失败"
    fi

mv /etc/yum.repos.d/*  /opt
    if [ $? -eq 0 ] ;then
        echo "系统源备份成功"
    else
        echo "系统源备份失败"
    fi

cp /mnt/cdrom/Packages/tree-1.6.0-10.el7.x86_64.rpm  /root/dcj
    if [ $? -eq 0 ] ;then
        echo "已将tree安装包移至本地源目录"
    else
        echo "tree安装包移至本地源失败"
    fi

createrepo /root/dcj/  &> /dev/null 
    if [ $? -eq 0 ] ;then
        echo "已经本地源目录设置为本地源仓库"
    else 
        echo "本地源目录设置本地源仓失败"
    fi

cat << eof >/etc/yum.repos.d/dcj.repo
[centos7]
name=dcj_centos7
baseurl=file:///root/dcj
enabled=1
gpgcheck=0  
 
eof
if [ $? -eq 0 ] ;then
    echo "本地yum源配置成功"
else
    echo "本地yum源配置失败"
    fi 


#安装软件测试包，清除缓存
yum -y install tree  &> /dev/null
    if [ $? -eq 0 ] ;then
        echo "tree插件已安装"
        yum clean all
        echo "清理本地源缓存"
    else
        echo "安装软件包测试失败"
    fi

yum repolist | grep dcj
sleep 5
    if [ $? -eq 0 ] ;then   
        echo "本地源仓库创建成功"
    else 
        echo "本地源仓库创建失败"
    fi

#将系统yum源移回yum.repos.d目录
mv /opt/* /etc/yum.repos.d/
    if [ $? -eq 0 ] ;then
        echo "已将系统yum源移至yum.repos.d目录"
        echo "虚拟机初始化设置成功"
    else 
        ehco "将系统yum源移至yum.repos.d目录失败"
    fi

#配置网络源
ping baidu.com -c 3 &>/dev/null
if [ $? -eq 0 ];then
    echo "网络正常"
    echo "准备安装基础工具"
    yum install -y vim wget net-tools lrzsz gcc gcc-c++ &>/dev/null
    
    wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo &>/dev/null
    
    echo "网络源配置完成"
    yum install -y epel-release &>/dev/null
   
    echo "扩展源配置成功"
    yum clean all &>/dev/null
    yum repolist &>/dev/null
   
#下载安装必备软件
    yum update -y &>/dev/null
    yum groupinstall -y "Development Tools" &>/dev/null
    yum install -y kernel-devel &>/dev/null
    yum install -y htop iotop nmon &>/dev/null
    yum install -y lrzsz &>/dev/null
else
    echo "当前无网络，请手动下载必备软件以及yum源"
fi
#关闭ssh远程连接NDS
    sed -i '/#UseDNS yes/c UseDNS no' /etc/ssh/sshd_config
    ystemctl restart sshd

%end

%packages
@base

%end

EOF

chmod +r /var/ftp/ks.cfg