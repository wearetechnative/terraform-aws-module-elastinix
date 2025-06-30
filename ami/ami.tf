locals {
  unique_resource_identifier = lower(replace("${var.name}-${var.infra_environment}-${var.aws_account_id}", "_", "-"))
}

resource "aws_ami" "ec2nix_ami" {
  name                = local.unique_resource_identifier # var.name
  virtualization_type = "hvm"
  root_device_name    = "/dev/xvda"
  ena_support         = true

  ebs_block_device {
    device_name = "/dev/xvda"
    snapshot_id = aws_ebs_snapshot_import.ec2nix_import.id
  }
}

resource "aws_s3_bucket" "ec2nix_bucket" {
  # bucket = lower(replace(var.name, "_", "-"))
  bucket = lower(replace(local.unique_resource_identifier, "_", "-"))
}

resource "aws_s3_object" "image_upload" {
  bucket = aws_s3_bucket.ec2nix_bucket.id
  key    = "nixos_bootstrap.vhd"
  source = var.bootstrap_img_path
}

resource "aws_ebs_snapshot_import" "ec2nix_import" {
  role_name = aws_iam_role.vmimport_role.id
  disk_container {
    format = "VHD"
    user_bucket {
      s3_bucket = aws_s3_bucket.ec2nix_bucket.id
      s3_key    = aws_s3_object.image_upload.id
    }
  }
  lifecycle {
    replace_triggered_by = [
      aws_s3_object.image_upload
    ]
  }
}

resource "aws_iam_role_policy_attachment" "vmpimport_attach" {
  role       = aws_iam_role.vmimport_role.id
  policy_arn = aws_iam_policy.vmimport_policy.arn
}

resource "aws_iam_role" "vmimport_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "vmie.amazonaws.com" }
        Action    = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:Externalid" = "vmimport"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "vmimport_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.ec2nix_bucket.id}",
          "arn:aws:s3:::${aws_s3_bucket.ec2nix_bucket.id}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:ModifySnapshotAttribute",
          "ec2:CopySnapshot",
          "ec2:RegisterImage",
          "ec2:Describe*"
        ],
        Resource = "*"
      }
    ]
  })
}
