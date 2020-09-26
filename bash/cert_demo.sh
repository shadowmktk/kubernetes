#!/bin/bash

. ./function.sh

############################################################
# ����cfssl���߼������ú�����cfssl_download
# ����Ѿ�����cfssl���߼�����Բ����øú���
#cfssl_download

############################################################
# ����֤����ʱ���Ŀ¼�����ú���ǰ���鴴��Ŀ¼��
# ����ʹ�þ���·��
K8S_SSL=$(pwd)/ssl
#K8S_SSL=/usr/local/src/ssl
mkdir -p $K8S_SSL && cd $K8S_SSL

# ����CA֤���˽Կ������3��������ca_config/ca_csr/ca_cert
CA_CSR=$K8S_SSL/ca-csr.json
ca_config
ca_csr
ca_cert $CA_CSR

############################################################
# ����etcd�����IP��ַ�б�
# ����etcd֤���˽Կ������2��������etcd_csr/etcd_cert
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
# ע������˳���ܴ���

############################################################
# ����apiserver�����IP��ַ�б�
# ����apiserver֤���˽Կ������2��������apiserver_csr/apiserver_cert
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
# ע������˳���ܴ���

############################################################
# ����kube-proxy֤���˽Կ������2��������kubeproxy_csr/kubeproxy_cert
CA_CERT=$K8S_SSL/ca.pem
CA_KEY=$K8S_SSL/ca-key.pem
CA_CONFIG=$K8S_SSL/ca-config.json
KUBEPROXY_CSR=$K8S_SSL/kube-proxy-csr.json

kubeproxy_csr
kubeproxy_cert $CA_CERT $CA_KEY $CA_CONFIG $KUBEPROXY_CSR
# ע������˳���ܴ���

############################################################
# ����admin֤���˽Կ������2��������admin_csr/admin_cert
CA_CERT=$K8S_SSL/ca.pem
CA_KEY=$K8S_SSL/ca-key.pem
CA_CONFIG=$K8S_SSL/ca-config.json
ADMIN_CSR=$K8S_SSL/admin-csr.json

admin_csr
admin_cert $CA_CERT $CA_KEY $CA_CONFIG $ADMIN_CSR
# ע������˳���ܴ���