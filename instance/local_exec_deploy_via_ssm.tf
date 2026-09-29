resource "null_resource" "nixos_deployment_ssm" {

  # The key has to be on the host before the switch: agenix reads it from
  # /tmp/system_sshd_key during activation. Without this the two local-execs may
  # run in either order, and the losing order fails the activation.
  depends_on = [null_resource.upload_ssh_workloads_key]

  triggers = {
    live_config_path = var.live_config_path
    # Included so flipping the flag alone redeploys. Without it a switched flag
    # would sit unused until the closure happened to change, and look like a
    # setting that does nothing.
    use_substitutes = var.use_substitutes
    # The instance id, or a replaced instance is never deployed to. It appears
    # below only as TARGET, which is not a trigger, so recreating the machine
    # while the closure stays the same left it running the bootstrap image with
    # no configuration at all -- and the apply reported success. Seen on
    # compute4-nonprod, 2026-09-29.
    instance_id = aws_instance.ec2nix_server.id
  }

  provisioner "local-exec" {

    command     = file("${path.module}/script/local_exec_deploy_via_ssm.sh")
    interpreter = ["bash", "-c"]

    environment = {
      LIVE_CONFIG_PATH = var.live_config_path
      USE_SUBSTITUTES  = var.use_substitutes
      NIX_SSHOPTS      = "-F ${path.module}/ssh.conf -i ${var.ssh_id_file}"
      SSH_ID_FILE      = var.ssh_id_file
      AWS_ACCOUNT_ID   = var.aws_account_id
      SCRIPT_PATH      = "${path.module}/script"
      SSH_CONFIG_FILE  = "${path.module}/ssh.conf"
      # TARGET           = var.associate_public_ip_address ? "root@${aws_instance.ec2nix_server.public_ip}" : "root@${aws_instance.ec2nix_server.id}"
      TARGET = "root@${aws_instance.ec2nix_server.id}"
    }
  }
}
