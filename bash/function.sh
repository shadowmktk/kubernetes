#!/bin/bash

############################################################
# ����cfssl���߼�
# ����ʹ�����cfssl_download
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
# ����CA�����ļ���CA֤���Ǽ�Ⱥ���нڵ㹲��ģ�ֻ��Ҫ����һ�� CA ֤�飬��������������֤�鶼����ǩ��
# ����ʹ�����ca_config
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

# ����CA֤��ǩ������
# ����ʹ�����ca_csr
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

# ����CA֤���˽Կ
# ����ʹ�÷���������������������ca_cert /usr/local/src/ssl/ca-csr.json
function ca_cert() {
# ָ��ca-csr.json�ļ�ȫ·��
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
# ����etcd֤��ǩ������
# ע��hosts�ֶ�ָ����Ȩʹ�ø�֤���etcd�ڵ�IP�������б�
# ����ʹ�÷���������ָ��һ�����������������ʾ�����£�
# ���봫���������봫���������봫��������Ҫ����˵����
# ����HOSTS�����������ʽ���������һ��
#HOSTS=(
#192.168.30.145
#192.168.30.146
#192.168.30.147
#192.168.30.148
#192.168.30.149
#192.168.30.150
#)
# ����ʹ�����etcd_csr $HOSTS
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

# ����֤���˽Կ
# ����ʹ�����etcd_cert /usr/local/src/ssl/ca.pem /usr/local/src/ssl/ca-key.pem /usr/local/src/ssl/ca-config.json /usr/local/src/ssl/etcd-csr.json
# ע������˳���ܴ���
function etcd_cert() {
# ָ��ca.pem�ļ�ȫ·��
# CA=/usr/local/src/ssl/ca.pem
CA=$1
# ָ��ca-key.pem�ļ�ȫ·��
# CA_KEY=/usr/local/src/ssl/ca-key.pem
CA_KEY=$2
# ָ��ca-config.json�ļ�ȫ·��
# CA_CONFIG=/usr/local/src/ssl/ca-config.json
CA_CONFIG=$3
# ָ��etcd-csr.json�ļ�ȫ·��
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
# ����apiserver֤��ǩ������
# ����ʹ�÷���������ָ��һ�����������������ʾ�����£�
# ���봫���������봫���������봫��������Ҫ����˵����
# ����HOSTS�������
#HOSTS=(
#10.96.0.1
#192.168.30.145
#192.168.30.146
#192.168.30.147
#192.168.30.148
#192.168.30.149
#192.168.30.150
#)
# ִ�к������apiserver_csr $HOSTS
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

# ����֤���˽Կ
# ����ʹ�����apiserver_cert /usr/local/src/ssl/ca.pem /usr/local/src/ssl/ca-key.pem /usr/local/src/ssl/ca-config.json /usr/local/src/ssl/apiserver-csr.json
# ע������˳���ܴ���
function apiserver_cert() {
# ָ��ca.pem�ļ�ȫ·��
# CA=/usr/local/src/ssl/ca.pem
CA=$1
# ָ��ca-key.pem�ļ�ȫ·��
# CA_KEY=/usr/local/src/ssl/ca-key.pem
CA_KEY=$2
# ָ��ca-config.json�ļ�ȫ·��
# CA_CONFIG=/usr/local/src/ssl/ca-config.json
CA_CONFIG=$3
# ָ��apiserver-csr.json�ļ�ȫ·��
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
# ����kube-proxy֤��ǩ������
# ����ʹ�����kubeproxy_csr
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

# ����kube-proxy֤���˽Կ
# ����ʹ�����kubeproxy_cert /usr/local/src/ssl/ca.pem /usr/local/src/ssl/ca-key.pem /usr/local/src/ssl/ca-config.json /usr/local/src/ssl/kube-proxy-csr.json
# ע������˳���ܴ���
function kubeproxy_cert() {
# ָ��ca.pem�ļ�ȫ·��
# CA=/usr/local/src/ssl/ca.pem
CA=$1
# ָ��ca-key.pem�ļ�ȫ·��
# CA_KEY=/usr/local/src/ssl/ca-key.pem
CA_KEY=$2
# ָ��ca-config.json�ļ�ȫ·��
# CA_CONFIG=/usr/local/src/ssl/ca-config.json
CA_CONFIG=$3
# ָ��kube-proxy-csr.json�ļ�ȫ·��
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
# ����admin֤��ǩ������
# �������admin_csr
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

# ����admin֤���˽Կ
# ����ʹ�����admin_cert /usr/local/src/ssl/ca.pem /usr/local/src/ssl/ca-key.pem /usr/local/src/ssl/ca-config.json /usr/local/src/ssl/admin-csr.json
function admin_cert() {
# ָ��ca.pem�ļ�ȫ·��
# CA=/usr/local/src/ssl/ca.pem
CA=$1
# ָ��ca-key.pem�ļ�ȫ·��
# CA_KEY=/usr/local/src/ssl/ca-key.pem
CA_KEY=$2
# ָ��ca-config.json�ļ�ȫ·��
# CA_CONFIG=/usr/local/src/ssl/ca-config.json
CA_CONFIG=$3
# ָ��admin-csr.json�ļ�ȫ·��
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
# ����cfssl���߼������ú�����cfssl_download
# ����Ѿ�����cfssl���߼�����Բ����øú���
#cfssl_download

############################################################
# ����֤����ʱ���Ŀ¼�����ú���ǰ���鴴��Ŀ¼��
# ����ʹ�þ���·��
#K8S_SSL=$(pwd)/ssl
#K8S_SSL=/usr/local/src/ssl
#mkdir -p $K8S_SSL && cd $K8S_SSL

# ����CA֤���˽Կ������3��������ca_config/ca_csr/ca_cert
#CA_CSR=$K8S_SSL/ca-csr.json
#ca_config
#ca_csr
#ca_cert $CA_CSR

############################################################
# ����etcd�����IP��ַ�б�
# ����etcd֤���˽Կ������2��������etcd_csr/etcd_cert
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
# ע������˳���ܴ���

############################################################
# ����apiserver�����IP��ַ�б�
# ����apiserver֤���˽Կ������2��������apiserver_csr/apiserver_cert
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
# ע������˳���ܴ���

############################################################
# ����kube-proxy֤���˽Կ������2��������kubeproxy_csr/kubeproxy_cert
#CA_CERT=$K8S_SSL/ca.pem
#CA_KEY=$K8S_SSL/ca-key.pem
#CA_CONFIG=$K8S_SSL/ca-config.json
#KUBEPROXY_CSR=$K8S_SSL/kube-proxy-csr.json

#kubeproxy_csr
#kubeproxy_cert $CA_CERT $CA_KEY $CA_CONFIG $KUBEPROXY_CSR
# ע������˳���ܴ���

############################################################
# ����admin֤���˽Կ������2��������admin_csr/admin_cert
#CA_CERT=$K8S_SSL/ca.pem
#CA_KEY=$K8S_SSL/ca-key.pem
#CA_CONFIG=$K8S_SSL/ca-config.json
#ADMIN_CSR=$K8S_SSL/admin-csr.json

#admin_csr
#admin_cert $CA_CERT $CA_KEY $CA_CONFIG $ADMIN_CSR
# ע������˳���ܴ���