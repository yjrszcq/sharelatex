# Ayakaleaf Pro 部署说明

本镜像基于 `ghcr.io/ayaka-notes/overleaf-pro`，保留完整 TeX Live 2026、系统中文字体及 `fonts/` 扩展。

官方参考：[Ayakaleaf Pro](https://github.com/ayaka-notes/ayakaleaf-pro/releases)、[Ayaka Toolkit](https://github.com/ayaka-notes/toolkit)。

## 使用此镜像

### 安装并配置 Ayakaleaf Pro

> Ayaka Toolkit 部署

#### 1. 拉取 Ayaka Toolkit 工具包
```
git clone https://github.com/ayaka-notes/toolkit.git ./overleaf-toolkit
```

#### 2. 进入 overleaf-toolkit 目录
```
cd ./overleaf-toolkit
```

#### 3. 初始化配置
```
bin/init
```
- 会在 config 目录下生成以下三个文件：
  - overleaf.rc
  - variables.env
  - version

#### 4. 进入 config 目录
```
cd config
```

#### 5. 编辑文件 `overleaf.rc`
```
# Ayakaleaf Pro container
OVERLEAF_IMAGE_NAME=szcq/sharelatex #更改镜像
OVERLEAF_DATA_PATH=/mydata/docker/overleaf/overleaf #数据的保存路径
SERVER_PRO=true
SIBLING_CONTAINERS_ENABLED=false #使用主容器内的 TeX Live 和字体
GIT_BRIDGE_ENABLED=false #如需 Git Bridge，按官方文档另行配置
MONGO_VERSION=8.0
OVERLEAF_LISTEN_IP=0.0.0.0 #如果不需要外部可访问，则填127.0.0.1
OVERLEAF_PORT=10802 #将该行修改为你所需服务端口，默认为80端口
```
- 其他的按需更改即可

#### 6. 编辑文件 `version`
```
6.3.2
```

#### 7. 配置必需的邀请令牌密钥并启动

运行 `openssl rand -base64 32`，将输出保存到 `config/variables.env`（不要提交密钥）：
```ini
OVERLEAF_INVITE_TOKEN_SECRET=生成的密钥
```

回到工具包根目录启动：
```bash
cd ..
```

初始化并启动 docker 服务
```
bin/up -d
```

#### 8. 创建管理员账户
- 进入以下页面，填写邮箱和密码，创建管理员账户
```
http://localhost:服务端口/launchpad
```

### 使用 Overleaf 官方 Toolkit

也可以使用 [Overleaf 官方 Toolkit](https://github.com/overleaf/toolkit)。官方通过 `OVERLEAF_IMAGE_NAME` 指定自定义镜像，再拼接 `config/version` 中的版本号，见 [官方镜像选择逻辑](https://github.com/overleaf/toolkit/blob/master/lib/shared-functions.sh)。以下配置使用主容器内的完整 TeX Live 和字体。

#### 1. 获取并初始化工具包

新部署执行：
```bash
git clone https://github.com/overleaf/toolkit.git ./overleaf-toolkit
cd ./overleaf-toolkit
bin/init
```

已有官方 Toolkit 的部署直接编辑现有配置，保留原数据路径；升级前先阅读下方“已有实例升级”。

#### 2. 编辑 `config/overleaf.rc`

修改对应配置项，其他数据路径、端口及 Redis 配置按现有部署保留：
```ini
OVERLEAF_IMAGE_NAME=szcq/sharelatex
SERVER_PRO=true
SIBLING_CONTAINERS_ENABLED=false
GIT_BRIDGE_ENABLED=false
MONGO_IMAGE=mongo
MONGO_VERSION=8.0
```

`OVERLEAF_IMAGE_NAME` 只填写镜像名称，不带版本号。`SIBLING_CONTAINERS_ENABLED=false` 使用本镜像内的 TeX Live 和字体，无需为编译挂载 Docker socket。若启用 Git Bridge 或沙盒编译，需要另行配置对应的 Ayakaleaf 服务/编译镜像。

#### 3. 编辑 `config/version`

填写已经构建并推送到 Docker Hub 的版本号：
```text
6.3.2
```

上述配置最终使用 `szcq/sharelatex:6.3.2`；部署版本应与运行 GitHub 工作流时填写的 `image_version` 一致。

#### 4. 配置邀请令牌密钥

运行 `openssl rand -base64 32`，将输出保存到 `config/variables.env`，不要提交密钥：
```ini
OVERLEAF_INVITE_TOKEN_SECRET=生成的密钥
```

#### 5. 启动

在 Toolkit 根目录执行：
```bash
bin/up -d
```

然后按上方步骤访问 `/launchpad` 创建管理员账户。此方式已核对官方 Toolkit 的配置逻辑，尚未实际启动验证；已有 MongoDB 5.x 数据仍需先逐级升级。

### 注意事项

#### 1. 若要在 Project 中使用中文，则要在编辑项目时，在左上角的 `MENU` 里，`Compiler` 选择 `XeLaTeX`

#### 2. 开始或停止运行
- 进入 overleaf-toolkit 目录
```
cd ./overleaf-toolkit
```

- 开始运行
```
bin/start
```

- 停止运行
```
bin/stop
```

#### 3. 本仓库默认使用主容器内的 TeX Live，文件 `overleaf.rc` 里的 Sibling Containers 设为 `false`
```
# Sibling Containers
SIBLING_CONTAINERS_ENABLED=false
DOCKER_SOCKET_PATH=/var/run/docker.sock
```

若改为沙盒编译，需要按 [官方说明](https://github.com/ayaka-notes/toolkit) 配置独立的 TeX Live 镜像；主容器的字体不会自动传入沙盒。

### 使用 Docker Compose

[docker-compose.yml](docker-compose.yml) 使用相同的多架构标签 `szcq/sharelatex:6.3.2`，不固定 `platform`。首次部署前在同目录的 `.env` 中保存上述生成的密钥：
```ini
OVERLEAF_INVITE_TOKEN_SECRET=生成的密钥
```

```bash
docker compose pull
docker compose up -d
```

示例使用 MongoDB 8.0 副本集，并等待初始化完成后启动 Ayakaleaf；保留原有 Redis 配置。已存在的副本集可重复启动。

### 已有实例升级

6.3.2 要求 MongoDB 至少 8.0（FCV 至少 7.0）以及 `OVERLEAF_INVITE_TOKEN_SECRET`。旧 Compose 使用 MongoDB 5.0，**不要将旧数据目录直接交给 MongoDB 8.0 启动**。先备份应用及数据库，按 [官方 MongoDB 升级说明](https://docs.overleaf.com/on-premises/maintenance/updating-mongodb) 逐级升级数据库并设置相应 FCV；应用也应按 [官方版本升级说明](https://docs.overleaf.com/on-premises/maintenance/upgrading) 完成所需中间版本迁移，再切换本镜像。仓库修改不会执行数据库或应用迁移。

从 6.2.x 或更早的 Ayakaleaf 升级且使用了 Zotero/Mendeley 时，还需先执行 [6.3.0 发布说明](https://github.com/ayaka-notes/ayakaleaf-pro/releases/tag/pro-v6.3.0) 中的迁移脚本，见 [6.3.2 升级说明](https://github.com/ayaka-notes/ayakaleaf-pro/releases/tag/pro-v6.3.2)。

### 容器创建后手动添加字体

- 仓库里提供了脚本 `install-sharelatex-fonts.sh`，用于在容器已经创建并运行后，手动把字体复制进容器并刷新字体缓存
- 脚本支持三种输入方式：字体 zip 文件、字体目录、单个字体文件
- 脚本默认容器名是 `sharelatex`；如果你的容器名不是这个值，需要用 `-c` 指定
- 当前 [docker-compose.yml](docker-compose.yml) 示例里的容器名是 `overleaf-sharelatex`

#### 1. 给脚本执行权限
```bash
chmod +x ./install-sharelatex-fonts.sh
```

#### 2. 使用 zip 文件导入字体
```bash
./install-sharelatex-fonts.sh -z Fonts.zip
./install-sharelatex-fonts.sh -c overleaf-sharelatex -z Fonts.zip
```

#### 3. 使用字体目录导入字体
```bash
./install-sharelatex-fonts.sh -d Fonts
./install-sharelatex-fonts.sh -c overleaf-sharelatex -d Fonts
```

#### 4. 使用单个字体文件导入字体
```bash
./install-sharelatex-fonts.sh -f simsun.ttc
./install-sharelatex-fonts.sh -c overleaf-sharelatex -f simhei.ttf
```

#### 5. 脚本会做的事情

- 将字体复制到容器内的 `/usr/share/fonts/addfonts`
- 如果输入的是 zip 文件，会在容器内自动安装 `unzip` 并解压
- 最后执行 `fc-cache -fv` 刷新字体缓存

#### 6. 注意事项

- 运行脚本前，请先确认 Ayakaleaf Pro 容器已经启动
- 如果脚本提示找不到容器，可以先执行 `docker ps --format '{{.Names}}'` 查看实际容器名
- 导入完成后，新编译的文档即可使用这些字体；如果项目仍识别不到中文字体，优先检查编译器是否为 `XeLaTeX`

## 自己制作镜像

### 配置 GitHub Actions

- 保留工作流 `.github/workflows/docker.yaml`，通过 `workflow_dispatch` 手动触发。
- 在 `Actions → Build and Push Docker Image → Run workflow` 中填写必填输入 `image_version`。工作流直接使用输入值作为官方基础镜像版本和发布标签，无需配置仓库变量 `IMAGE_VERSION`；使用 `X.Y.Z` 格式，并确认该官方标签支持两种架构。
- 在 `Secrets` 设置 `DOCKER_TOKEN`，值为可向 `szcq/sharelatex` 推送的 Docker Hub 访问令牌。
- 镜像账号和名称继续由工作流中的 `IMAGE_OWNER: szcq`、`IMAGE_NAME: sharelatex` 决定；发布到自己的账号时修改这两项。

### 更新版本信息

- 修改 `Dockerfile` 的 `ARG BASE_IMAGE=ghcr.io/ayaka-notes/overleaf-pro:6.3.2`，作为本地构建的默认基础镜像。
- 运行工作流时填写对应的 `image_version`，部署时同步更新本文及 Compose/Toolkit 的镜像标签。
- 当前 `TEXLIVE_YEAR=2026`；更换基础镜像时检查其 TeX Live 年份，必要时同步更新 Dockerfile 和工作流。
- `TEXLIVE_BIN_SUBDIR` 默认根据 `TARGETARCH` 自动选择 `x86_64-linux` 或 `aarch64-linux`，并验证 biber 存在。不要在多架构构建中固定为某一种架构。

### 编译镜像

在 `Actions` 中运行 `Build and Push Docker Image`，填写 `image_version` 后再点击 `Run workflow`。输入值会赋给工作流环境变量 `IMAGE_VERSION`。工作流使用 QEMU 和 Buildx，一次构建并推送 `linux/amd64,linux/arm64` 的 manifest，发布为 `szcq/sharelatex:${IMAGE_VERSION}`。不额外发布 `latest` 或 `-amd64` / `-arm64` 标签，也不再运行独立的单架构发布或 manifest 合并任务。

本地需要构建并推送时（需先 `docker login`，并具备支持双架构的 Buildx builder/QEMU）：
```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg BASE_IMAGE=ghcr.io/ayaka-notes/overleaf-pro:6.3.2 \
  --build-arg TEXLIVE_YEAR=2026 \
  -t szcq/sharelatex:6.3.2 --push .
```

保留 `fonts/` 中的自定义字体及安装脚本。新增字体放入 `fonts/` 后重新构建镜像，或按前述脚本导入已运行的容器。
