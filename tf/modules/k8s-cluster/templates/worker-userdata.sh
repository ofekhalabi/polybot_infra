#!/bin/bash
set -e  # Stop script on error
exec > /var/log/user-data.log 2>&1  # Redirect output to log file

# Update packages
sudo apt-get update
sudo apt-get install -y jq unzip ebtables ethtool software-properties-common apt-transport-https ca-certificates curl gpg

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Enable IPv4 packet forwarding
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# Install CRI-O, kubelet, kubeadm, and kubectl
curl -fsSL https://pkgs.k8s.io/core:/stable:/${kubernetes_version}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${kubernetes_version}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" | sudo tee /etc/apt/sources.list.d/cri-o.list

sudo apt-get update
sudo apt-get install -y cri-o kubelet kubeadm
sudo apt-mark hold kubelet kubeadm

# Start CRIO and kubelet services
sudo systemctl enable --now crio.service
sudo systemctl enable --now kubelet

# Disable swap memory permanently
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab  # Remove swap from fstab to persist reboots

# Add swapoff to crontab to ensure it's disabled on every reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab -
