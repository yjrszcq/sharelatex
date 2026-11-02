#!/bin/sh
set -eu

# GIT_BRIDGE_ENABLED is the feature switch for both local and external modes.
# An explicit non-loopback host selects the externally deployed Git Bridge.
case "${GIT_BRIDGE_HOST:-127.0.0.1}" in
    127.0.0.1|localhost) local_bridge=true ;;
    *) local_bridge=false ;;
esac

if [ "${GIT_BRIDGE_ENABLED:-false}" = true ] && [ "$local_bridge" = true ]; then
    root_dir="$(readlink -m "${GIT_BRIDGE_ROOT_DIR:-/data/git-bridge}")"
    if [ "$root_dir" = / ]; then
        echo "GIT_BRIDGE_ROOT_DIR must be a dedicated data directory" >&2
        exit 1
    fi
    mkdir -p "$root_dir" /opt/git-bridge/conf
    chown -R git-bridge:git-bridge "$root_dir" /opt/git-bridge/conf
    rm -f /etc/service/git-bridge/down
else
    touch /etc/service/git-bridge/down
fi
