resource "aws_volume_attachment" "ec2nix_server_vol" {
  count       = var.ebs_volume_id != "" ? 1 : 0
  device_name = "/dev/xvdb"
  volume_id   = var.ebs_volume_id
  instance_id = aws_instance.ec2nix_server.id
}
