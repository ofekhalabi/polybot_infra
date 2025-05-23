#!/bin/bash
set -e

# Update package list and upgrade packages
apt-get update
apt-get upgrade -y

# Install prerequisites
apt-get install -y apt-transport-https ca-certificates curl gpg software-properties-common

# Add Kubernetes GPG key and repo
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

# Add CRI-O repo and GPG key (for Ubuntu 22.04, Jammy)
OS="xUbuntu_22.04"
echo "deb [signed-by=/etc/apt/keyrings/cri-o.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/${OS}/ /" | tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb [signed-by=/etc/apt/keyrings/cri-o.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/${kubernetes_version}/${OS}/ /" | tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:${kubernetes_version}.list

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/${OS}/Release.key | gpg --dearmor -o /etc/apt/keyrings/cri-o.gpg

# Update and install CRI-O + Kubernetes tools
apt-get update
apt-get install -y cri-o cri-o-runc kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Enable and start CRI-O and kubelet
systemctl daemon-reexec
systemctl enable crio --now
systemctl enable kubelet --now

# Configure kernel modules and sysctl
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

# Disable swap (required for Kubernetes)
swapoff -a
sed -i '/swap/d' /etc/fstab

# Initialize control plane with Calico's default pod CIDR
kubeadm init --pod-network-cidr=192.168.0.0/16 --cri-socket=unix:///var/run/crio/crio.sock

# Set up kubectl for ubuntu user
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube

# Install Calico CNI
sudo -u ubuntu kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
sudo -u ubuntu kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml
