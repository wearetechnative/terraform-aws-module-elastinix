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
    command     = file("${path.module}/test-machine-up.sh")
    interpreter = ["bash", "-c"]
    environment = {
      INSTANCE_ID = self.id
      PUBLIC_IP   = var.associate_public_ip_address ? self.public_ip : ""
      SSH_ID_FILE = var.ssh_id_file
      # SSH-PRIVKEY = aws_ssm_parameter" "privkey_poormansql" #tls_private_key.poormansql.private_key_pem
      #SSH_PRIVKEY = var.ssh_privkey
      SSH_CONFIG_FILE = "../${path.module}/ssh_ec2_config"
      AWS_PROFILE     = var.aws_ssm_profile
    }
  }

  # NOTE this could prevent recreation when operated by other users
  lifecycle {
    #ignore_changes = all # TODO ENABLE when stable
  }
}

resource "null_resource" "ssh_workloads_key" {
  #count = var.associate_public_ip_address ? 0 : 1
  triggers = {
    live_config_path = var.live_config_path
  }

  provisioner "local-exec" {
    # TODO replace unset SSH_AUTH_SOCK with -o IdentitiesOnly=yes
    command = <<-EOT
      echo $TARGET >/tmp/debug-target.txt
      unset SSH_AUTH_SOCK
      cd secrets; agenix -d system_sshd_key.age --identity ${var.ssh_id_file} |  ssh -F ../${path.module}/ssh_ec2_config -oStrictHostKeyChecking=no -i ${var.ssh_id_file} $TARGET 'cat - > /tmp/system_sshd_key && chmod 600 /tmp/system_sshd_key && chown root:root /tmp/system_sshd_key' \
      EOT

    environment = {
      NIX_SSHOPTS     = "-F ${path.module}/ssh_ec2_config -i ${var.ssh_id_file}"
      SSH_ID_FILE     = var.ssh_id_file
      SSH_CONFIG_FILE = "${path.module}/ssh_ec2_config"
      AWS_PROFILE     = var.aws_ssm_profile
      TARGET          = var.associate_public_ip_address ? "root@${aws_instance.ec2nix_server.public_ip}" : "root@${aws_instance.ec2nix_server.id}"
      #TARGET = "root@${aws_instance.ec2nix_server.id}"
    }
  }
  #  depends_on = [resource.null_resource.nixos_deployment_ssm]
}

## INCREMENTAL PROVISIONER FOR SSM
resource "null_resource" "nixos_deployment_ssm" {
  #count = var.associate_public_ip_address ? 0 : 1
  triggers = {
    live_config_path = var.live_config_path
  }

  provisioner "local-exec" {
    # TODO replace unset SSH_AUTH_SOCK with -o IdentitiesOnly=yes
    command = <<-EOT
      echo $TARGET >/tmp/debug-target.txt
      unset SSH_AUTH_SOCK
      nix-copy-closure $TARGET ${var.live_config_path}

      ssh-keygen -R $TARGET \

      ssh -F ${path.module}/ssh_ec2_config \
        -oStrictHostKeyChecking=no \
        -i ${var.ssh_id_file} \
        #          $TARGET 'if [[ -d /data ]]; then chmod -f 777 /data ; chown -R 1001:root /data ; fi ' \

      ssh -F ${path.module}/ssh_ec2_config \
        -i ${var.ssh_id_file} \
        -oStrictHostKeyChecking=no \
        $TARGET '${var.live_config_path}/bin/switch-to-configuration switch && nix-collect-garbage'

      EOT

    environment = {
      NIX_SSHOPTS     = "-F ${path.module}/ssh_ec2_config -i ${var.ssh_id_file}"
      SSH_ID_FILE     = var.ssh_id_file
      SSH_CONFIG_FILE = "${path.module}/ssh_ec2_config"
      AWS_PROFILE     = var.aws_ssm_profile
      TARGET          = var.associate_public_ip_address ? "root@${aws_instance.ec2nix_server.public_ip}" : "root@${aws_instance.ec2nix_server.id}"
      #TARGET = "root@${aws_instance.ec2nix_server.id}"
    }
  }
}

resource "aws_volume_attachment" "ec2nix_server_vol" {
  count       = var.ebs_volume_id != "" ? 1 : 0
  device_name = "/dev/xvdb"
  volume_id   = var.ebs_volume_id
  instance_id = aws_instance.ec2nix_server.id
}

resource "aws_security_group" "ec2nix_security_group" {

  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.ingress_ports

    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = var.ingress_from_to_ports

    content {
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ## FOR SSM BE SURE 443 is open
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
