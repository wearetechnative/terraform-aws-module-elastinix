#!/usr/bin/env bash

set -e
test -n "$INSTANCE_ID" || (echo missing INSTANCE_ID; exit 1)
test -n "$SSH_ID_FILE" || (echo missing SSH_ID_FILE; exit 1)
test -n "$SSH_CONFIG_FILE" || (echo missing SSH_CONFIG_FILE; exit 1)
set +e

AWS_PROFILE=$($SCRIPT_PATH/find_profile.sh $AWS_ACCOUNT_ID)
echo $AWS_PROFILE >> /tmp/debug-target.txt

cleanup() {
  exit $!
}

for try in {0..100}; do
  echo "Polling for machine to come up. Retry #$try"
  unset SSH_AUTH_SOCK

  if [[ -z "${PUBLIC_IP}" ]]; then
    ssh -F $SSH_CONFIG_FILE -i "$SSH_ID_FILE" -oStrictHostKeyChecking=no "root@$INSTANCE_ID" uptime
  else
    ### TODO MAKE CONFIG SWITCH OR ALWAYS USE SSM
    ssh -F $SSH_CONFIG_FILE -i "$SSH_ID_FILE" -oStrictHostKeyChecking=no "root@$INSTANCE_ID" uptime
    #ssh -i "$SSH_ID_FILE" -oStrictHostKeyChecking=no "root@$PUBLIC_IP" uptime
  fi

  success="$?"
  if [ "$success" -eq 0 ]; then
    echo "Machine ${INSTANCE_ID} up and ready to for provisioning over SSM/SSH"
    echo ""
    #echo "Add the the systems private key to agenix and run rekey (agenix -r -i PRIVATE_KEY)"
    #cat /etc/ssh/ssh_host_ed25519_key.pub
    #echo
    cleanup 0
  fi
  sleep 5s
done

echo "Failed to poll for machine up status"
cleanup 1
