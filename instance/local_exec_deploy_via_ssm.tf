resource "null_resource" "nixos_deployment_ssm" {

  triggers = {
    live_config_path = var.live_config_path
  }

  provisioner "local-exec" {

    command     = file("${path.module}/script/local_exec_deploy_via_ssm.sh")
    interpreter = ["bash", "-c"]

    environment = {
      LIVE_CONFIG_PATH = var.live_config_path
      NIX_SSHOPTS      = "-F ${path.module}/ssh.conf -i ${var.ssh_id_file}"
      SSH_ID_FILE      = var.ssh_id_file
      AWS_ACCOUNT_ID  = var.aws_account_id
      SCRIPT_PATH     = "${path.module}/script"
      SSH_CONFIG_FILE  = "${path.module}/ssh.conf"
      TARGET           = var.associate_public_ip_address ? "root@${aws_instance.ec2nix_server.public_ip}" : "root@${aws_instance.ec2nix_server.id}"
    }
  }
}
