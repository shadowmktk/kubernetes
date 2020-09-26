#!/bin/bash

############################################################
# 下载cfssl工具集
# 函数使用命令：cfssl_download
function cfssl_download() {
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 && \mv cfssl_linux-amd64 /usr/bin/cfssl
[[ $? -ne 0 ]] && exit 1
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 && \mv cfssljson_linux-amd64 /usr/bin/cfssljson
[[ $? -ne 0 ]] && exit 1
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 && \mv cfssl-certinfo_linux-amd64 /usr/bin/cfssl-certinfo
[[ $? -ne 0 ]] && exit 1
chmod +x /usr/bin/{cfssl,cfssljson,cfssl-certinfo}
}

############################################################
# 生成CA配置文件，CA证书是集群所有节点共享的，只需要创建一个 CA 证书，后续创建的所有证书都由它签名
# 函数使用命令：ca_config
function ca_config() {
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
          "signing",
          "key encipherment",
          "server auth",
          "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF
}

# 生成CA证书签名请求
# 函数使用命令：ca_csr
function ca_csr() {
cat > ca-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
}

# 生成CA证书和私钥
# 函数使用方法（传参数给函数）：ca_cert /usr/local/src/ssl/ca-csr.json
function ca_cert() {
# 指定ca-csr.json文件全路径
# CA_CSR=/usr/local/src/ssl/ca-csr.json
CA_CSR=$1
cfssl gencert -initca ${CA_CSR:-ca-csr.json} | cfssljson -bare ca
echo ""
echo "#########################################"
[[ -f $K8S_SSL/ca.pem ]] && echo "ca_cert_file=$K8S_SSL/ca.pem" || exit 1
[[ -f $K8S_SSL/ca-key.pem ]] && echo "ca_key_file=$K8S_SSL/ca-key.pem" || exit 1
echo "#########################################"
}

############################################################
# 创建etcd证书签名请求
# 注：hosts字段指定授权使用该证书的etcd节点IP或域名列表
# 函数使用方法，必须指定一个数组变量给函数，示例如下：
# 必须传参数，必须传参数，必须传参数，重要事情说三遍
# 定制HOSTS数组变量，格式必须跟以下一样
#HOSTS=(
#192.168.30.145
#192.168.30.146
#192.168.30.147
#192.168.30.148
#192.168.30.149
#192.168.30.150
#)
# 函数使用命令：etcd_csr $HOSTS
function etcd_csr() {
[[ -z $1 ]] && exit 1
ETCD_HOSTS=$1
M=0
for line in ${ETCD_HOSTS[@]}
do
    Array_1[$M]=\"$line\"\,
    ((M++))
done
Array_2=$(echo ${Array_1[@]} | sed 's@\(.*\)\,$@\1@')
cat > etcd-csr.json <<EOF
{
  "CN": "etcd",
  "hosts": [
    ${Array_2}
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
	  "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
}

# 生成证书和私钥
# 函数使用命令：etcd_cert /usr/local/src/ssl/ca.pem /usr/local/src/ssl/ca-key.pem /usr/local/src/ssl/ca-config.json /usr/local/src/ssl/etcd-csr.json
# 注：参数顺序不能错乱
function etcd_cert() {
# 指定ca.pem文件全路径
# CA=/usr/local/src/ssl/ca.pem
CA=$1
# 指定ca-key.pem文件全路径
# CA_KEY=/usr/local/src/ssl/ca-key.pem
CA_KEY=$2
# 指定ca-config.json文件全路径
# CA_CONFIG=/usr/local/src/ssl/ca-config.json
CA_CONFIG=$3
# 指定etcd-csr.json文件全路径
# ETCD_CSR=/usr/local/src/ssl/etcd-csr.json
ETCD_CSR=$4
cfssl gencert -ca=${CA:-ca.pem} \
-ca-key=${CA_KEY:-ca-key.pem} \
-config=${CA_CONFIG:-ca-config.json} \
-profile=kubernetes ${ETCD_CSR:-etcd-csr.json} | cfssljson -bare etcd
echo ""
echo "#########################################"
[[ -f $K8S_SSL/etcd.pem ]] && echo "etcd_cert_file=$K8S_SSL/etcd.pem" || exit 1
[[ -f $K8S_SSL/etcd-key.pem ]] && echo "etcd_key_file=$K8S_SSL/etcd-key.pem" || exit 1
echo "#########################################"
}

############################################################
# 创建apiserver证书签名请求
# 函数使用方法，必须指定一个数组变量给函数，示例如下：
# 必须传参数，必须传参数，必须传参数，重要事情说三遍
# 定制HOSTS数组变量
#HOSTS=(
#10.96.0.1
#192.168.30.145
#192.168.30.146
#192.168.30.147
#192.168.30.148
#192.168.30.149
#192.168.30.150
#)
# 执行函数命令：apiserver_csr $HOSTS
function apiserver_csr() {
[[ -z $1 ]] && exit 1
APISERVER_HOSTS=$1
N=0
for line in ${APISERVER_HOSTS[@]}
do
    Array[$N]=\"$line\"\,
    ((N++))
done
cat > apiserver-csr.json <<EOF
{
	"CN": "kubernetes",
	"hosts": [
	"127.0.0.1",
	${Array[@]}
	"kubernetes",
	"kubernetes.default",
	"kubernetes.default.svc",
	"kubernetes.default.svc.cluster",
	"kubernetes.default.svc.cluster.local"],
	"key": {
		"algo": "rsa",
		"size": 2048
	},
	"names": [{
		"C": "CN",
		"ST": "BeiJing",
		"L": "BeiJing",
		"O": "k8s",
		"OU": "System"
	}]
}
EOF
}

# 生成证书和私钥
# 函数使用命令：apiserver_cert /usr/local/src/ssl/ca.pem /usr/local/src/ssl/ca-key.pem /usr/local/src/ssl/ca-config.json /usr/local/src/ssl/apiserver-csr.json
# 注：参数顺序不能错乱
function apiserver_cert() {
# 指定ca.pem文件全路径
# CA=/usr/local/src/ssl/ca.pem
CA=$1
# 指定ca-key.pem文件全路径
# CA_KEY=/usr/local/src/ssl/ca-key.pem
CA_KEY=$2
# 指定ca-config.json文件全路径
# CA_CONFIG=/usr/local/src/ssl/ca-config.json
CA_CONFIG=$3
# 指定apiserver-csr.json文件全路径
# APISERVER_CSR=/usr/local/src/ssl/apiserver-csr.json
APISERVER_CSR=$4
cfssl gencert -ca=${CA:-ca.pem} \
-ca-key=${CA_KEY:-ca-key.pem} \
-config=${CA_CONFIG:-ca-config.json} \
-profile=kubernetes ${APISERVER_CSR:-apiserver-csr.json} | cfssljson -bare apiserver
echo ""
echo "#########################################"
[[ -f $K8S_SSL/apiserver.pem ]] && echo "apiserver_cert_file=$K8S_SSL/apiserver.pem" || exit 1
[[ -f $K8S_SSL/apiserver-key.pem ]] && echo "apiserver_key_file=$K8S_SSL/apiserver-key.pem" || exit 1
echo "#########################################"
}

############################################################
# 创建kube-proxy证书签名请求
# 函数使用命令：kubeproxy_csr
function kubeproxy_csr() {
cat > kube-proxy-csr.json <<EOF
{
	"CN": "system:kube-proxy",
	"hosts": [],
	"key": {
		"algo": "rsa",
		"size": 2048
	},
	"names": [{
		"C": "CN",
		"ST": "BeiJing",
		"L": "BeiJing",
		"O": "k8s",
		"OU": "System"
	}]
}
EOF
}

# 生成kube-proxy证书和私钥
# 函数使用命令：kubeproxy_cert /usr/local/src/ssl/ca.pem /usr/local/src/ssl/ca-key.pem /usr/local/src/ssl/ca-config.json /usr/local/src/ssl/kube-proxy-csr.json
# 注：参数顺序不能错乱
function kubeproxy_cert() {
# 指定ca.pem文件全路径
# CA=/usr/local/src/ssl/ca.pem
CA=$1
# 指定ca-key.pem文件全路径
# CA_KEY=/usr/local/src/ssl/ca-key.pem
CA_KEY=$2
# 指定ca-config.json文件全路径
# CA_CONFIG=/usr/local/src/ssl/ca-config.json
CA_CONFIG=$3
# 指定kube-proxy-csr.json文件全路径
# KUBEPROXY_CSR=/usr/local/src/ssl/kube-proxy-csr.json
KUBEPROXY_CSR=$4
cfssl gencert -ca=${CA:-ca.pem} \
-ca-key=${CA_KEY:-ca-key.pem} \
-config=${CA_CONFIG:-ca-config.json} \
-profile=kubernetes ${KUBEPROXY_CSR:-kube-proxy-csr.json} | cfssljson -bare kube-proxy
echo ""
echo "#########################################"
[[ -f $K8S_SSL/kube-proxy.pem ]] && echo "kube-proxy_cert_file=$K8S_SSL/kube-proxy.pem" || exit 1
[[ -f $K8S_SSL/kube-proxy-key.pem ]] && echo "kube-proxy_key_file=$K8S_SSL/kube-proxy-key.pem" || exit 1
echo "#########################################"
}

############################################################
# 创建admin证书签名请求
# 函数命令：admin_csr
function admin_csr() {
cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "system:masters",
      "OU": "System"
    }
  ]
}
EOF
}

# 生成admin证书和私钥
# 函数使用命令：admin_cert /usr/local/src/ssl/ca.pem /usr/local/src/ssl/ca-key.pem /usr/local/src/ssl/ca-config.json /usr/local/src/ssl/admin-csr.json
function admin_cert() {
# 指定ca.pem文件全路径
# CA=/usr/local/src/ssl/ca.pem
CA=$1
# 指定ca-key.pem文件全路径
# CA_KEY=/usr/local/src/ssl/ca-key.pem
CA_KEY=$2
# 指定ca-config.json文件全路径
# CA_CONFIG=/usr/local/src/ssl/ca-config.json
CA_CONFIG=$3
# 指定admin-csr.json文件全路径
# ADMIN_CSR=/usr/local/src/ssl/admin-csr.json
ADMIN_CSR=$4
cfssl gencert -ca=${CA:-ca.pem} \
-ca-key=${CA_KEY:-ca-key.pem} \
-config=${CA_CONFIG:-ca-config.json} \
-profile=kubernetes ${KUBEPROXY_CSR:-admin-csr.json} | cfssljson -bare admin
echo ""
echo "#########################################"
[[ -f $K8S_SSL/admin.pem ]] && echo "admin_cert_file=$K8S_SSL/admin.pem" || exit 1
[[ -f $K8S_SSL/admin-key.pem ]] && echo "admin_key_file=$K8S_SSL/admin-key.pem" || exit 1
echo "#########################################"
}

############################################################
# 下载cfssl工具集，调用函数：cfssl_download
# 如果已经下载cfssl工具集则可以不调用该函数
#cfssl_download

############################################################
# 创建证书临时存放目录（调用函数前建议创建目录）
# 必须使用绝对路径
#K8S_SSL=$(pwd)/ssl
#K8S_SSL=/usr/local/src/ssl
#mkdir -p $K8S_SSL && cd $K8S_SSL

# 生成CA证书和私钥，调用3个函数：ca_config/ca_csr/ca_cert
#CA_CSR=$K8S_SSL/ca-csr.json
#ca_config
#ca_csr
#ca_cert $CA_CSR

############################################################
# 定制etcd服务的IP地址列表
# 生成etcd证书和私钥，调用2个函数：etcd_csr/etcd_cert
#ETCD_HOSTS=(
#192.168.30.145
#192.168.30.146
#192.168.30.147
#192.168.30.148
#192.168.30.149
#192.168.30.150
#)
#CA_CERT=$K8S_SSL/ca.pem
#CA_KEY=$K8S_SSL/ca-key.pem
#CA_CONFIG=$K8S_SSL/ca-config.json
#ETCD_CSR=$K8S_SSL/etcd-csr.json

#etcd_csr $ETCD_HOSTS
#etcd_cert $CA_CERT $CA_KEY $CA_CONFIG $ETCD_CSR
# 注：参数顺序不能错乱

############################################################
# 定制apiserver服务的IP地址列表
# 生成apiserver证书和私钥，调用2个函数：apiserver_csr/apiserver_cert
#APISERVER_HOSTS=(
#10.96.0.1
#192.168.30.145
#192.168.30.146
#192.168.30.147
#192.168.30.148
#192.168.30.149
#192.168.30.150
#)
#CA_CERT=$K8S_SSL/ca.pem
#CA_KEY=$K8S_SSL/ca-key.pem
#CA_CONFIG=$K8S_SSL/ca-config.json
#APISERVER_CSR=$K8S_SSL/apiserver-csr.json

#apiserver_csr $APISERVER_HOSTS
#apiserver_cert $CA_CERT $CA_KEY $CA_CONFIG $APISERVER_CSR
# 注：参数顺序不能错乱

############################################################
# 生成kube-proxy证书和私钥，调用2个函数：kubeproxy_csr/kubeproxy_cert
#CA_CERT=$K8S_SSL/ca.pem
#CA_KEY=$K8S_SSL/ca-key.pem
#CA_CONFIG=$K8S_SSL/ca-config.json
#KUBEPROXY_CSR=$K8S_SSL/kube-proxy-csr.json

#kubeproxy_csr
#kubeproxy_cert $CA_CERT $CA_KEY $CA_CONFIG $KUBEPROXY_CSR
# 注：参数顺序不能错乱

############################################################
# 生成admin证书和私钥，调用2个函数：admin_csr/admin_cert
#CA_CERT=$K8S_SSL/ca.pem
#CA_KEY=$K8S_SSL/ca-key.pem
#CA_CONFIG=$K8S_SSL/ca-config.json
#ADMIN_CSR=$K8S_SSL/admin-csr.json

#admin_csr
#admin_cert $CA_CERT $CA_KEY $CA_CONFIG $ADMIN_CSR
# 注：参数顺序不能错乱