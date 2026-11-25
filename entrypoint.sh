#!/usr/bin/env bash
set -euo pipefail

log() { echo "[entrypoint] $*" >&2; }

USER_NAME="$(ls /home | head -n1)"
if [ -z "${USER_NAME}" ]; then
    log "No directory under /home, running as root"
    exec "$@"
fi

HOME_DIR="/home/${USER_NAME}"
HOST_UID="$(stat -c %u "${HOME_DIR}")"
HOST_GID="$(stat -c %g "${HOME_DIR}")"

if [ "${HOST_UID}" -eq 0 ]; then
    log "${HOME_DIR} is owned by root, running as root"
    exec "$@"
fi

USER_FILE=/var/lib/agent/user
GROUP_FILE=/var/lib/agent/group
mkdir -p "$(dirname "${USER_FILE}")"

if [ ! -f "${GROUP_FILE}" ]; then
    groupadd -o -g "${HOST_GID}" agent
    echo "${HOST_GID}" > "${GROUP_FILE}"
fi

if [ ! -f "${USER_FILE}" ]; then
    useradd -o -M -u "${HOST_UID}" -g agent -d "${HOME_DIR}" -s /bin/bash "${USER_NAME}"
    echo "${USER_NAME}" > "${USER_FILE}"
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/agent
    chmod 0440 /etc/sudoers.d/agent
fi

RUN_UID="$(id -u "${USER_NAME}")"
RUN_GID="$(id -g "${USER_NAME}")"
log "Running as ${USER_NAME} (${RUN_UID}:${RUN_GID})"
cd "${HOME_DIR}"
exec gosu "${USER_NAME}" "$@"
