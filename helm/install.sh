#!/bin/bash

# °²×°helm
Version=v3.3.2
cd /tmp/ && wget https://get.helm.sh/helm-${Version}-linux-amd64.tar.gz
[[ -f "helm-${Version}-linux-amd64.tar.gz" ]] && tar xf helm-${Version}-linux-amd64.tar.gz
[[ -d "linux-amd64" ]] && \cp linux-amd64/helm /usr/bin/
which helm && echo "helm install ok!"