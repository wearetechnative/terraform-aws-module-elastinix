#!/usr/bin/env bash


echo
echo "UPDATE KNOWN HOSTS"
ssh-keygen -R $(echo $TARGET | sed "s/root@//")

export AWS_PROFILE=$($SCRIPT_PATH/find_profile.sh $AWS_ACCOUNT_ID)

# TODO only if debug=true
echo $AWS_PROFILE >> /tmp/debug-target.txt
echo $TARGET >> /tmp/debug-target.txt

# TODO replace unset SSH_AUTH_SOCK with -o IdentitiesOnly=yes
unset SSH_AUTH_SOCK

CURR_DIR=$(pwd)
echo $CURR_DIR

cd secrets
SYS_SSH_KEY=$(agenix -d system_sshd_key.age --identity $SSH_ID_FILE)
cd $CURR_DIR

echo $SYS_SSH_KEY | ssh -F $SSH_CONFIG_FILE -oStrictHostKeyChecking=no -i $SSH_ID_FILE \
  $TARGET 'cat - > /tmp/system_sshd_key && chmod 600 /tmp/system_sshd_key && chown root:root /tmp/system_sshd_key'
