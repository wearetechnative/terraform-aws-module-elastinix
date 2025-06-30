#!/usr/bin/env bash
set -ex
test -n "$INSTANCE_ID" || (echo missing INSTANCE_ID; exit 1)
test -n "$SSH_ID_FILE" || (echo missing SSH_ID_FILE; exit 1)
#wto#test -n "$SSH_PRIVKEY" || (echo missing SSH_PRIVKEY; exit 1)
test -n "$SSH_CONFIG_FILE" || (echo missing SSH_CONFIG_FILE; exit 1)
#test -n "$PUBLIC_IP" || (echo missing PUBLIC_IP; exit 1)

set +e

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
    cleanup 0
  fi
  sleep 5s
done

echo "Failed to poll for machine up status"
cleanup 1
