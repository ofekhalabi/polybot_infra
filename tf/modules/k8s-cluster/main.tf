data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available_azs" {
  state = "available"
}

module "polybot-vpc"  {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available_azs.names
  public_subnets  = var.vpc_public_subnets
  private_subnets = var.vpc_private_subnets
  map_public_ip_on_launch = true
  
  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = merge(
    var.vpc_tags,
    {
      Terraform   = "true"
      Environment = "ofekh-polybot"
    },
  )
}

# Security Groups
resource "aws_security_group" "control_plane" {
  name_prefix = "${var.cluster_name}-control-plane-"
  vpc_id      = module.polybot-vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-control-plane-sg"
  }
}

resource "aws_security_group" "worker" {
  name_prefix = "${var.cluster_name}-worker-"
  vpc_id      = module.polybot-vpc.vpc_id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.control_plane.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-worker-sg"
  }
}


resource "aws_security_group" "alb" {
  name_prefix = "${var.cluster_name}-alb-"
  vpc_id      = module.polybot-vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-alb-sg"
  }
}


# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = module.polybot-vpc.public_subnets

  enable_deletion_protection = false

  tags = {
    Name = "${var.cluster_name}-alb"
  }
  depends_on = [
    aws_security_group.alb,
    aws_lb_target_group.polybot-tg,
    aws_autoscaling_group.worker,
    ]
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.polybot-tg.arn
  }
}

# create a target group for the ALB
resource "aws_lb_target_group" "polybot-tg" {
  name     = "ofekh-polybot-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.polybot-vpc.vpc_id

  health_check {
    enabled             = true
    path                = var.alb_health_check_path
    port                = var.alb_health_check_port
    interval            = var.alb_health_check_interval
    timeout             = var.alb_health_check_timeout
    healthy_threshold   = var.alb_health_check_healthy_threshold
    unhealthy_threshold = var.alb_health_check_unhealthy_threshold
    matcher             = "200"
  }

  tags = {
    Name = "ofekh-polybot-tg"
  }
}

# Create IAM role for control plane
resource "aws_iam_role" "control_plane_role" {
  name = var.control_plane_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = var.control_plane_role_name
    Terraform   = "true"
    Environment = "ofekh-polybot"
  }
}

# Create separate policy for OIDC operations
resource "aws_iam_policy" "oidc_list_policy" {
  name = "ofekh-oidc-list-policy"
  description = "Policy to allow OIDC provider operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "iam:ListOpenIDConnectProviders"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "iam:GetOpenIDConnectProvider"
        Resource = "arn:aws:iam::352708296901:oidc-provider/*"
      }
    ]
  })
}

# Attach OIDC policy to the role
resource "aws_iam_role_policy_attachment" "control_plane_oidc_policy" {
  policy_arn = aws_iam_policy.oidc_list_policy.arn
  role       = aws_iam_role.control_plane_role.name
}

# Attach managed policies to the control plane role
resource "aws_iam_role_policy_attachment" "control_plane_ebs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.control_plane_role.name
}

resource "aws_iam_role_policy_attachment" "control_plane_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.control_plane_role.name
}

resource "aws_iam_role_policy_attachment" "control_plane_eks_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.control_plane_role.name
}

resource "aws_iam_role_policy_attachment" "control_plane_s3_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.control_plane_role.name
}

resource "aws_iam_role_policy_attachment" "control_plane_autoscaling_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  role       = aws_iam_role.control_plane_role.name
}

resource "aws_iam_role_policy_attachment" "control_plane_secrets_policy" {
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  role       = aws_iam_role.control_plane_role.name
}

# Create IAM instance profile for control plane
resource "aws_iam_instance_profile" "control_plane_profile" {
  name = "${var.control_plane_role_name}-profile"
  role = aws_iam_role.control_plane_role.name
}

# Create IAM role for worker nodes
resource "aws_iam_role" "worker_node_role" {
  name = var.worker_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = var.worker_role_name
    Terraform   = "true"
    Environment = "ofekh-polybot"
  }
}

# Attach managed policies to the worker role
resource "aws_iam_role_policy_attachment" "worker_sqs_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  role       = aws_iam_role.worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "worker_dynamodb_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "worker_ebs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "worker_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "worker_eks_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "worker_sns_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
  role       = aws_iam_role.worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "worker_cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  role       = aws_iam_role.worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "worker_cloudwatch_v2_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccessV2"
  role       = aws_iam_role.worker_node_role.name
}

# Create IAM instance profile for worker nodes
resource "aws_iam_instance_profile" "worker_node_profile" {
  name = "${var.worker_role_name}-profile"
  role = aws_iam_role.worker_node_role.name
}

# Launch Template for Worker Nodes
resource "aws_launch_template" "worker" {
  name_prefix   = "${var.cluster_name}-worker-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.worker_instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.worker_node_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups            = [aws_security_group.worker.id]
    subnet_id                  = module.polybot-vpc.public_subnets[0]
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = var.ebs_volume_size
      volume_type = "gp3"
      encrypted   = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/worker-userdata.sh", {
    kubernetes_version = var.kubernetes_version
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-worker"
    }
  }
}

# Auto Scaling Group for Worker Nodes
resource "aws_autoscaling_group" "worker" {
  name                = "${var.cluster_name}-worker-asg"
  desired_capacity    = var.worker_desired_capacity
  max_size           = var.worker_max_size
  min_size           = var.worker_min_size
  target_group_arns  = [aws_lb_target_group.polybot-tg.arn]
  vpc_zone_identifier = module.polybot-vpc.public_subnets

  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value              = "${var.cluster_name}-worker"
    propagate_at_launch = true
  }
  depends_on = [
    aws_launch_template.worker,
    aws_lb_target_group.polybot-tg,
  ]
}

# Attach target group to ASG
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.worker.name
  lb_target_group_arn   = aws_lb_target_group.polybot-tg.arn
  depends_on = [
    aws_autoscaling_group.worker,
    aws_lb_target_group.polybot-tg,
  ]
}

# Control Plane Instance
resource "aws_instance" "control_plane" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.control_plane_instance_type
  key_name      = var.key_name
  iam_instance_profile = aws_iam_instance_profile.control_plane_profile.name

  subnet_id                   = module.polybot-vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.control_plane.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.ebs_volume_size
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Update package list and upgrade packages
              apt-get update
              apt-get upgrade -y

              # Install prerequisites
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common

              # Add Docker's official GPG key
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

              # Add Docker repository
              echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

              # Install Docker
              apt-get update
              apt-get install -y docker-ce docker-ce-cli containerd.io

              # Add Kubernetes repo and GPG key
              curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
              echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

              # Install Kubernetes components
              apt-get update
              apt-get install -y kubelet kubeadm kubectl
              apt-mark hold kubelet kubeadm kubectl

              # Configure containerd
              cat <<EOF2 > /etc/modules-load.d/containerd.conf
              overlay
              br_netfilter
              EOF2

              modprobe overlay
              modprobe br_netfilter

              cat <<EOF2 > /etc/sysctl.d/99-kubernetes-cri.conf
              net.bridge.bridge-nf-call-iptables  = 1
              net.ipv4.ip_forward                 = 1
              net.bridge.bridge-nf-call-ip6tables = 1
              EOF2

              sysctl --system

              # Initialize control plane with Calico's default CIDR
              kubeadm init --pod-network-cidr=192.168.0.0/16

              # Configure kubectl for ubuntu user
              mkdir -p /home/ubuntu/.kube
              cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
              chown -R ubuntu:ubuntu /home/ubuntu/.kube

              # Install Calico CNI
              sudo -u ubuntu kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
              sudo -u ubuntu kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml
              EOF
  )

  tags = {
    Name = "${var.cluster_name}-control-plane"
  }
}


