#!/usr/bin/env bash
#
# Copy the built NixOS closure to the target and activate it.
#
# Two failures used to pass unnoticed here, and they compounded each other.
#
# A failed activation still reported success: the script had no `set -e`, and
# `switch-to-configuration` was not the last command -- `nix-collect-garbage`
# ran after it, so the script exited on the garbage collector's status and
# Terraform printed "Apply complete!" over a host whose activation had failed.
#
# A run that died left a `nix-store --serve` on the target still holding a path
# lock, with its connection already gone. The next deploy then blocked on that
# lock indefinitely, printing nothing to say why.
#
# So: fail loudly, and refuse to start when the previous run left something
# behind.

set -eo pipefail

echo "$TARGET" >> /tmp/debug-target.txt

AWS_PROFILE=$("$SCRIPT_PATH/find_profile.sh" "$AWS_ACCOUNT_ID") || exit 1
export AWS_PROFILE
echo "$AWS_PROFILE" >> /tmp/debug-target.txt

# Select ssh identity (on-disk key vs rbw/agent) -> sets KEYFILE, SSH_I, NIX_SSHOPTS
# (NIX_SSHOPTS is overridden here so nix-copy-closure uses the same identity)
# shellcheck source=/dev/null
source "$SCRIPT_PATH/lib_ssh_identity.sh"

# shellcheck disable=SC2086 # SSH_I is a two-word argument on purpose
target_ssh() {
  ssh -F "$SSH_CONFIG_FILE" ${SSH_I} -oStrictHostKeyChecking=no "$TARGET" "$@"
}

echo
echo "UPDATE KNOWN HOSTS"
# Absent from known_hosts is the normal case, not an error.
ssh-keygen -R "${TARGET#root@}" || true

echo
echo "CHECK FOR A PREVIOUS DEPLOY"
# `nix-store --serve` is the receiving end of nix-copy-closure. Ours has not
# started yet, so anything running now belongs to an earlier deploy: either one
# still in progress, which must not be raced, or one that died and left a
# process holding a path lock that nothing will ever release.
#
# Matched on the process name rather than the command line: `pgrep -f` would
# also match this very check, which is how the problem hid for an afternoon.
# shellcheck disable=SC2086,SC2016 # SSH_I is two words; the quoted block runs on the target
stale=$(timeout 60 ssh -F "$SSH_CONFIG_FILE" ${SSH_I} -oStrictHostKeyChecking=no "$TARGET" '
  for p in $(pgrep -x nix-store 2>/dev/null); do
    tr "\0" " " < /proc/$p/cmdline 2>/dev/null | grep -q -- "--serve" || continue
    printf "  pid %s  running for %ss  holding: %s\n" \
      "$p" \
      "$(ps -o etimes= -p "$p" 2>/dev/null | tr -d " ")" \
      "$(ls -l /proc/$p/fd 2>/dev/null | grep -o "/nix/store/[^ ]*\.lock" | tr "\n" " ")"
  done' 2>/dev/null) || {
  echo "(could not check the target; continuing, the copy will report any real problem)"
  stale=""
}

if [ -n "$stale" ]; then
  echo "ERROR: the target already has a nix-store --serve from an earlier deploy:" >&2
  echo "$stale" >&2
  cat >&2 <<MSG

Refusing to start. Either another deploy is in progress -- wait for it -- or a
previous one died and left this behind, in which case it will hold its path lock
forever and this deploy would hang on it with no explanation.

Inspect and, if it is wreckage, clear it:

  ssh $TARGET 'ps -o pid,etimes,args -p <pid>'
  ssh $TARGET 'kill <pid>'

Killing it is safe: Nix does not register a store path as valid until it is
complete, so the next writer takes the lock, discards the partial path and
writes it again.
MSG
  exit 1
fi
echo "none"

echo
echo "NIX-COPY-CLOSURE"
# With USE_SUBSTITUTES=true the target first fetches whatever its own
# substituters can serve, and only the remainder travels over SSH. Unset or
# false gives exactly the command this script has always run.
NIX_COPY_FLAGS=""
if [ "${USE_SUBSTITUTES:-false}" = "true" ]; then
  NIX_COPY_FLAGS="--use-substitutes"
  echo "(using the target's substituters)"
fi
# shellcheck disable=SC2086 # NIX_COPY_FLAGS is empty or a single flag
nix-copy-closure $NIX_COPY_FLAGS "$TARGET" "$LIVE_CONFIG_PATH"

echo
echo "NIX SWITCH TO NEW CONFIG"
# Captured rather than left to `set -e`, so the garbage collection below still
# runs. The status is what this script exits on.
switch_status=0
target_ssh "$LIVE_CONFIG_PATH/bin/switch-to-configuration switch" || switch_status=$?

# TODO MAKE OPTIONAL
echo
echo "NIX GARBAGE COLLECT"
# Never allowed to decide the outcome: it used to be the last command, which is
# precisely how a failed activation came out as success.
target_ssh 'nix-collect-garbage' || echo "WARNING: garbage collection failed; not treating that as a deploy failure"

if [ "$switch_status" -ne 0 ]; then
  echo >&2
  echo "ERROR: switch-to-configuration exited $switch_status on $TARGET." >&2
  echo "The closure was copied, but the host is not running it as intended." >&2
  echo "Check the activation output above; agenix chown failures are a common cause." >&2
  exit "$switch_status"
fi
