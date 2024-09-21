#!/bin/bash
ip="192.168.0"

# 检查 fping 是否已安装
if ! command -v fping &> /dev/null; then
    echo "fping 未找到，正在安装..."

    # 安装 EPEL 仓库
    yum install -y epel-release || { echo "安装 EPEL 失败"; exit 1; }

    # 更新 yum 缓存
    yum makecache || { echo "更新 yum 缓存失败"; exit 1; }

    # 安装 fping
    yum install -y fping || { echo "安装 fping 失败，请手动安装"; exit 1; }
fi

rm -rf errory.txt success.txt &> /dev/null

# 使用 fping 检查可达的 IP
fping -a -g "$ip.1" "$ip.254" 2>/dev/null | tee success.txt | while read addr; do
    echo "$addr 可以通信"
done

# 确保 success.txt 存在
if [[ ! -s success.txt ]]; then
    echo "没有成功通信的IP"
    exit 0
fi

# 处理未通信的 IP
for i in $(seq 1 254); do
    if ! grep -q "$ip.$i" success.txt; then
        echo "$ip.$i" >> errory.txt
    fi
done

er=$(wc -l < errory.txt)
sc=$(wc -l < success.txt)

echo "当前能通信的IP的总数为$sc"
echo "当前不能通信的IP的总数为$er"
