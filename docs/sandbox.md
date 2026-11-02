# 带自定义中文字体的 TeX Live 沙盒镜像

用于 Ayakaleaf Pro 的沙盒编译，基于 `ghcr.io/ayaka-notes/texlive-full:2026.1`，保留官方完整 TeX Live，只添加 `fonts/` 中的字体并刷新缓存。

本仓库有两种编译方式：

- 主容器内编译：使用仓库根目录的主镜像，`SIBLING_CONTAINERS_ENABLED=false`。可通过 `scripts/install-sharelatex-fonts.sh` 给运行中的主容器注入字体。
- 沙盒编译：`SIBLING_CONTAINERS_ENABLED=true`，使用独立的 TeX Live 编译镜像。给主容器注入字体不会自动影响沙盒，需使用本目录构建带字体的编译镜像。

官方参考：[TeX Live 沙盒镜像与配置](https://github.com/ayaka-notes/texlive-full)、[Toolkit 沙盒配置](https://github.com/ayaka-notes/toolkit/blob/master/doc/overleaf-rc.md)。

根目录的 [fonts.sh](../fonts.sh) 提供英语（默认）/中文交互菜单，可选择主容器或沙盒并填写字体来源；远程运行命令见 [字体工具说明](fonts.md#交互式字体安装与沙盒构建)。

## 一步构建

可直接使用仓库 `scripts/` 下的 [build-texlive.sh](../scripts/build-texlive.sh)，将现有字体 zip、混合目录（多个 ZIP、字体及子文件夹）或单个字体文件作为输入，无需手动准备本目录的 `fonts/`：
```bash
# 在仓库根目录执行；不传 -v 则交互输入官方镜像版本号
./scripts/build-texlive.sh -z /实际路径/wps-office-fonts.zip
./scripts/build-texlive.sh -v 2026.1 -d /实际路径/Fonts
./scripts/build-texlive.sh -b my-texlive:2026.1 -f /实际路径/simsun.ttc -o szcq/texlive-custom:2026.1
```

选项同时支持长名称：`--version`、`--base-image`、`--output-image`、`--zip`、`--font-dir`、`--font-file`；`-h/--help` 查看帮助。三种字体输入必须三选一，版本号与完整基础镜像名互斥。

脚本内置字体整理、Dockerfile 和构建逻辑，可单独下载运行，无需本目录的其他文件；在临时目录中准备字体，完成镜像检查、必要时拉取和构建。成功后打印完整镜像名；失败时中止，退出时自动清理临时文件。原字体及仓库目录保持原样。输入包含 ZIP 时依赖运行主机的 `unzip`，脚本不自动安装主机软件，也不自动推送镜像。

目录模式会递归整理子文件夹、解压其中的全部 ZIP，也会继续处理解压出来的嵌套 ZIP。每个 ZIP 单独解压到以 `.zip.unpacked`（或 `.ZIP.unpacked`）结尾的目录，保留同名字体，避免互相覆盖。成功解压后只删除临时副本中的 ZIP；原目录、原字体和原压缩包均保持不变，生成的镜像中不包含这些 ZIP。

例如可以直接使用：
```bash
./scripts/build-texlive.sh -v 2026.1 -d /mydata/other/font
```

完成后按部署方式选择下方“配置 Docker Compose”或“配置 Toolkit”。如果需要手动管理本目录的字体和构建过程，也可以按下面步骤操作。

## 准备字体

进入仓库中的本目录：
```bash
cd texlive-custom
```

将 `.ttf`、`.ttc`、`.otf` 等字体放到 `fonts/`，支持子目录。字体 zip 需先解压，例如：
```bash
unzip /实际路径/wps-office-fonts.zip -d fonts/
```

目录结构：
```text
texlive-custom/
├── Dockerfile
├── build.sh
├── README.md
└── fonts/
    └── wps-office/
        └── 字体文件.ttf
```

`fonts/` 初始仅有占位文件；请自行放入所需字体。本目录不会自动复制仓库根目录的 `fonts/` 或主容器中已导入的字体。

## 构建镜像

准备好 `fonts/` 后运行：
```bash
./build.sh
```

按提示输入官方 TeX Live 沙盒镜像的版本号，不设默认输入值。也可以通过 `-v/--version` 指定：
```bash
./build.sh -v 2026.1
```

通过 `-b/--base-image` 指定完整基础镜像名，`-o/--output-image` 指定完整输出镜像名：
```bash
./build.sh -b ghcr.io/ayaka-notes/texlive-full:2026.1 -o szcq/texlive-custom:2026.1
```

基础镜像也可以是通过 `docker load` 导入的本地沙盒镜像：
```bash
docker load -i texlive-backup.tar
./build.sh --base-image my-texlive:2026.1 --output-image texlive-custom:2026.1
```

这里的 `my-texlive:2026.1` 应替换为 `docker load` 后实际显示的镜像名称。输入的基础镜像需兼容 Ayakaleaf 编译沙盒，带有 TeX Live、`tex` 用户及 `fc-cache`。

脚本会检查指定基础镜像是否已在本地；存在则直接使用，没有则先执行 `docker pull`，然后构建并加载输出镜像到本地。使用 `-v/--version` 时，基础镜像为 `ghcr.io/ayaka-notes/texlive-full:<版本号>`；使用 `-b/--base-image` 时，直接使用指定的镜像引用。两者不能同时使用，所有命令行参数均通过选项传入，不接受位置参数。

不指定输出镜像名时，默认生成 `texlive-custom:<基础镜像tag>`，基础镜像未带 tag 时使用 `texlive-custom:latest`。`-o/--output-image` 是输出镜像名，不是 `.tar` 文件路径；需要导出文件时使用下方的 `docker save`。脚本只构建并加载，不自动推送。成功结束后会打印完整输出镜像名；如果拉取或构建失败，脚本会中止。

运行 `./build.sh -h` 或 `./build.sh --help` 可查看全部选项。

脚本使用本目录作为构建上下文，可从其他目录调用。运行脚本的账号需能访问 Docker；构建默认采用当前 Docker builder 对应的平台。官方基础镜像支持 amd64 和 arm64，构建平台应与实际部署平台一致。

以下部署示例以输入 `2026.1` 为例，实际使用时请替换为脚本打印的镜像名。这里的 TeX Live 镜像版本与 Ayakaleaf 主镜像版本分别管理。

验证镜像能列出中文字体：
```bash
docker run --rm texlive-custom:2026.1 fc-list :lang=zh family
```

镜像必须存在于实际运行沙盒的 Docker 主机上。如果在 `lab.szcq.cc` 构建、在其他主机部署，可通过镜像仓库传输，或在构建主机导出：
```bash
docker save -o texlive-custom-2026.1.tar texlive-custom:2026.1
```

把文件传到部署主机后导入：
```bash
docker load -i texlive-custom-2026.1.tar
```

## 配置 Docker Compose

在主容器 `services.ayakaleaf` 中追加下面的配置，保留原有数据库、Redis、密钥及其他环境变量。

### 数据路径和 Docker socket

沙盒由宿主机 Docker 启动，主容器需要能访问该 Docker 的 socket。在主容器已有的 `volumes` 中追加：
```yaml
volumes:
  # 保留现有数据卷；本节环境变量示例假设数据映射为：
  # - ${PWD}/data/overleaf:/var/lib/overleaf
  - /var/run/docker.sock:/var/run/docker.sock
```

`${PWD}` 是执行 Compose 时宿主机的当前目录，不是容器内目录。本节假设主容器的数据映射路径为 `${PWD}/data/overleaf`；因此下面的编译和输出路径分别对应其 `data/compiles` 和 `data/output`。

如果实际数据卷为 `${OVERLEAF_DATA_PATH}/overleaf:/var/lib/overleaf`，请按该目录在宿主机上的实际绝对路径填写下面两项 `SANDBOXED_COMPILES_HOST_DIR_*`，不要为套用示例而改动原有数据卷。使用 `${PWD}` 示例时，应在仓库根目录运行 Compose；也可以直接填写实际绝对路径。

若使用 Rootless Docker，将 socket 挂载的左侧换成实际 socket 路径，右侧仍为 `/var/run/docker.sock`。

### 主容器环境变量

```yaml
environment:
  # -------------------------
  # Sandbox Compile
  # -------------------------
  SANDBOXED_COMPILES: "true"
  DOCKER_RUNNER: "true"
  SANDBOXED_COMPILES_SIBLING_CONTAINERS: "true"

  # 此处的 ${PWD} 是宿主机的当前目录，不是容器内目录
  # ${PWD}/data/overleaf/ 应与 ayakaleaf 的实际数据映射路径一致
  SANDBOXED_COMPILES_HOST_DIR_COMPILES: "${PWD}/data/overleaf/data/compiles"
  SANDBOXED_COMPILES_HOST_DIR_OUTPUT: "${PWD}/data/overleaf/data/output"

  # 以下官方镜像仅用于未添加自定义字体的情况。
  # 使用字体构建脚本后，必须换成脚本打印的输出镜像名，见下节。
  # 首次启动前请在宿主机手动拉取实际使用的镜像：
  # docker pull ghcr.io/ayaka-notes/texlive-full:2026.1
  # docker pull ghcr.io/ayaka-notes/texlive-full:2025.1
  TEX_LIVE_DOCKER_IMAGE: ghcr.io/ayaka-notes/texlive-full:2026.1

  ALL_TEX_LIVE_DOCKER_IMAGES: >-
    ghcr.io/ayaka-notes/texlive-full:2026.1,
    ghcr.io/ayaka-notes/texlive-full:2025.1

  ALL_TEX_LIVE_DOCKER_IMAGE_NAMES: >-
    TeX Live 2026,
    TeX Live 2025
```

不需要定制字体、直接使用官方镜像时，在实际运行沙盒的 Docker 主机上首次启动前执行：
```bash
docker pull ghcr.io/ayaka-notes/texlive-full:2026.1
docker pull ghcr.io/ayaka-notes/texlive-full:2025.1
```

### 使用字体脚本构建后的镜像

`ghcr.io/ayaka-notes/texlive-full:<版本>` 是脚本的基础镜像。通过 `fonts.sh` 的沙盒模式或 `scripts/build-texlive.sh` 添加字体后，**实际编译必须使用脚本最后打印的输出镜像名**；继续使用官方基础镜像不会带上新增字体。

例如分别为 2026 和 2025 构建字体镜像：
```bash
./scripts/build-texlive.sh -v 2026.1 -d /mydata/other/font
./scripts/build-texlive.sh -v 2025.1 -d /mydata/other/font
```

若脚本打印的镜像名分别为 `texlive-custom:2026.1` 和 `texlive-custom:2025.1`，将上述三个镜像相关配置项替换为：
```yaml
environment:
  TEX_LIVE_DOCKER_IMAGE: texlive-custom:2026.1
  ALL_TEX_LIVE_DOCKER_IMAGES: >-
    texlive-custom:2026.1,
    texlive-custom:2025.1
  ALL_TEX_LIVE_DOCKER_IMAGE_NAMES: >-
    TeX Live 2026 中文字体,
    TeX Live 2025 中文字体
```

这段只替换镜像配置；前面的沙盒开关和宿主机路径配置仍需保留。如果只构建了一个字体镜像，就只在列表中填写该镜像和对应显示名称；镜像列表与名称列表的数量和顺序必须一致。使用 `-o/--output-image` 自定义过名称时，填写实际输出名称。

自定义镜像必须已在实际运行沙盒的 Docker 主机上；异机构建时按前述步骤通过 `docker save/load` 或镜像仓库传输。这里填写的是镜像名，不是导出的 `.tar` 文件路径；`.tar` 文件需先 `docker load`。

最后在仓库根目录更新主容器：
```bash
docker compose up -d
```

进入项目选择对应的 TeX Live 版本及 `XeLaTeX` 编译器，已有项目也需确认选中自定义字体镜像对应的版本。

## 配置 Toolkit

以下配置适用于 Ayaka Toolkit 或 Overleaf 官方 Toolkit。

修改 `config/overleaf.rc` 中对应配置项：
```ini
SERVER_PRO=true
SIBLING_CONTAINERS_ENABLED=true
SIBLING_CONTAINERS_PULL=false
```

字体构建脚本输出的镜像同样应填入下方 `TEX_LIVE_DOCKER_IMAGE` 和 `ALL_TEX_LIVE_DOCKER_IMAGES`，使用实际打印的名称替换示例值。

保留已配置好的 `DOCKER_SOCKET_PATH`。`SIBLING_CONTAINERS_PULL=false` 表示使用部署主机已有的本地镜像，避免 Toolkit 尝试从仓库拉取 `texlive-custom:2026.1`。

修改 `config/variables.env` 中对应配置项：
```ini
TEX_LIVE_DOCKER_IMAGE=texlive-custom:2026.1
ALL_TEX_LIVE_DOCKER_IMAGES=texlive-custom:2026.1
ALL_TEX_LIVE_DOCKER_IMAGE_NAMES="TeX Live 2026 中文字体"
```

在 Toolkit 根目录执行：
```bash
bin/up -d
```

在项目设置中选择对应的 TeX Live 版本，并选择 `XeLaTeX` 编译中文文档。已有项目也要确认选中的是这个自定义编译镜像对应的版本。

如果使用镜像仓库发布，将上面两项镜像地址改成实际发布的完整名称；希望 Toolkit 自动拉取时将 `SIBLING_CONTAINERS_PULL` 设为 `true`。

## 更新字体

更新 `fonts/` 后重新构建镜像，并将更新后的镜像部署到沙盒所在主机。下一次创建的沙盒会使用新镜像，无需向临时沙盒容器手动复制字体。若更换了镜像名称或 tag，还需同步修改 `config/variables.env` 并运行 `bin/up -d`。

仓库根目录的主镜像工作流不会自动构建或发布本目录的沙盒镜像。
