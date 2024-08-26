#!/bin/bash
#kubernetes集群更新脚本
#by:daichangjiang
#date:2024-08-17
#############################################################################################
file_num=$(ls /root/master-list.txt /root/work-list.txt | wc -l)  &> /dev/null
if [ $file_num -ne 2 ]; then
    echo "master-list.txt或work-list.txt文件不存在,请按照后续提示输入IP地址！"
    read -p "请输入master节点IP地址，多个IP地址之间用空格分隔：" master_list
    read -p "请输入worker节点IP地址，多个IP地址之间用空格分隔：" work_list
    echo "master节点IP地址：$master_list"
    echo "worker节点IP地址：$work_list"

#编写master-list.txt文件
    for ip in $master_list; do
        printf "%s\\n" "$ip" > master-list.txt
    done 

#编写work-list.txt文件
    for ip in $work_list; do
        printf "%s\\n" "$ip" > work-list.txt
    done 
fi
read -p "请输入更新版本号：" version
echo "更新版本号：$version"
master_num=$(wc -l < master-list.txt)
work_num=$(wc -l < work-list.txt)
echo "master节点数量：$master_num"
echo "worker节点数量：$work_num"
#############################################################################################
which pssh   &> /dev/null
if [ $? -ne 0 ]; then
    rpm -qa epel-release  &> /dev/null
    if [ $? -ne 0 ]; then
        echo "正在安装epel-release源！"
        yum install -y epel-release  &> /dev/null
        yum clean all                &> /dev/null
        yum makecache fast           &> /dev/null
    fi
    echo "正在安装pssh..."
    yum install -y pssh &> /dev/null
    if [ $? -ne 0 ]; then
        echo "pssh安装失败，请检查原因！"
        exit 1
    fi
fi
echo "pssh已安装！"

#master1节点更新
echo "正在更新master1节点..."
for f in kubernetes*.tar.gz; do [ -e "$f" ] && mv "$f" kubernetes-server-linux-amd64.tar.gz; done  &> /dev/null
ls /root/kubernetes-server-linux-amd64.tar.gz   &> /dev/null
if [ $? -ne 0 ]; then
    echo "kubernetes-server-linux-amd64.tar.gz文件不存在，请检查原因！"
    exit 1
fi
systemctl stop kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy  &> /dev/null
tar -xf kubernetes-server-linux-amd64.tar.gz --strip-components=3 -C /usr/local/bin kubernetes/server/bin/kube{let,ctl,-apiserver,-controller-manager,-scheduler,-proxy}  &> /dev/null
systemctl start kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy   &> /dev/null
sleep 20
kubectl get node | awk 'NR==2 {print $5}' > /tmp/master1_version.txt 
if [ "$version" = "$(cat /tmp/master1_version.txt)" ]; then
    echo "master1节点更新成功！，节点`kubectl get node | awk 'NR==2 {print $1}'`当前版本为：$(cat /tmp/master1_version.txt)"
fi

if [ $master_num = 2 ] && [ $work_num = 2 ]; then
    echo "master2节点更新..."
     pssh -h master-list.txt -i 'systemctl stop kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy'  &> /dev/null
    pscp.pssh -h master-list.txt  /usr/local/bin/kube{let,ctl,-apiserver,-controller-manager,-scheduler,-proxy} /usr/local/bin/    &> /dev/null
    sleep 20
    pssh -h master-list.txt -i 'systemctl start kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy'   &> /dev/null
    sleep 20
    kubectl get node | awk 'NR==3 {print $5}' > /tmp/master2_version.txt
    echo "master2节点更新成功！，节点`kubectl get node | awk 'NR==3 {print $1}'`当前版本为：$(cat /tmp/master2_version.txt)"
#worker节点更新
    pssh -h work-list.txt -i 'systemctl stop kubelet kube-proxy'   &> /dev/null
    pscp.pssh -h work-list.txt /usr/local/bin/kube{let,-proxy} /usr/local/bin/   &> /dev/null
    pssh -h work-list.txt -i 'systemctl start kubelet kube-proxy'   &> /dev/null
    sleep 20
    kubectl get node | awk 'NR==4 {print $5}' > /tmp/work_version.txt
    if [ "$version" = "$(cat /tmp/work_version.txt)" ]; then
        echo "worker1节点更新成功！，节点`kubectl get node | awk 'NR==5 {print $1}'`当前版本为：$(cat /tmp/work_version.txt)"
        kubectl get node | awk 'NR==5 {print $5}' > /tmp/work2_version.txt
        echo "worker2节点更新成功！，节点`kubectl get node | awk 'NR==5 {print $1}'`当前版本为：$(cat /tmp/work2_version.txt)"
    fi
fi

if [ $master_num = 2 ] && [ $work_num -ge 3 ]; then
    pssh -h master-list.txt -i 'systemctl stop kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy'  &> /dev/null
    pscp.pssh -h master-list.txt  /usr/local/bin/kube{let,ctl,-apiserver,-controller-manager,-scheduler,-proxy} /usr/local/bin/    &> /dev/null
    sleep 20
    pssh -h master-list.txt -i 'systemctl start kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy'   &> /dev/null
    sleep 20
    kubectl get node | awk 'NR==3 {print $5}' > /tmp/master2_version.txt
    echo "master2节点更新成功！，节点`kubectl get node | awk 'NR==3 {print $1}'`当前版本为：$(cat /tmp/master2_version.txt)"
#worker节点更新
    pssh -h work-list.txt -i 'systemctl stop kubelet kube-proxy'   &> /dev/null
    pscp.pssh -h work-list.txt /usr/local/bin/kube{let,-proxy} /usr/local/bin/   &> /dev/null
    pssh -h work-list.txt -i 'systemctl start kubelet kube-proxy'   &> /dev/null
    sleep 20
    for (( i=1; i<=$work_num; i++ )); do
        node_line=$((3+i))
        worker_version=$(kubectl get node | awk -v line="$node_line" 'NR==line {print $5}')
        worker_node=$(kubectl get node | awk -v line="$node_line" 'NR==line {print $1}')
        echo "worker${i}节点更新成功！，节点${worker_node}当前版本为：${worker_version}"
    done
fi

if [ $master_num = 3 ] && [ $work_num -ge 3 ]; then
    pssh -h master-list.txt -i 'systemctl stop kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy'  &> /dev/null
    pscp.pssh -h master-list.txt  /usr/local/bin/kube{let,ctl,-apiserver,-controller-manager,-scheduler,-proxy} /usr/local/bin/    &> /dev/null
    sleep 20
    pssh -h master-list.txt -i 'systemctl start kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy'   &> /dev/null
    sleep 20
    kubectl get node | awk 'NR==3 {print $5}' > /tmp/master2_version.txt
    echo "master2节点更新成功！，节点`kubectl get node | awk 'NR==3 {print $1}'`当前版本为：$(cat /tmp/master2_version.txt)"
    kubectl get node | awk 'NR==4 {print $5}' > /tmp/master3_version.txt
    echo "master3节点更新成功！，节点`kubectl get node | awk 'NR==4 {print $1}'`当前版本为：$(cat /tmp/master3_version.txt)"
#worker节点更新
    pssh -h work-list.txt -i 'systemctl stop kubelet kube-proxy'   &> /dev/null
    pscp.pssh -h work-list.txt /usr/local/bin/kube{let,-proxy} /usr/local/bin/   &> /dev/null
    pssh -h work-list.txt -i 'systemctl start kubelet kube-proxy'   &> /dev/null
    sleep 20
    for (( i=1; i<=$work_num; i++ )); do
        worker_node=$(kubectl get node | awk -v i=$((4+i)) 'NR==i {print $1}')
        worker_version=$(kubectl get node | awk -v i=$((4+i)) 'NR==i {print $5}')
        echo "worker${i}节点更新成功！，节点${worker_node}当前版本为：${worker_version}"
    done
fi
echo "恭喜您，Kubernetes集群更新成功！当前版本为：$version"
sleep 30
kubectl get node