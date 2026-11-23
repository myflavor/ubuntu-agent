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
mkdir -p "$(dirname "${USER_FILE}")"

if [ -f "${USER_FILE}" ]; then
    log "Removing previous user $(cat "${USER_FILE}")"
    userdel "$(cat "${USER_FILE}")" 2>/dev/null || true
    rm -f "${USER_FILE}"
fi
groupdel agent 2>/dev/null || true

groupadd -o -g "${HOST_GID}" agent

echo "${USER_NAME}" > "${USER_FILE}"
useradd -o -M -u "${HOST_UID}" -g agent -d "${HOME_DIR}" -s /bin/bash "${USER_NAME}"
echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/agent
chmod 0440 /etc/sudoers.d/agent

log "Running as ${USER_NAME} (${HOST_UID}:${HOST_GID})"
cd "${HOME_DIR}"
exec gosu "${USER_NAME}" "$@"
