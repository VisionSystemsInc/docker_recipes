#!/usr/bin/env sh

#*# docker/recipes/verify_gpg.sh

#**
# ==========
# verify gpg
# ==========
#
# .. default-domain:: bash
#
# .. file:: verify_gpg.sh
#
# A script to help verify a gpg signature.
#
# :Arguments: * ``$1`` - File to check
#             * ``$2`` - Checksum file. Can be a file path or URL.
#             * ``$3`` - GPG Key ID
#**

# GPG server list
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
  #**
  # .. function:: recv_key
  #
  # Receive the gpg from a common list of gpg key servers
  #
  # :Arguments: * ``$1`` - GPG Key ID
  #
  # .. envvar:: GPG_SERVER_TIMEOUT
  #
  # Timeout before giving up and trying the next server. Each server is only tried once. Default: ``30``
  #**

  local server

  for server in $(shuf -e ${gpg_servers}); do
    if timeout "${GPG_SERVER_TIMEOUT}" gpg --batch --keyserver "${server}" --recv-keys "${1}"; then
      return 0
    fi
  done
  return 1
}

function verify_gpg_signature()
{
  #**
  # .. function:: verify_gpg_signature
  #
  # Helper to load a gpg key and test file
  #
  # :Arguments: * ``$1`` - File to check
  #             * ``$2`` - Checksum file. Can be a file path or URL.
  #             * ``$3`` - GPG Key ID
  #
  # .. envvar:: SKIP_GPG_VERIFY
  #
  # Set to ``1`` to skip all GPG checks
  #**

  local file_name=${1}
  local checksum=${2}
  local gpg_id=${3}

  local GNUPGHOME=${GNUPGHOME-/dev/shm}
  export GNUPGHOME

  if [ "${SKIP_GPG_VERIFY}" != "1" ]; then
    if [ "${checksum:0:7}" = "http://" -o "${checksum:0:8}" = "https://" ]; then
      curl -fsSLo /dev/shm/checksum.asc "${checksum}"
      checksum=/dev/shm/checksum.asc
    fi

    recv_key "${gpg_id}"
    gpg --batch --verify "${checksum}" "${file_name}"
  fi
}

if [ -n "${BASH_SOURCE+set}" ]; then
  if [ "${BASH_SOURCE[0]}" = "${0}" ] || [ "$(basename "${BASH_SOURCE[0]}")" = "${0}" ]; then
    verify_gpg_signature "${@}"
  fi
elif [ "${0:${#0}-13:13}" = "verify_gpg.sh" ]; then
  verify_gpg_signature "${@}"
fi
