#!/usr/bin/env bash

echo $TARGET >> /tmp/debug-target.txt

AWS_PROFILE=$($SCRIPT_PATH/find_profile.sh $AWS_ACCOUNT_ID) || exit 1
export AWS_PROFILE
echo $AWS_PROFILE >> /tmp/debug-target.txt

# Select ssh identity (on-disk key vs rbw/agent) -> sets KEYFILE, SSH_I, NIX_SSHOPTS
# (NIX_SSHOPTS is overridden here so nix-copy-closure uses the same identity)
source "$SCRIPT_PATH/lib_ssh_identity.sh"

echo
echo "UPDATE KNOWN HOSTS"
ssh-keygen -R $(echo $TARGET | sed "s/root@//")

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
nix-copy-closure $NIX_COPY_FLAGS $TARGET $LIVE_CONFIG_PATH

echo
echo "NIX SWITCH TO NEW CONFIG"
ssh -F $SSH_CONFIG_FILE ${SSH_I} -oStrictHostKeyChecking=no $TARGET "$LIVE_CONFIG_PATH/bin/switch-to-configuration switch"

# TODO MAKE OPTIONAL
echo
echo "NIX GARBAGE COLLECT"
ssh -F $SSH_CONFIG_FILE ${SSH_I} -oStrictHostKeyChecking=no $TARGET 'nix-collect-garbage'
