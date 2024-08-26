#1 /bin/bash

cutip(){
        ip=`ifconfig ens33 | grep netmask | awk '{print $2}'`
        echo "本机ip地址为：$ip"
}
cpu_info(){
        cpu=`iostat`
        echo -e "cpu信息如下：\n$cpu"
}       
mem_use(){
        mem_free=`free -m | grep Mem | awk '{print $4}'`
        mem_totle=`free -m | grep Mem | awk '{print $2}'`
        mem_used=`echo "scale=4;(1-$mem_free/$mem_totle)*100" | bc`
        echo "本机内存使用率为：`printf "%.2f%%" ${mem_used}`"
                                    
}
dev_use(){
        dev=`df -h`
        echo -e "本机磁盘使用情况如下\n$dev"
}
delimiter(){ 
        echo -e "\e[36;1m+++++++++++++++++++++++++++++++++++\e[0m"
}
memnu(){
        delimiter
        echo -e "\e[32m
        1 显示本地计算机ip地址
        2 显示cpu信息
        3 显示内存使用情况
        4 显示磁盘使用情况
        5 打印菜单
        6 退出 \e[0m"
        delimiter
}
memnu

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
                                cutip
                                delimiter
                                ;;
                        2)
                                cpu_info
                                delimiter
                                ;;
                        3)
                                mem_use
                                delimiter
                                ;;
                        4)
                                dev_use
                                delimiter
                                ;;
                        5)
                                memnu;;
                        6)
                                break;;
                        *)
                                echo -e "\e[36;1m 选项错误！\e[0m"
                                continue
                esac                
        fi
done