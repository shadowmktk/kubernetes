#!/bin/bash
# CentOS Linux release 7.8.2003 (Core)
# 从官网拉取不到镜像的话可以使用该脚本
# 前提：必须已安装kubeadm和docker
KUBERNETES=v1.19.0
FLANNEL_VERSION=v0.12.0-amd64
REGISTRY_HOST=registry.cn-hangzhou.aliyuncs.com/google_containers

# 获取kubernetes默认镜像
KUBE_ARRAY=$(kubeadm config images list --kubernetes-version=${KUBERNETES})

# 将获取到的镜像数据生成为数组
for LINE in $KUBE_ARRAY
do
  Array=$LINE
  KUBE_IMAGES[$NUMBER]=$Array
  ((NUMBER++))
done

# 拉取核心组件镜像
docker pull ${REGISTRY_HOST}/${KUBE_IMAGES[0]#*/}
docker pull ${REGISTRY_HOST}/${KUBE_IMAGES[1]#*/}
docker pull ${REGISTRY_HOST}/${KUBE_IMAGES[2]#*/}
docker pull ${REGISTRY_HOST}/${KUBE_IMAGES[3]#*/}
docker pull ${REGISTRY_HOST}/${KUBE_IMAGES[4]#*/}
docker pull ${REGISTRY_HOST}/${KUBE_IMAGES[5]#*/}
docker pull ${REGISTRY_HOST}/${KUBE_IMAGES[6]#*/}

# 拉取网络组件镜像
docker pull quay.io/coreos/flannel:${FLANNEL_VERSION}

# 修改tag
docker tag ${REGISTRY_HOST}/${KUBE_IMAGES[0]#*/} ${KUBE_IMAGES[0]}
docker tag ${REGISTRY_HOST}/${KUBE_IMAGES[1]#*/} ${KUBE_IMAGES[1]}
docker tag ${REGISTRY_HOST}/${KUBE_IMAGES[2]#*/} ${KUBE_IMAGES[2]}
docker tag ${REGISTRY_HOST}/${KUBE_IMAGES[3]#*/} ${KUBE_IMAGES[3]}
docker tag ${REGISTRY_HOST}/${KUBE_IMAGES[4]#*/} ${KUBE_IMAGES[4]}
docker tag ${REGISTRY_HOST}/${KUBE_IMAGES[5]#*/} ${KUBE_IMAGES[5]}
docker tag ${REGISTRY_HOST}/${KUBE_IMAGES[6]#*/} ${KUBE_IMAGES[6]}

# 删除无用镜像
#docker images | grep ${REGISTRY_HOST} | awk '{print "docker rmi "$1":"$2}' | sh
docker rmi ${REGISTRY_HOST}/${KUBE_IMAGES[0]#*/}
docker rmi ${REGISTRY_HOST}/${KUBE_IMAGES[1]#*/}
docker rmi ${REGISTRY_HOST}/${KUBE_IMAGES[2]#*/}
docker rmi ${REGISTRY_HOST}/${KUBE_IMAGES[3]#*/}
docker rmi ${REGISTRY_HOST}/${KUBE_IMAGES[4]#*/}
docker rmi ${REGISTRY_HOST}/${KUBE_IMAGES[5]#*/}
docker rmi ${REGISTRY_HOST}/${KUBE_IMAGES[6]#*/}