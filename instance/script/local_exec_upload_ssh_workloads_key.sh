#!/usr/bin/env bash


echo
echo "UPDATE KNOWN HOSTS"
ssh-keygen -R $(echo ${TARGET} | sed "s/root@//")

AWS_PROFILE=$(${SCRIPT_PATH}/find_profile.sh ${AWS_ACCOUNT_ID}) || exit 1
export AWS_PROFILE

# Select ssh identity (on-disk key vs rbw/agent) -> sets KEYFILE, SSH_I, NIX_SSHOPTS
source "${SCRIPT_PATH}/lib_ssh_identity.sh"

CURR_DIR=$(pwd)

cd secrets
if [ -s "${KEYFILE}" ]; then
  # Real private key on disk (user without rbw): agenix with the on-disk identity.
  SYS_SSH_KEY=$(agenix -d system_sshd_key.age --identity "${KEYFILE}")
else
  # No private key on disk (rbw user): ragenx pulls the identity from rbw (in-memory).
  SYS_SSH_KEY=$(ragenx -d system_sshd_key.age)
fi
cd ${CURR_DIR}

echo "${SYS_SSH_KEY}" | ssh -F ${SSH_CONFIG_FILE} -oStrictHostKeyChecking=no ${SSH_I} \
 ${TARGET} 'cat - > /tmp/system_sshd_key && chmod 600 /tmp/system_sshd_key && chown root:root /tmp/system_sshd_key'

