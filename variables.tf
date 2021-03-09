variable "aws_region" {
  description = "AWS Region to deploy the endpoint in."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the instance will live in."
  type        = string
}

variable "namespace" {
  description = "A name to affix to human-readable resouces, e.g. IAM Roles."
  type        = string
}

variable "availability_zone" {
  description = "AWS Availability Zone."
  type        = string
}

variable "ec2_instance_type" {
  description = "The size of the EC2 instance."
  default     = "t2.micro"
  type        = string
}

variable "ec2_ssh_key" {
  description = "EC2 SSH key for ssh connectivity."
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet to place this instance into."
  type        = string
}

variable "tags" {
  description = "Tags to assign to the Instance."
  type        = map(string)
}

variable "wireguard_address" {
  description = "The internal address that wg0 will listen on."
  type        = string
}

variable "remote_client_public_key" {
  description = "The remote client's public key."
  type        = string
}

variable "remote_client_ip" {
  description = "The Public IP address of the remote client permitted to establish a connection."
  type        = string
}

variable "allowed_ips" {
  description = "A list of internal IPs assigned to the remote endpoint."
  type        = string
}

variable "client_subnet" {
  description = "The internal IP space which VPN clients will reside."
  type        = string
}
variable "external_allowed_cidr_blocks" {
  description = "A list of public CIDR ranges which can establish connectivity to Wireguard."
  type        = list(string)
}

variable "hosted_zone_id" {
  description = "The Route53 Hosted Zone ID. Required to allow ChangeResourceRecordSets in Route53 for the Zone."
  type        = string
}

variable "endpoint_fqdn" {
  description = "The public FQDN record you wish to assign to the endpoint inside the Hosted Zone above."
  type        = string
}

variable "endpoint_ttl" {
  description = "The time-to-live value for the endpoint DNS record"
  type        = number
  default     = 300
}

variable "ansible_playbook_url" {
  description = "The location of the bootstrap-wireguard-ec2 Ansible playbook. This can be changed if you have forked it."
  type        = string
  default     = "https://github.com/gavmain/bootstrap-wireguard-ec2.git"
}

variable "ansible_playbook_release" {
  description = "The version of the Ansible playbook to install."
  type        = string
  default     = "v0.1.1"
}

variable "ansible_playbook_directory" {
  description = "The directory to git clone the ansible playbook into"
  type        = string
  default     = "~/bootstrap-wireguard-ec2"
}
