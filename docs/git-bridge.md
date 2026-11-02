# Git Bridge：内置或外部服务

镜像内置与 `IMAGE_VERSION` 同版本的官方 Git Bridge 程序及 Java 21 运行环境，支持 amd64 和 arm64，沿用主镜像的 runit 进行进程管理。

`GIT_BRIDGE_ENABLED` 是内置和外部模式共用的功能总开关，`GIT_BRIDGE_HOST` 只负责选择连接目标：

| GIT_BRIDGE_ENABLED | GIT_BRIDGE_HOST | 行为 |
| --- | --- | --- |
| 未设置或 `false` | 任意值 | 主应用禁用 Git Bridge 集成，内置进程不启动 |
| `true` | 默认 `127.0.0.1` 或 `localhost` | 启动并使用内置 Git Bridge |
| `true` | 外部服务主机名或地址 | 使用外部 Git Bridge，内置进程不启动 |

## 内置模式（无需额外容器）

给主容器增加数据卷和环境变量即可：
```yaml
volumes:
  - ${OVERLEAF_DATA_PATH}/git-bridge:/data/git-bridge
environment:
  GIT_BRIDGE_ENABLED: "true"
```

主镜像默认 `GIT_BRIDGE_HOST=127.0.0.1`、`GIT_BRIDGE_PORT=8000`。内置服务通过回环地址访问主容器 API、OAuth 和 History，不需要额外对外开放 8000 端口。`GIT_BRIDGE_ENABLED` 未设置或为 `false` 时，两种模式的 Git Bridge 集成都关闭，内置 Java 进程也不启动。

仓库的 [docker-compose.yml](../docker-compose.yml) 已采用内置模式。创建/更新容器：
```bash
docker compose up -d
```

如果之前已按旧 Compose 运行了独立的 `ayakaleaf-git-bridge`，切换内置模式前先停止它，避免两个服务同时写入同一个数据目录：
```bash
docker stop ayakaleaf-git-bridge
docker compose up -d --remove-orphans
```

需要先构建并部署包含本次修改的新镜像，再按以上配置启用内置服务。

Git Bridge 使用专用的 `git-bridge` 用户运行；内置模式启动时会设置其数据目录所有权，保证挂载目录可写。仓库及数据库存放于 `/data/git-bridge`，请持久化这个目录。可通过 `GIT_BRIDGE_JVM_ARGS` 设置 Java 内存等参数，未设置时沿用官方启动脚本的默认值。

## 外部模式（兼容独立 Git Bridge）

给主容器显式指定外部主机和端口：
```yaml
environment:
  GIT_BRIDGE_ENABLED: "true"
  GIT_BRIDGE_HOST: "git-bridge"
  GIT_BRIDGE_PORT: "8000"
  V1_HISTORY_URL: "http://ayakaleaf:3100/api"
```

`GIT_BRIDGE_HOST` 为非本机主机名时，镜像不会启动内置 Git Bridge，而是连接你部署的服务。外部服务仍需使用与主镜像相同的版本，并正确设置其 API、OAuth、postback 和数据目录。

外部服务由用户自行部署。例如在 Compose 的 `services` 中增加：
```yaml
git-bridge:
  image: ghcr.io/ayaka-notes/overleaf-pro/git-bridge:6.3.2
  restart: unless-stopped
  volumes:
    - ${OVERLEAF_DATA_PATH}/git-bridge:/data/git-bridge
  environment:
    GIT_BRIDGE_API_BASE_URL: "http://ayakaleaf:3000/api/v0/"
    GIT_BRIDGE_OAUTH2_SERVER: "http://ayakaleaf"
    GIT_BRIDGE_POSTBACK_BASE_URL: "http://git-bridge:8000"
    GIT_BRIDGE_ROOT_DIR: "/data/git-bridge"
  user: root
  command: ["/server-pro-start.sh"]
```

镜像版本与主容器保持一致，服务名、主机名和 API 地址按实际部署调整。已有 Git Bridge 数据切换运行方式前，请备份并确认数据目录对实际运行用户可写。

## Toolkit 中使用

使用内置模式时，在 `config/overleaf.rc` 保持 `SERVER_PRO=true`、`GIT_BRIDGE_ENABLED=false`，避免 Toolkit 自己创建独立容器。然后在 `config/docker-compose.override.yml` 中启用主容器内置服务：
```yaml
services:
  sharelatex:
    volumes:
      - ${OVERLEAF_DATA_PATH}/git-bridge:/data/git-bridge
    environment:
      GIT_BRIDGE_ENABLED: "true"
```

使用外部模式时，在 `overleaf.rc` 中设置 `GIT_BRIDGE_ENABLED=true`，指定 `GIT_BRIDGE_IMAGE=ghcr.io/ayaka-notes/overleaf-pro/git-bridge`；并在上述 override 的 `sharelatex.environment` 中显式设置 `GIT_BRIDGE_HOST: "git-bridge"`、`GIT_BRIDGE_PORT: "8000"`。

完成配置后，在 Toolkit 根目录运行 `bin/up -d`。这只启用 Git Bridge；GitHub、GitLab 等第三方同步仍需各自的认证配置。
