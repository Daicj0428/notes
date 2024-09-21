#! /bin/bash
ip="192.168.0"
rm -rf errory.txt success.txt &> /dev/null
concurrent=30                      #设置并发数量变量
#########################################
#用来存放所有后台进程的PID
pids=()  


for i in `seq 1 254`; do
	(
	ping -c 1 -w 1 $ip.$i  &> /dev/null
	if [ $? -ne 0 ] ; then
		echo "$ip.$i" >> errory.txt
#		echo "$ip.$i 暂时无法通信，请检查原因！" 
	else 
		echo "$ip.$i" >> success.txt
		echo "$ip.$i 可以通信"   
	fi
	) &      #& 表示放入后台执行
#控制并发数
    pids+=($!)
    if [ ${#pids[@]} -ge $concurrent ]; then
        wait   # 等待任意一个进程完成
        pids=()  # 清空进程数组
    fi
done

#等待所有进程完成
wait

#统计结果
er=`cat errory.txt |wc -l`
sc=`cat success.txt | wc -l`
echo "当前不能通信的IP的总数为$er"
echo "当前能通信的IP的总数为$sc"
