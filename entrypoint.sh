#!/usr/bin/env bash
set -euo pipefail

log() { echo "[entrypoint] $*" >&2; }

GROUP_NAME=agent
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

GROUP_FILE=/var/lib/agent/group
USER_FILE=/var/lib/agent/user
mkdir -p "$(dirname "${USER_FILE}")"

if [ ! -f "${GROUP_FILE}" ]; then
    groupadd -o -g "${HOST_GID}" "${GROUP_NAME}"
    echo "${GROUP_NAME}" > "${GROUP_FILE}"
fi

if [ ! -f "${USER_FILE}" ]; then
    useradd -o -M -u "${HOST_UID}" -g "${GROUP_NAME}" -d "${HOME_DIR}" -s /bin/bash "${USER_NAME}"
    echo "${USER_NAME}" > "${USER_FILE}"
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USER_NAME}"
    chmod 0440 "/etc/sudoers.d/${USER_NAME}"
fi

RUN_UID="$(id -u "${USER_NAME}")"
RUN_GID="$(id -g "${USER_NAME}")"
log "Running as ${USER_NAME} (${RUN_UID}:${RUN_GID})"
cd "${HOME_DIR}"
exec gosu "${USER_NAME}" "$@"
