#! /bin/sbin
#2024年64月13日 16:11:08
##############################################

count=1
price=$(($RANDOM % 100))
##################################################
while true
do
	let count++
	read -t 10 -p "请输入你要猜的商品价格(0-100)：" num
	expr $num + 3 &> /dev/null
	if [ $? -eq 0 ];then
		if [ $[$count-1] \> 5 ] ;then
                        echo "您的次数已用完" 
                        exit
		fi
		if [ -z "$num" ];then
			echo "请输入你猜的价格"
		elif [ "$num" -lt "0" -o "$num" -gt "100" ];then
			echo "请输入正确的价格"
	    elif [ "$num" -gt "$price" ];then
	        echo "你出的价格为$num,猜高了，请继续"
	    elif [ "$num" -lt "$price" ];then
	        echo "你出价格为$num,猜低了，请继续"
		elif [ "$num" -eq "$price" ];then
			echo "恭喜你猜对了,你一共猜了$[$count-1] 次"
			exit
	
		else
			echo "请输入(1-1000)正确的结果"
		fi
	else
		echo "请输入(1-1000)正确的结果"
	fi
done

