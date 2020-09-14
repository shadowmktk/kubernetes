#!/bin/bash

yum -y install ntp ntpdate
ntpdate time.windows.com
systemctl enable ntpd && systemctl restart ntpd
sed -i "s@^\(SELINUX\)=.*@\1=disabled@" /etc/selinux/config && setenforce 0
systemctl disable firewalld && systemctl stop firewalld

# ÅäÖÃsysctl
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

# ÅäÖÃipvs
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- overlay
modprobe -- br_netfilter
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod +x /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules
lsmod | grep -E "ip_vs|nf_conntrack_ipv4"

# ½ûÓÃSwap
swapoff -a && sed -i '/swap/ s@^\(.*\)@\#\1@g' /etc/fstab

# ÅäÖÃdockerºÍkubernetesµÄyumÔ´
yum -y install yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF