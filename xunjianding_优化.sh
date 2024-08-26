#1 /bin/bash
#巡检脚本
#by Dai
#2024-4-17
####################################################
time=$(date "+%F %H:%M:%S")
host=$(hostname)
webhook='https://oapi.dingtalk.com/robot/send?access_token=1a136e0122572f16f5d14c6633b71e3fc104f9e7406c9ec80ca318d61dd2c0ae'
THRESHOLD=70

function msgding()	{
curl $webhook -H "Content-Type: application/json" -d "
{
	\"msgtype\": \"markdown\",
	\"markdown\": {	
\"title\": \"告警\", 
\"text\": \"
## 傻呗出问题了! \n
## 时间: $time \n
主机: $host \n
服务: $1 \n
注意排查原因!
![long](https://imgs.qiubiaoqing.com/qiubiaoqing/imgs/63973daa74dfcGts.gif)\"
},
	"at": {
		"isAtAll": true
		}
	}"
}
####################################################
#系统错误日志检检查
sys_worry(){
syswrroy=`cat /var/log/messages |grep -iE "fail|error|fatal|critical" | wc -l`
if [ $syswrroy -gt 0 ];then
	echo "系统日志暂未出现问题！当前错误日志数为: $syswrroy "
else 
	echo "系统日志出现问题"
	msgding "系统日志出现问题 "
fi
}
#文件系统使用率
mem_user(){
df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' | while read output;
do
# 当前使用率
	usep=$(echo $output | awk  '{print $1}' | cut -d'%' -f1  )
# 文件系统名称
	partition=$(echo $output | awk '{print $2}' )
		if [ $usep -ge $THRESHOLD ]; then
			echo "文件系统$partition 使用率为$usep% 超过了$THRESHOLD%。"
			msgding "$partition文件系统使用率超过了$THRESHOLD%，当前为$usep%"
		fi
done
}
#文件系统i节点使用率
iod_used(){
df -i | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' | while read output;
do
# i节点使用率
	usep_iod=$(echo $output | awk '{ print $1}' | cut -d'%' -f1  )
# 文件系统名称
	partition_iod=$(echo $output | awk '{ print $2 }' )
		if [ $usep_iod -ge $THRESHOLD ]; then
			echo "文件系统$partition_iod i节点使用率为$usep_iod% 超过了$THRESHOLD%。"
			msgding "$partition_iod i节点使用率超过了$THRESHOLD%，当前为$usep_iod%"
		fi
done
}
#文件系统挂载检查
mount_type(){
# 获取df命令输出中的文件系统列表
df_filesystems=$(df -h | grep -v tmpfs| awk '!/boot/{print $1}' | sed '1d')

# 获取fstab文件中的文件系统列表
fstab_filesystems=$(awk '!/^#/ && !/UUID/ && !/swap/ && NF {print $1}' /etc/fstab)

# 比较两个列表，找出在fstab文件中存在但df中未列出的文件系统
for fs in $fstab_filesystems; do
    if ! echo "$df_filesystems" | grep -q "$fs"; then
        echo "文件系统 $fs in /etc/fstab 但没在 df"
		msgding "文件系统 $fs in /etc/fstab 但没在 df"
    else    
        echo "文件系统全都设置永久挂载了"
	fi
done

# 检查df列出的文件系统是否都在fstab中
for fs in $df_filesystems; do
    if ! echo "$fstab_filesystems" | grep -q "$fs"; then
        echo "文件系统 $fs 在df存在,但不在 /etc/fstab"
		msgding "文件系统 $fs 在df存在,但不在 /etc/fstab"
	else 
       echo "文件系统均已设置了临时及永久挂载"
    fi
done
}
#僵尸进程检查
defunc_num(){
defunc1=`ps -ef|grep defunc | wc -l`
	if [ $defunc1 -ne 1 ];then
		echo "当前系统存在僵尸进程"
		msgding "当前系统存在僵尸进程,个数为：$[$defunc1-1]"
	else 
		echo "当前系统不存在僵尸进程"
	fi
}
#patrolagent进程检查
patrolagent_num(){
patrolagent1=`ps -ef |grep patrolagent |wc -l`
	if [ $defunc1 -ne 1 ];then
		echo "当前系统patrolagent进程不正常"
		msgding "当前系统patrolagent进程不正常,个数为：$[$dpatrolagent1-1]"
	else
		echo "当前系统patrolagent进程正常"
	fi
}
#ntp进程检查
ntp_num(){
ntp1=`ps -ef|grep ntpd |wc -l`
	if [ $defunc1 -ne 1 ];then
		echo "当前系统ntp进程不正常"
		msgding "当前系统ntp进程不正常,个数为：$[$ntp1-1]"
	else
		echo "当前系统ntp进程正常"
	fi
}
#NTP授时状态
ntp_state(){
/usr/sbin/ntpq -p |grep '*'
	if [ $? -eq 0 ];then
		echo "表示当前时间源有效"
	else
		echo "当前没有有效的时间源"
		msgding "当前没有有效的时间源"
	fi
}
#父进程为1的非root用户检查
ppid_root(){
ppid1=`ps -o pid,ppid,uid --ppid 1 | grep -v 0 | wc -l`
	if  [ $ppid1 -gt 0 ];then
		echo "当前存在父进程为1的非root用户"
		msgding "当前存在父进程为1的非root用户"
	else
		echo "当前不存在父进程为1的非root用户"
	fi
}
#交换空间
swap_space(){
swap_take=30
swap_used=`free | awk 'NR==3 {print int($3/$2 *100)}'`
	if [ $swap_used -gt $swap_take ];then
		echo "当前swap空间使用率当前为$(printf "%.2f%%" ${swap_mem}) 超过了${swap_take}%"
		msgding "当前swap空间使用率当前为$(printf "%.2f%%" ${swap_mem}) 超过了${swap_take}%"
	else
		echo "当前swap空间充裕"
    fi
}
#网络传输检查

#主机解析检查
host_name(){
hosts_ip=`cat /etc/hosts |grep 127.0.0.1 | wc -l`
	if [ $hosts_ip -ge 1 ];then
		echo "主机解析检查正常"
	else
		echo "主机解析检查出现问题"
		msgding "主机解析检查出现问题，未匹配到127.0.0.1"
	fi
}
#网络连接数及状态检测
nat_state(){
lISTEN_num=`netstat -antup | grep LISTEN | wc -l`
ESTABLISHED_num=`netstat -antup | grep ESTABLISHED | wc -l`
CLOSE_WAIT=`netstat -antup | grep CLOSE_WAIT | wc -l`
FIN_WAIT=`netstat -antup | grep FIN_WAIT | wc -l`
if [ $lISTEN_num -ge 10 ] && [ $ESTABLISHED_num -ge 10 ] && [ $CLOSE_WAIT -le 100 ] && [ $FIN_WAIT ];then
    echo "正常"
else
    echo "网络连接状态数量出现问题"
	msgding "网络连接状态数量出现问题"
fi
}
#路由器状态
ug_state(){
uG_num=`route | grep UG | wc -l`
ping_num=`ping -c 3  0.0.0.0 | awk 'NR==7 {print $6}' | cut -d '%' -f1`
if [ $uG_num -eq 1 ];then 
    if [ $ping_num -le 25 ];then 
        echo "当前网络连接未出现问题"
    fi
else    
    echo "当前路由连接出现问题"
	msgding "当前路由连接出现问题"
fi
}
#查询绑定网卡链路状态是否正常

#检查rootvg中剩余的空间大小

#检查lv状态是否可用
lv_state(){
lv_status=`lvdisplay | grep "LV Status"| awk 'NR==1 {print $3}'`
	if [ $lv_status == available ];then
		echo "当前LV状态为可用"
	else 
		echo "当前lv状态为不可用"
	fi
}
#检查pv状态是否可用
pv_stste(){
Pv_status=`pvdisplay | grep "PV Status"| awk 'NR==1 {print $3}'`
	if [ $Pv_status == allocatable ];then
		echo "当前PV状态为可用"
	else 
		echo "当前Pv状态为不可用"
		msgding "当前Pv状态为不可用"
	fi
}
#检查vg状态是否可用
vg_state(){
vg_status=`vgdisplay -v | grep "VG Status"| awk '{print $3}'`
	if [ $vg_status == resizable ];then
		echo "当前vg状态为可用"
	else 
		echo "当前vg状态为不可用"
	fi
}
#检查当前同时登陆的用户数
who_state(){
who_num=`who | wc -l | awk '{print $1}'`
	if [ $who_num -lt 10 ];then
		echo "当前登陆用户数正常"
	else
		echo "当前登陆用户数异常数量为：$who_num "
		msgding "当前登陆用户数异常数量为：$who_num "
	fi 
}
#特权用户检查
root_state(){
root_num=`awk -F: '$3==0 {print $1}' /etc/passwd |wc -l`
	if [ $root_num -eq 1 ];then
		echo "当前特权用户数量正常"
	else
		echo "当前特权用户数量异常，数量为$root_num"
		msgding "当前特权用户数量异常，数量为$root_num"
	fi
}
#mail日志文件大小检查
mail_sizes(){
mail_size=`find /var/spool/mail -type f -size +64M | wc -l`
	if [ $mail_size -gt 0 ];then
		echo "mail日志文件出现了大于64M的文件，个数为$mail_size"
		msgding "mail日志文件出现了大于64M的文件，个数为$mail_size"
	else
		echo "mail日志文件暂未出现大于64M的文件"
	fi
}
#cpu利用率检查
cpu_state(){
cpu_num=`sar 2 2 | grep -ivE "cpu" | awk '{print $8}' | awk '{if($1<70) print $0}' | sed '/^$/d'|wc -l`
	if [ $cpu_num -eq 0 ];then
		echo "当前cpu的使用率正常"
	else
		echo "当前cpu的使用率不正常，低于70%的有$cpu_num 个"
		msgding "当前cpu的使用率不正常，低于70%的有:$cpu_num 个"
	fi
}
#最耗cpu进程检查
cpu_maxnum(){
cpu_max=`ps aux | awk '1d' | awk '($3>30) {print $0}' | wc -l`
	if [ $cpu_max -eq 0 ];then
		echo "当前cpu损耗正常"
	else
		echo "当前cpu损耗异常，超过30%的有:$cpu_num 个 "
		msgding "当前cpu损耗异常，超过30%的有:$cpu_num 个 "
	fi
}
#操作系统内存利用率检查
sys_usage(){
mem_ut=`free | sed -n 2p | awk '{print int($3/$2*100)}'`
	if [ $mem_ut -le 70 ];then
		echo "当前操作系统内存利用率无异常"
	else
		echo "当前操作系统内存利用率出现异常,使用率为:$mem_ut"
		msgding "当前操作系统内存利用率出现异常,使用率为:$mem_ut"
	fi
}
#资源利用
Res_usage(){
ps_use=`ps auxwww |sed '1d' |awk '( $4 > 20 ) {print $0}' |wc -l`
	if [ $ps_use -eq 0 ];then
		echo "当前资源利用正常"
	else
		echo "当前资源利用异常，超过20%的有:$ps_use 个 "
		msgding "当前资源利用异常，超过20%的有:$ps_use 个"
	fi
}

#分隔符
delimiter(){
    echo -e "\e[33m>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\e[0m"
}

#菜单
memnu1(){
       delimiter
        echo -e "\e[36m
        1   文件系统使用率检查
        2   文件系统i节点使用率检查
        3   文件系统挂载检查
        4   菜单
        5   返回上一级菜单 \e[0m"
        delimiter
}
memnu2(){
       delimiter
        echo -e "\e[36m
        1   僵尸进程检查
        2   patrolagent进程检查
        3   ntp进程
        4   NTP授时状态
        5   父进程为1的非root用户检查
        6   菜单
        7   返回上一级菜单 \e[0m"
        delimiter
}
memnu3(){
       delimiter
        echo -e "\e[36m
        1   网络传输检查
        2   主机解析检查
        3   网络连接及状态检查
        4   路由状态检查
        5   绑定网卡链路状态是否正常
        6   菜单
        7   返回上一级菜单 \e[0m"
        delimiter
}
memnu4(){
       delimiter
        echo -e "\e[36m
        1   rootvg剩余空间检查
        2   lv状态检查
        3   pv状态检查
        4   vg状态检查
        5   菜单
        6   返回上一级菜单 \e[0m"
        delimiter
}
memnu5(){
       delimiter
        echo -e "\e[36m
        1   登陆情况检查
        2   特权用户检查
        3   mail日志文件大小检查
        4   菜单
        5   返回上一级菜单 \e[0m"
        delimiter
}
memnu6(){
       delimiter
        echo -e "\e[36m
        1   cpu利用率检查
        2   最耗cpu进程检查
        3   操作空间利用率检查
        4   最耗内存的进程检查
        5   菜单
        6   返回上一级菜单 \e[0m"
        delimiter
}
#主菜单
memnumax(){
        delimiter
        echo -e "\e[36m
        1   错误日志
        2   文件系统
        3   进程
        4   交换空间
        5   网络
        6   卷组状态
        7   系统安全
        8   资源利用
        9   查看菜单
        10  退出 \e[0m"
        delimiter
}
memnumax

while true
do      
        read -t 10 -p "请输入你的查看选项：" num
        if [ -z $num ];then
                echo " "
                echo -e "\e[31m 超时，请重新输入! \e[0m"
                continue
        elif [ $num -le 10 -o $num -ge 1 ];then
                case $num in
                        1)
                                sys_worry
                                continue
                                ;;
                        2)
                            memnu1
                                while true 
                                do
                                    read -t 10 -p "请输入你的查看选项：" num
                                    if [ -z $num ];then
                                        echo " "
                                        echo -e "\e[31m 超时，请重新输入! \e[0m"
                                        continue
                                    elif [ $num -le 5 -o $num -ge 1 ];then
                                    case $num in
                                        1)
                                            mem_user
                                            continue
                                            delimiter
                                            ;;
                                        2)
                                            iod_used
                                            continue
                                            delimiter
                                            ;;
                                        3)
                                            mount_type
                                            continue
                                            delimiter
                                            ;;
                                        4)
                                            memnu1;;
                                        5)
                                            break ;;       
                                        *)
                                            echo -e "\e[36;1m 选项错误！\e[0m"
                                            continue  
                                    esac
                                    fi
                                done
                                delimiter
                                ;;
                        3)
                            memnu2
                                while true 
                                do
                                    read -t 10 -p "请输入你的查看选项：" num
                                    if [ -z $num ];then
                                        echo " "
                                        echo -e "\e[31m 超时，请重新输入! \e[0m"
                                        continue
                                    elif [ $num -le 7 -o $num -ge 1 ];then
                                    case $num in
                                        1)
                                            defunc_num
                                            continue
                                            delimiter
                                            ;;
                                        2)
                                            patrolagent_num
                                            continue
                                            delimiter
                                            ;;
                                        3)
                                            ntp_num
                                            continue
                                            delimiter
                                            ;;
                                        4)
                                            ntp_state
                                            continue
                                            delimiter
                                            ;;                                        
                                        5)
                                            ppid_root
                                            continue
                                            delimiter
                                            ;;                                        
                                        6)
                                            memnu2;;
                                        7)
                                            break;;       
                                        *)
                                            echo -e "\e[36;1m 选项错误！\e[0m"
                                            continue  
                                    esac
                                    fi
                                done
                                delimiter
                                ;;
                        4)
                                swap_space
                                delimiter
                                ;;
                        5)
                           memnu3
                                while true 
                                do
                                    read -t 10 -p "请输入你的查看选项：" num
                                    if [ -z $num ];then
                                        echo " "
                                        echo -e "\e[31m 超时，请重新输入! \e[0m"
                                        continue
                                    elif [ $num -le 7 -o $num -ge 1 ];then
                                    case $num in
                                        1)
                                            echo -e "\e[5;1m暂未设置\e[0m"
                                            continue
                                            delimiter
                                            ;;
                                        2)
                                            host_name
                                            continue
                                            delimiter
                                            ;;
                                        3)
                                            nat_state
                                            continue
                                            delimiter
                                            ;;
                                        4)
                                            ug_state
                                            continue
                                            delimiter
                                            ;;                                        
                                        5)
                                            echo -e "\e[5;1m暂未设置\e[0m"
                                            continue
                                            delimiter
                                            ;;                                        
                                        6)
                                            memnu3;;
                                        7)
                                            break;;       
                                        *)
                                            echo -e "\e[36;1m 选项错误！\e[0m"
                                            continue  
                                    esac
                                    fi
                                done
                                delimiter
                                ;;
                        6)
                           memnu4
                                while true 
                                do
                                    read -t 10 -p "请输入你的查看选项：" num
                                    if [ -z $num ];then
                                        echo " "
                                        echo -e "\e[31m 超时，请重新输入! \e[0m"
                                        continue
                                    elif [ $num -le 6 -o $num -ge 1 ];then
                                    case $num in
                                        1)
                                            echo -e "\e[5;1m暂未设置\e[0m"
                                            continue
                                            delimiter
                                            ;;
                                        2)
                                            lv_state
                                            continue
                                            delimiter
                                            ;;
                                        3)
                                            pv_stste
                                            continue
                                            delimiter
                                            ;;
                                        4)
                                            vg_state
                                            continue
                                            delimiter
                                            ;;                                                                           
                                        5)
                                            memnu4;;
                                        6)
                                            break;;       
                                        *)
                                            echo -e "\e[36;1m 选项错误！\e[0m"
                                            continue  
                                    esac
                                    fi
                                done
                                delimiter
                                ;;
                        7)
                           memnu5
                                while true 
                                do
                                    read -t 10 -p "请输入你的查看选项：" num
                                    if [ -z $num ];then
                                        echo " "
                                        echo -e "\e[31m 超时，请重新输入! \e[0m"
                                        continue
                                    elif [ $num -le 5 -o $num -ge 1 ];then
                                    case $num in
                                        1)
                                            who_state
                                            continue
                                            delimiter
                                            ;;
                                        2)
                                            root_state
                                            continue
                                            delimiter
                                            ;;
                                        3)
                                            mail_sizes
                                            continue
                                            delimiter
                                            ;;                                                                         
                                        4)
                                            memnu5;;
                                        5)
                                            break;;
                                        *)
                                            echo -e "\e[36;1m 选项错误！\e[0m"
                                            continue       
                                    esac
                                    fi
                                done
                                delimiter
                                ;;
                        8)
                           memnu6
                                while true 
                                do
                                    read -t 10 -p "请输入你的查看选项：" num
                                    if [ -z $num ];then
                                        echo " "
                                        echo -e "\e[31m 超时，请重新输入! \e[0m"
                                        continue
                                    elif [ $num -le 6 -o $num -ge 1 ];then
                                    case $num in
                                        1)
                                            cpu_state
                                            continue
                                            delimiter
                                            ;;
                                        2)
                                            cpu_maxnum
                                            continue
                                            delimiter
                                            ;;
                                        3)
                                            sys_usage
                                            continue
                                            delimiter
                                            ;;
                                        4)
                                            Res_usage
                                            continue
                                            delimiter
                                            ;;                                                                           
                                        5)
                                            memnu6;;
                                        6)
                                            break;;       
                                        *)
                                            echo -e "\e[36;1m 选项错误！\e[0m"
                                            continue  
                                    esac
                                    fi
                                done
                                delimiter
                                ;;
                        9)
                                memnumax;;
                        10)
                                break;;
                        *)
                                echo -e "\e[36;1m 选项错误！\e[0m"
                                continue
                esac                
        fi
done