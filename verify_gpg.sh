#!/usr/bin/env sh

gpg_servers="ha.pool.sks-keyservers.net"
gpg_servers="${gpg_servers} hkp://p80.pool.sks-keyservers.net:80"
gpg_servers="${gpg_servers} keys.openpgp.org"
gpg_servers="${gpg_servers} hkp://keys.openpgp.org:80"
gpg_servers="${gpg_servers} keyserver.ubuntu.com"
gpg_servers="${gpg_servers} hkp://keyserver.ubuntu.com:80"
gpg_servers="${gpg_servers} pgp.mit.edu"
gpg_servers="${gpg_servers} hkp://pgp.mit.edu:80"

: ${GPG_SERVER_TIMEOUT=10}

function recv_key()
{
  # $1 - GPG Key ID
  local server
  for server in $(shuf -e ${gpg_servers}); do
    timeout "${GPG_SERVER_TIMEOUT}" gpg --batch --keyserver "${server}" --recv-keys "${1}" && return 0 || :
  done
  return 1
}

function process_key()
{
  # Helper to load a gpg key from common remote list
  # $1 - File to check
  # $2 - Checksum file. Can be a file path or URL.
  # $3 - GPG Key ID

  file_name=${1}
  checksum=${2}
  gpg_id=${3}

  if [ "${SKIP_GPG_VERIFY}" != "1" ]; then \
    if [ "${checksum:0:7}" = "http://" -o "${checksum:0:8}" = "https://" ]; then
      curl -fsSLo /dev/shm/checksum.asc "${checksum}"
      checksum=/dev/shm/checksum.asc
    fi

    local GNUPGHOME=${GNUPGHOME-/dev/shm}
    export GNUPGHOME

    recv_key "${gpg_id}"
    gpg --batch --verify "${checksum}" "${file_name}"
  fi
}

if [ -n "${BASH_SOURCE+set}" ]; then
  if [ "${BASH_SOURCE[0]}" = "${0}" ] || [ "$(basename "${BASH_SOURCE[0]}")" = "${0}" ]; then
    process_key "${@}"
  fi
elif [ "${0:${#0}-13:13}" = "verify_gpg.sh" ]; then
  process_key "${@}"
fi
