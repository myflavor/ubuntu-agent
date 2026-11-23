# ubuntu-agent

An Ubuntu 24.04 image for running agents. On every container start, the entrypoint:

1. Takes the first directory under `/home` as the username and reads its UID/GID
2. Runs as root if `/home` is empty or that directory is owned by root
3. Removes only what it created last time: the user recorded in `/var/lib/agent/user` and the `agent` group. Other users/groups are never touched
4. Creates the `agent` group with that GID and the user with that UID (primary group `agent`; `-o` allows sharing an ID already taken). The username is recorded before `useradd`, so a crash midway is still cleaned up on the next start. Then overwrites `/etc/sudoers.d/agent` with `<user> ALL=(ALL) NOPASSWD:ALL` and drops privileges via `gosu`

## Usage

```bash
docker run -it --rm -v /home/xin:/home/xin ghcr.io/myflavor/ubuntu-agent:latest
```

Or `docker compose run --rm agent`.

## Publishing

Pushing to `main` or a `v*` tag triggers GitHub Actions to build a multi-arch (amd64/arm64) image and push it to `ghcr.io/myflavor/ubuntu-agent`.
