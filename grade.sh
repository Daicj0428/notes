#! /bin/bash 
#############################
read -t 10 -p "请输入你要查询的姓名：" name
if [ -z $name ] ;then
    echo ""
    echo "未检测到内容，自动退出"
    exit  1
fi
class_1=`cat /root/grade.txt | grep -i $name | awk '{print $3}'`
date_1=`cat /root/grade.txt | grep -i $name | awk '{print $4}'`
name_1=`cat /root/grade.txt | grep -i $name | awk '{print $1}'`
cji=`cat /root/grade.txt | grep -i $name | awk '{print $2}'`
uptime_1=`date "+%x%X"`
#############################
    if [ -z $name_1 ] ;then 
        echo "你所查询的考生未参与本次考试"
        exit
    else
        echo "本次查询时间为：$uptime_1"
        echo "考生${name_1}本次考试的成绩为：$cji"
        echo "考生${name_1}所在的班级为：${class_1}期"
        echo "考生${name_1}本次考试的时间为：$date_1"
    fi
        if  [ $cji -eq 100 ] ;then
            echo "简直完美!!!!"
        elif [ $cji -ge 90 ] && [ $cji -le 100 ] ;then
            echo "你可太优秀了"
        elif [ $cji -ge 75 ] && [ $cji -le 90 ] ;then
            echo "很优秀请继续保持"
        elif [ $cji -ge 60 ] && [ $cji -le 75 ] ;then
            echo "请加油，下次争取达到优秀"
        elif [ $cji -ge 40 ] && [ $cji -le 60 ] ;then
            echo "请来办公室喝茶"
        else 
            echo -e "\e[33;5;1m 请通知家长 \e[0m"
    fi