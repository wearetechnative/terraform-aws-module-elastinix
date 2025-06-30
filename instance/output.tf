output "instance_id" {
  value = aws_instance.ec2nix_server.id
}
output "instance_arn" {
  value = aws_instance.ec2nix_server.arn
}

output "public_ip" {
  value = var.associate_public_ip_address ? aws_instance.ec2nix_server.public_ip : ""
}

output "private_ip" {
  value = aws_instance.ec2nix_server.private_ip
}

