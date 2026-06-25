# ── AMI (Ubuntu 24.04 LTS) ────────────────────────────────────────────────────

data "aws_ami" "ubuntu_24_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── Instances ─────────────────────────────────────────────────────────────────

# 1. Bastion Host (Public Subnet)
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu_24_04.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.freeswitch_key_pair.key_name

  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "${var.cluster_name}-bastion"
  }

  lifecycle {
    ignore_changes = [key_name, associate_public_ip_address]
  }
}

# 2. Private FreeSWITCH Server (Private Subnet)
resource "aws_instance" "freeswitch" {
  ami                  = data.aws_ami.ubuntu_24_04.id
  instance_type        = var.instance_type
  key_name             = aws_key_pair.freeswitch_key_pair.key_name
  iam_instance_profile = "EC2-ECR-Read-Role"

  subnet_id              = module.vpc.private_subnets[0]
  private_ip             = "10.0.1.143"
  vpc_security_group_ids = [aws_security_group.freeswitch_sg.id]

  root_block_device {
    volume_size           = 40
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = file("${path.module}/templates/userdata_server.sh.tpl")

  tags = {
    Name = "${var.cluster_name}-server"
  }

  lifecycle {
    ignore_changes = [key_name]
  }
}

# 3. Nginx / SIP Proxy Host (Public Subnet)
resource "aws_instance" "proxy" {
  ami           = data.aws_ami.ubuntu_24_04.id
  instance_type = "t3.small"
  key_name      = aws_key_pair.freeswitch_key_pair.key_name

  subnet_id                   = module.vpc.public_subnets[1]
  vpc_security_group_ids      = [aws_security_group.proxy_sg.id]
  associate_public_ip_address = true
  source_dest_check           = false

  user_data = templatefile("${path.module}/templates/userdata_proxy.sh.tpl", {
    private_fs_ip = aws_instance.freeswitch.private_ip
  })

  tags = {
    Name = "${var.cluster_name}-proxy"
  }

  lifecycle {
    ignore_changes = [key_name, associate_public_ip_address, user_data]
  }
}

# ── Elastic IP for the Proxy (Twilio & Web Traffic entry point) ──────────────

resource "aws_eip" "proxy_eip" {
  domain   = "vpc"
  instance = aws_instance.proxy.id

  tags = {
    Name = "${var.cluster_name}-proxy-eip"
  }
}
