#!/usr/bin/env bash
# Shared helper: selects the ssh identity based on whether a real private key
# exists on disk. Source this file (do not execute it).
#
#   ~/.ssh/<key> is a real, non-empty file   -> user WITHOUT rbw:
#       use that private key file and disable the ssh-agent (classic behaviour).
#   ~/.ssh/<key> is empty (0-byte) or absent  -> rbw user:
#       use the matching .pub so the rbw ssh-agent signs (do NOT disable the agent).
#
# Expects in the environment: SSH_ID_FILE, SSH_CONFIG_FILE.
# Sets: KEYFILE, SSH_I (the "-i ..." argument) and NIX_SSHOPTS (for nix-copy-closure).

KEYFILE="${HOME}/.ssh/$(basename "${SSH_ID_FILE}")"

if [ -s "${KEYFILE}" ]; then
  unset SSH_AUTH_SOCK
  SSH_I="-i ${KEYFILE}"
else
  SSH_I="-i ${KEYFILE}.pub"
fi

export NIX_SSHOPTS="-F ${SSH_CONFIG_FILE} ${SSH_I}"
