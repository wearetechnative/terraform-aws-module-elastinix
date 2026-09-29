# CHANGELOG

## NEXT VERSION

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
