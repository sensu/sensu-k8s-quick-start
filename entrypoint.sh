#!/bin/sh

# detect the linux distribution
which_linux_distro() {
  if ls /etc/*release 1> /dev/null 2>&1; then
    for DISTRO in alpine debian centos "red hat"
    do
      if grep -iq "${DISTRO}" /etc/*release; then
        echo ${DISTRO}
        return 0
      fi
    done
  else
    return 1
  fi
}

# update the CA trust store (if ca-certificates or equivalent is installed)
update_ca_trust_store() {
  if [ -n $1 ]; then
    echo "INFO: Attempting to update CA Trust Store..."
    case $1 in
      alpine)
        if $(command -v update-ca-certificates); then
          update-ca-certificates
          return 0
        else
          echo "INFO: update-ca-certificates not available"
          return 1
        fi
        ;;
      debian)
        if $(command -v update-ca-certificates); then
          update-ca-certificates
          return 0
        else
          echo "INFO: update-ca-certificates not available"
          return 1
        fi
        ;;
      centos|"red hat")
        if $(command -v update-ca-trust); then
          update-ca-trust force-enable
          update-ca-trust extract
          return 0
        else
          echo "INFO: update-ca-trust not available"
          return 1
        fi
        ;;
      *)
        return 1
        ;;
    esac
  else
    return 1
  fi
}

# detect platform and update CA trust store
if OS=$(which_linux_distro); then
  if (update_ca_trust_store "${OS}"); then
    echo "INFO: CA Trust Store updated successfully!"
  else
    echo "INFO: Unable to update CA Trust Store (continuing)"
  fi
else
  echo "ERROR: unknown Linux distribution (supported platforms: alpine debian centos redhat)"
  exit 2
fi

# execute the desired start command (passthrough all positional arguments as a command)
exec "$@"
