#!/bin/bash

. ./function.sh

############################################################
# 下载cfssl工具集，调用函数：cfssl_download
# 如果已经下载cfssl工具集则可以不调用该函数
#cfssl_download

############################################################
# 创建证书临时存放目录（调用函数前建议创建目录）
# 必须使用绝对路径
K8S_SSL=$(pwd)/ssl
#K8S_SSL=/usr/local/src/ssl
mkdir -p $K8S_SSL && cd $K8S_SSL

# 生成CA证书和私钥，调用3个函数：ca_config/ca_csr/ca_cert
CA_CSR=$K8S_SSL/ca-csr.json
ca_config
ca_csr
ca_cert $CA_CSR

############################################################
# 定制etcd服务的IP地址列表
# 生成etcd证书和私钥，调用2个函数：etcd_csr/etcd_cert
ETCD_HOSTS=(
192.168.30.145
192.168.30.146
192.168.30.147
192.168.30.148
192.168.30.149
192.168.30.150
)
CA_CERT=$K8S_SSL/ca.pem
CA_KEY=$K8S_SSL/ca-key.pem
CA_CONFIG=$K8S_SSL/ca-config.json
ETCD_CSR=$K8S_SSL/etcd-csr.json

etcd_csr $ETCD_HOSTS
etcd_cert $CA_CERT $CA_KEY $CA_CONFIG $ETCD_CSR
# 注：参数顺序不能错乱

############################################################
# 定制apiserver服务的IP地址列表
# 生成apiserver证书和私钥，调用2个函数：apiserver_csr/apiserver_cert
APISERVER_HOSTS=(
10.96.0.1
192.168.30.145
192.168.30.146
192.168.30.147
192.168.30.148
192.168.30.149
192.168.30.150
)
CA_CERT=$K8S_SSL/ca.pem
CA_KEY=$K8S_SSL/ca-key.pem
CA_CONFIG=$K8S_SSL/ca-config.json
APISERVER_CSR=$K8S_SSL/apiserver-csr.json

apiserver_csr $APISERVER_HOSTS
apiserver_cert $CA_CERT $CA_KEY $CA_CONFIG $APISERVER_CSR
# 注：参数顺序不能错乱

############################################################
# 生成kube-proxy证书和私钥，调用2个函数：kubeproxy_csr/kubeproxy_cert
CA_CERT=$K8S_SSL/ca.pem
CA_KEY=$K8S_SSL/ca-key.pem
CA_CONFIG=$K8S_SSL/ca-config.json
KUBEPROXY_CSR=$K8S_SSL/kube-proxy-csr.json

kubeproxy_csr
kubeproxy_cert $CA_CERT $CA_KEY $CA_CONFIG $KUBEPROXY_CSR
# 注：参数顺序不能错乱

############################################################
# 生成admin证书和私钥，调用2个函数：admin_csr/admin_cert
CA_CERT=$K8S_SSL/ca.pem
CA_KEY=$K8S_SSL/ca-key.pem
CA_CONFIG=$K8S_SSL/ca-config.json
ADMIN_CSR=$K8S_SSL/admin-csr.json

admin_csr
admin_cert $CA_CERT $CA_KEY $CA_CONFIG $ADMIN_CSR
# 注：参数顺序不能错乱