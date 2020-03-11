#!/bin/bash
set -euxo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export SNAPCRAFT_ENABLE_DEVELOPER_DEBUG=yes
export PATH="$PATH:/snap/bin"

rm -f "${DIR}/*.snap"

# avoid random errors with stuck instances
command -v multipass >/dev/null && \
    multipass delete --purge snapcraft-molecule || true

# effective build of snap
command -v snapcraft
snapcraft snap

# testing the snap on supporting platforms
command -v snap >/dev/null && {
    snap install --devmode --classic ./*.snap
    molecule --version
    molecule drivers
}
