terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

locals {
  user_data_file = templatefile("${path.module}/templates/user-data.tpl", {
    tf_wireguard_playbook_config = jsonencode({
      "wireguard_preup": [
        "sysctl -w net.ipv4.ip_forward=1"
      ],
      "wireguard_postdown": [
        "iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE"
      ],
      "wireguard_persistent_keepalive": "30",
      "wireguard_save_config": "true",
      "wireguard_postup": [
        "iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE"
      ],
      "wireguard_predown": [
        "sysctl -w net.ipv4.ip_forward=0"
      ],
      "wireguard_address": var.wireguard_address,
      "wireguard_unmanaged_peers": {
        "${var.remote_client_ip}": {
          "persistent_keepalive": "25",
          "public_key": var.remote_client_public_key,
          "endpoint": "${var.remote_client_ip}:51505",
          "allowed_ips": var.allowed_ips
        }
      },
      "endpoint_fqdn": var.endpoint_fqdn
      "endpoint_ttl": var.endpoint_ttl
    }),
    tf_ansible_playbook_url       = var.ansible_playbook_url,
    tf_ansible_playbook_release   = var.ansible_playbook_release,
    tf_ansible_playbook_directory = var.ansible_playbook_directory
  })
}

data "aws_caller_identity" "current" {}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  name_regex  = "^amzn2"
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "wireguard_endpoint_instance" {
  ami                     = data.aws_ami.amazon_linux_2.id
  instance_type           = var.ec2_instance_type
  availability_zone       = var.availability_zone
  subnet_id               = var.subnet_id
  source_dest_check       = false
  disable_api_termination = false
  key_name                = var.ec2_ssh_key
  iam_instance_profile    = aws_iam_instance_profile.wireguard_endpoint.id
  user_data               = local.user_data_file
  vpc_security_group_ids  = [aws_security_group.wireguard_endpoint.id]
  tags                    = var.tags
}

resource "aws_ebs_volume" "wireguard_endpoint_vol" {
  availability_zone = var.availability_zone
  size              = 8
  encrypted         = true

  lifecycle {
    prevent_destroy = false
  }
}
