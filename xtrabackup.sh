#!/bin/bash
#xtrabackup全备和增量备份+数据恢复脚本 周日全备 每天一增倍 周六数据恢复
#by daichangjiang
#2024-5-20
#########################################
xtrabackup1="/opt/mysqlbackup/xback"
backup_add="/opt/mysqlbackup/add"
file_name="--defaults-file=/etc/my.cnf"
socket_name="--socket=/usr/local/mysql/mysql.sock"
user_name="--user=root"
password_name="--password=123456"
backup_bak="/opt/mysqlbackup/xback.bak"
date_dir=`date | awk '{print $4}'`
#########################################
#安装xtrabackup软件
which innobackupex &> /dev/null
if [ $? -ne 0 ]; then
    echo "正在安装xtarbackup软件"
    wget https://downloads.percona.com/downloads/Percona-XtraBackup-2.4/Percona-XtraBackup-2.4.29/binary/redhat/7/x86_64/percona-xtrabackup-24-2.4.29-1.el7.x86_64.rpm &> /dev/null
    yum -y install percona-xtrabackup-24-2.4.29-1.el7.x86_64.rpm &> /dev/null
fi
#创建全备目录
ls $xtrabackup1 &> /dev/null
if [ $? -ne 0 ]; then
    mkdir -p $xtrabackup1
fi
#设置每星期日进行全备
date | grep 星期日
if [ $? -eq 0 ]; then
    echo "正在进行全备"
    innobackupex $file_name $socket_name $user_name $password_name $xtrabackup1 &> /dev/null
else
    echo "当前是$date_dir 不进行全备"
fi 
#增量备份
ls $backup_add &> /dev/null
if [ $? -ne 0 ]; then 
    mkdir -p $backup_add
fi
#########################################
old_backup=`ls -t $xtrabackup1 | head -n 1`
backup_num=`ls -t $xtrabackup1 | wc -l`
new_add=`ls -t $backup_add | head -n 1`
add_num=`ls -t $backup_add | wc -l`
#########################################
if [ $backup_num -lt 1 ]; then
    echo "当前暂未进行全备，正在进行全备"
    innobackupex $file_name $socket_name $user_name $password_name $xtrabackup1 &> /dev/null
fi
if [ $add_num -lt 1 ]; then
    echo "当前暂未进行增量备份,正在进行第一次增量备份"
    innobackupex $file_name $socket_name $user_name $password_name --incremental $backup_add --incremental-basedir=$xtrabackup1/$old_backup &> /dev/null
else
    date | grep 星期一
    if [ $? -eq 0 ]; then
        echo "正在进行第一次增量备份"
        innobackupex $file_name $socket_name $user_name $password_name --incremental $backup_add --incremental-basedir=$xtrabackup1/$old_backup &> /dev/null
    elif [ $date_dir == "星期日" ];then
        echo "今天星期日不进行增量备份"
    else
        echo "正在进行增量备份"
        innobackupex $file_name $socket_name $user_name $password_name --incremental $backup_add --incremental-basedir=$backup_add/$new_add &> /dev/null
    fi
fi
#数据恢复
if [ $date_dir == "星期六" ];then
#全备恢复
innobackupex --apply --redo-only $xtrabackup1/$old_backup &> /dev/null
#增量备份恢复
mk_dir=`ls $backup_add`
    for i in $mk_dir
    do
        if [ $i != $new_add ]; then
            innobackupex --apply-log --redo-only $xtrabackup1/$old_backup --incremental-dir=$backup_add/$i &> /dev/null
        else
            innobackupex --apply-log  $xtrabackup1/$old_backup --incremental-dir=$backup_add/$i &> /dev/null
        fi
    done
#整合备份
innobackupex --apply-log $xtrabackup1/$old_backup &> /dev/null
systemctl stop mysqld
#备份data、add目录
cd $backup_bak
tar -zcvf  data-$(date +%F).tar.gz /data/mysql/data/* --remove-files &> /dev/null
tar -zcvf  add-$(date +%F).tar.gz $new_add/* --remove-files &> /dev/null
chown -R mysql:mysql /data/mysql/data
#恢复数据
innobackupex --copy-back $xtrabackup1/$old_backup &> /dev/null
    if [ $? -eq 0 ]; then
        echo "数据恢复成功"
        systemctl start mysqld
        cd $backup_bak
        tar -zxcf  old-$(date +%F).tar.gz $xtrabackup1/* --remove-files  &> /dev/null
    else
        echo "数据恢复失败"
    fi
else
    echo "今天不是星期六，不进行数据恢复"
fi
#设置删除超过三十天的压缩包 
find $backup_bak/ -type f -ctime +30 -name "*.gz" -exec rm -rf {} \;