# terraform-aws-wireguard-endpoint
A Terraform module which sets up an EC2 instance as a [Wireguard](https://www.wireguard.com/) endpoint, which allows you to tunnel through to internal subnets in your VPC.

## The module

The Terraform module's aim was to automatically provision a VPN endpoint which met the following criteria:

* No SSH rules for remote provisioners to configure the endpoint.
* To be disposable.
* Fast-ish to deploy.
* Available to the smallest of EC2 instances.
* Modular. Allowing instances to be created in multiple regions.
* Relatively lightweight.

Wireguard was the best tool for the job, given its light-weight approach to configuration. This module heavily relies upon [Ansible](https://www.ansible.com/) to run locally on the EC2 instance during it's first (and second) boot and initiates the playbook https://github.com/gavmain/bootstrap-wireguard-ec2. This is intended for single-user use and ideal for individuals who don't wish to set up an OpenVPN instance.

This only supports [Amazon Linux 2](https://aws.amazon.com/amazon-linux-2/) and provisions with the latest available AMI.

### What you get

* A disposable VPN endpoint which you can use to tunnel through to your resources hosted on a private subnet in your VPC.
* By default, only the Wireguard port is exposed to the internet.
* When configured with an associated DNS record, if you power off the instance, at boot-time it will [automatically update Route53](https://github.com/gavmain/ansible-role-update-route53-onboot) to reflect the newly assigned public IP address.
* Once provisioned, the newly minted [public key](https://www.wireguard.com/#cryptokey-routing) will be made available to [AWS Systems Manager - Parameter Store](https://aws.amazon.com/systems-manager/features/#Parameter_Store) to be fetched at a later time.
* The user-data provisioning stage usually takes a couple of minutes including the reboot.

### Outputs

The security group attached to the endpoint, useful if you wish to augment the security group in your own Terraform code. E.g. Adding SSH access for testing.

        output "wireguard_security_group_id" {
          value       = aws_security_group.wireguard_endpoint.id
          description = "The ID of the security group attached to the Wireguard endpoint"
        }

The ID of the EC2 instance. Used in other parts of your Terraform code to add routes, allowing internal resources to route back to the Wireguard endpoint.

        output "wireguard_endpoint_instance_id" {
        value       = aws_instance.wireguard_endpoint_instance.id
        description = "The ID of the Wireguard Endpoint instance"
        }


## Prerequisites

### Wireguard
An idea of how Wireguard works - https://www.wireguard.com/quickstart/. The project creators have done a great job explaining at a high-level how Wireguard can be used.

### Terraform
This module was written with v0.14.7

### AWS
Access to an AWS account with system administrator level privileges.

## Configuration

There are a few parameters that you should create in a `secrets.tfvars` file:

    client_wireguard_public_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx="
    hosted_zone_id              = "xxxxxxxxxxxxxxxxxxxxx"
    vpn_dns_entry               = "london.yourdomain.com"

## Example
    module "wireguard_endpoint" {
      source = "gavmain/aws-wireguard-endpoint"

      aws_region                   = "eu-west-2"
      vpc_id                       = aws_vpc.default.id
      namespace                    = "example"
      availability_zone            = "eu-west-2a"
      ec2_instance_type            = "t2.nano"
      ec2_ssh_key                  = aws_key_pair.example_ec2.id
      subnet_id                    = aws_subnet.public_2a.id
      wireguard_address            = var.wireguard_server_internal_ip
      remote_client_public_key     = var.client_wireguard_public_key
      remote_client_ip             = "0.0.0.0"
      client_subnet                = var.client_subnet
      allowed_ips                  = var.assigned_client_wireguard_ip
      external_allowed_cidr_blocks = ["0.0.0.0/0"]
      endpoint_fqdn                = var.endpoint_fqdn
      endpoint_ttl                 = var.endpoint_ttl

      hosted_zone_id               = var.hosted_zone_id


      tags = {
        "Name" = "wireguard-example-london-2a"
      }
    }



## Acknowledgements
https://www.wireguard.com/

https://github.com/githubixx/

https://www.ifconfig.it/hugo/2020/04/aws-terraform-and-wireguard-part-one/

https://github.com/npalm/terraform-aws-gitlab-runner


## Author

[Gav Main](https://github.com/gavmain), 2021.
