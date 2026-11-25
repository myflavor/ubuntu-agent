# ubuntu-agent

在 Docker 里运行交互式编码 agent（Claude Code、Gemini CLI 等）的 Ubuntu 24.04
镜像。镜像发布在 `ghcr.io/myflavor/ubuntu-agent`，支持 `linux/amd64` 和
`linux/arm64`。

## 基础用法

把下面的内容保存为 `docker-compose.yml`：

```yaml
services:
  agent:
    image: ghcr.io/myflavor/ubuntu-agent
    volumes:
      - /home/xin:/home/xin
    working_dir: /home/xin
    environment:
      TERM: xterm-256color
    stdin_open: true
    tty: true
```

运行：

```bash
docker compose up -d
docker compose exec -u xin agent bash -l
```

## WSL用法

```yaml
services:
  agent:
    image: ghcr.io/myflavor/ubuntu-agent:latest
    working_dir: /home/xin
    volumes:
      - /mnt:/mnt:ro
      - /run/WSL:/run/WSL:ro
      - /run/wsl:/run/wsl:ro
      - /home/xin:/home/xin
    environment:
      TERM: xterm-256color
      WSL_INTEROP: /run/WSL/1_interop
      WSL_DISTRO_NAME: Ubuntu-24.04
    privileged: true
    stdin_open: true
    tty: true
```

说明：

在 WSL 里用这份 compose 代替基础用法里的那份，保存为 `docker-compose.yml`，运行方式相同。

- `WSL_DISTRO_NAME` 改成 `wsl.exe -l -q` 的输出。
- `WSL_INTEROP` 固定写成 `/run/WSL/1_interop`。不要用 `${WSL_INTEROP}`：它是
  每个终端会话一个 socket，compose 只在创建容器时取一次值，会话结束就失效。
- `privileged: true` 用来放行 `socket(AF_VSOCK)`，等价于把这个容器当成 WSL
  root；也可以换成 `security_opt: [seccomp:unconfined]`。Docker 默认的 seccomp
  会拦 AF_VSOCK。
- `/run/WSL` 和 `/run/wsl` 两个挂载缺一不可。

## 说明

镜像基于 Ubuntu 24.04，预装 `git`、`curl`、`wget`、`jq`、`vim`、
`build-essential`、Python 3、`openssh-client`、`sudo` 等常用工具。

容器启动时会取 `/home` 下第一个目录作为用户名和 UID/GID，创建同名用户、写入
`NOPASSWD` sudo，然后用 `gosu` 降权运行；如果 `/home` 为空或属主是 root，则以
root 运行。容器内创建的文件因此会属于你的宿主用户。

## 构建与发布

推 `v*` tag 会触发 GitHub Actions，构建 amd64/arm64 并推送到
`ghcr.io/myflavor/ubuntu-agent`：

```bash
git tag v1.0.0 && git push origin v1.0.0
```

会发布 `1.0.0`、`1.0`、`1` 和 `latest`（`v1.1.0-rc.1` 这类预发布 tag 不更新
`latest`）。
