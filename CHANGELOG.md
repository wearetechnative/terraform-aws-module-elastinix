# CHANGELOG

## NEXT VERSION

### Fixed

- **A replaced instance is deployed to again.** `null_resource.nixos_deployment_ssm`
  and `null_resource.upload_ssh_workloads_key` triggered on `live_config_path`
  only; the instance id appeared solely as `TARGET` in the provisioner
  environment, which is not a trigger. Recreating the machine while the closure
  stayed the same therefore left it running the bootstrap image with no
  configuration, no secrets and no services -- and the apply reported success.
  Both resources now carry `instance_id` in their triggers.

  **On upgrade every host redeploys once**, because the trigger map gains a key.
  That is also the cure for any host currently sitting in that state.

- **The ssh key lands before the switch.** The two local-execs had no ordering
  between them, and agenix reads `/tmp/system_sshd_key` during activation, so the
  losing order failed every secret. `nixos_deployment_ssm` now depends on
  `upload_ssh_workloads_key`.

### Changed

- **A failed deploy now fails.** `switch-to-configuration` was not the last
  command in `local_exec_deploy_via_ssm.sh` -- `nix-collect-garbage` ran after
  it and, without `set -e`, the script exited on the garbage collector's status.
  Terraform therefore reported `Apply complete!` over hosts whose activation had
  failed. The switch's status is now what the script exits on; the garbage
  collection still runs but can no longer decide the outcome, and a failure
  there is a warning. `nix-copy-closure` failures abort as well.

  **This changes what consumers see.** A deploy that used to report success over
  a broken activation will now fail and Terraform will taint the resource. That
  is the point, but expect previously hidden breakage to surface on the first
  apply after upgrading.

### Added

- **Refuse to start when a previous deploy is holding a store path lock.** A run
  that dies leaves a `nix-store --serve` on the target holding a path lock that
  nothing will release; the next deploy then blocks on it indefinitely with
  nothing in the output to explain why. The script now checks the target first
  and stops with the process, its age, the lock it holds and the command to
  clear it.

  Keyed on the lock, not on the process. A `nix-store --serve` lingering without
  a lock is ordinary aftermath -- one survives every successful deploy for a
  minute or two, parented by an sshd-session that has not been reaped -- and
  blocks nobody. Refusing on its presence would refuse every second deploy in a
  row.

## nixos-25.05.1

- initial release of `terraform-aws-module-elastinix` the sister project of elastinix.
