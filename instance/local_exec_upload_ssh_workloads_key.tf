resource "null_resource" "upload_ssh_workloads_key" {
  triggers = {
    live_config_path = var.live_config_path
  }

  provisioner "local-exec" {
    command     = file("${path.module}/script/local_exec_upload_ssh_workloads_key.sh")
    interpreter = ["bash", "-c"]
    environment = {
      NIX_SSHOPTS     = "-F ${path.module}/ssh.conf -i ${var.ssh_id_file}"
      AWS_ACCOUNT_ID  = var.aws_account_id
      SCRIPT_PATH     = "${path.module}/script"
      SSH_ID_FILE     = var.ssh_id_file
      SSH_CONFIG_FILE = "${path.module}/ssh.conf"
      TARGET          = var.associate_public_ip_address ? "root@${aws_instance.ec2nix_server.public_ip}" : "root@${aws_instance.ec2nix_server.id}"
    }
  }
}
