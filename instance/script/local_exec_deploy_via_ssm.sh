#!/usr/bin/env bash

echo $TARGET >> /tmp/debug-target.txt

AWS_PROFILE=$($SCRIPT_PATH/find_profile.sh $AWS_ACCOUNT_ID)
echo $AWS_PROFILE >> /tmp/debug-target.txt

# TODO replace unset SSH_AUTH_SOCK with -o IdentitiesOnly=yes
unset SSH_AUTH_SOCK

echo
echo "UPDATE KNOWN HOSTS"
ssh-keygen -R $(echo $TARGET | sed "s/root@//")

echo
echo "NIX-COPY-CLOSURE"
nix-copy-closure $TARGET $LIVE_CONFIG_PATH

echo
echo "NIX SWITCH TO NEW CONFIG"
ssh -F $SSH_CONFIG_FILE -i $SSH_ID_FILE -oStrictHostKeyChecking=no $TARGET "$LIVE_CONFIG_PATH/bin/switch-to-configuration switch"

# TODO MAKE OPTIONAL
echo
echo "NIX GARBAGE COLLECT"
ssh -F $SSH_CONFIG_FILE -i $SSH_ID_FILE -oStrictHostKeyChecking=no $TARGET 'nix-collect-garbage'

