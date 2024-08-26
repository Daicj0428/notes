#!/bin/bash
#ssh免密登陆脚本

#####################################################################
# 用户配置
USER="root" 
REMOTE_IPS=("192.168.1.29" "192.168.1.28" "192.168.1.27" "192.168.1.26") 
SSH_KEY_DIR="$HOME/.ssh"
SSH_KEY="$SSH_KEY_DIR/id_rsa"
SSH_PUB_KEY="$SSH_KEY.pub"
SSH_PASS="123456"  

# 检查SSH密钥是否存在，如果不存在，则生成新的密钥对
if [ ! -f "$SSH_KEY" ]; then
    echo "SSH私钥不存在，正在生成新的SSH密钥对..."
    ssh-keygen -t rsa -b 2048 -f "$SSH_KEY" -N ""
    echo "SSH密钥对生成完毕。"
else
    echo "SSH密钥对已存在。"
fi

# 创建expect脚本文件
EXPECT_SCRIPT=$(mktemp /tmp/expect_script.XXXX)

# 写入expect脚本内容
cat > "$EXPECT_SCRIPT" << EOF
#!/usr/bin/expect -f
set timeout -1
set ip [lindex $argv 0]
set pub_key [lindex $argv 1]
set user [lindex $argv 2]
set pass [lindex $argv 3]
spawn ssh-copy-id -i $pub_key $user@$ip
expect "yes/no" { send "yes\\r" }
expect "password:" { send $pass\\r }
expect eof
EOF

# 给expect脚本执行权限
chmod +x "$EXPECT_SCRIPT"

# 循环IP地址数组，将公钥复制到每个远程服务器
for IP in "${REMOTE_IPS[@]}"; do
    echo "正在将公钥复制到 $IP..."
    # 执行expect脚本
        
    if [ $? -eq 0 ]; then
        echo "公钥已成功复制到 $IP."
    else
        echo "复制公钥到 $IP 失败。"
    fi
done

# 删除expect脚本文件
rm -f "$EXPECT_SCRIPT"

echo "所有操作完成。"