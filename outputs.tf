output "wireguard_security_group_id" {
  value       = aws_security_group.wireguard_endpoint.id
  description = "The ID of the security group attached to the Wireguard endpoint"
}

output "wireguard_endpoint_instance_id" {
  value       = aws_instance.wireguard_endpoint_instance.id
  description = "The ID of the Wireguard Endpoint instance"
}
