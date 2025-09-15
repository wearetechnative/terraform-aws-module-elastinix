locals {
  unique_resource_identifier = lower(replace("${var.name}-${var.infra_environment}-${var.aws_account_id}", "_", "-"))
}

resource "aws_instance" "ec2nix_server" {

  tags = merge(
    {
      Name = local.unique_resource_identifier
    },
    var.tags
  )

  subnet_id = var.subnet_id

  availability_zone = var.availability_zone
  ami               = var.ec2nix_ami_id
  instance_type     = var.instance_type

  associate_public_ip_address = var.associate_public_ip_address

  vpc_security_group_ids = [aws_security_group.ec2nix_security_group.id]

  iam_instance_profile = var.iam_instance_profile

  hibernation = var.hibernation

  root_block_device {
    volume_size = var.root_initial_size
    volume_type = var.volume_type
    encrypted   = var.hibernation ? true : false
  }

  provisioner "local-exec" {

    command     = file("${path.module}/script/local_exec_test_machine_up.sh")
    interpreter = ["bash", "-c"]

    environment = {
      INSTANCE_ID     = self.id
      PUBLIC_IP       = var.associate_public_ip_address ? self.public_ip : ""
      SSH_ID_FILE     = var.ssh_id_file
      SSH_CONFIG_FILE = "${path.module}/ssh.conf"
      SCRIPT_PATH     = "${path.module}/script"
      AWS_ACCOUNT_ID  = var.aws_account_id
    }
  }

  # NOTE this could prevent recreation when operated by other users
  lifecycle {
    #ignore_changes = all # TODO ENABLE when stable
  }
}
