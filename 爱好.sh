#! /bin.bash
echo "请选择你的爱好"  
select i in "唱" "跳" "RAP" "篮球" "music" "只因你太美"
do 
    case $i in
        唱|RAP|music)
            echo "唱歌有利于身心健康"
            ;;
        跳|篮球)
            echo "生命在于运动"
            ;;
        只因你太美)
            echo "你个小黑子，鸽鸽下的蛋你别吃"
            ;;
        *)
            echo "输出错误"
                  
    esac
break 
done