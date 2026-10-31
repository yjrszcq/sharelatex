# 带自定义中文字体的 TeX Live 沙盒镜像

用于 Ayakaleaf Pro 的沙盒编译，基于 `ghcr.io/ayaka-notes/texlive-full:2026.1`，保留官方完整 TeX Live，只添加 `fonts/` 中的字体并刷新缓存。

本仓库有两种编译方式：

- 主容器内编译：使用仓库根目录的主镜像，`SIBLING_CONTAINERS_ENABLED=false`。可通过 `scripts/install-sharelatex-fonts.sh` 给运行中的主容器注入字体。
- 沙盒编译：`SIBLING_CONTAINERS_ENABLED=true`，使用独立的 TeX Live 编译镜像。给主容器注入字体不会自动影响沙盒，需使用本目录构建带字体的编译镜像。

官方参考：[TeX Live 沙盒镜像与配置](https://github.com/ayaka-notes/texlive-full)、[Toolkit 沙盒配置](https://github.com/ayaka-notes/toolkit/blob/master/doc/overleaf-rc.md)。

根目录的 [fonts.sh](../fonts.sh) 提供英语（默认）/中文交互菜单，可选择主容器或沙盒并填写字体来源；远程运行命令见 [主 README](../README.md#交互式字体安装与沙盒构建)。

## 一步构建

可直接使用仓库 `scripts/` 下的 [build-texlive.sh](../scripts/build-texlive.sh)，将现有字体 zip、字体目录或单个字体文件作为输入，无需手动准备本目录的 `fonts/`：
```bash
# 在仓库根目录执行；不传 -v 则交互输入官方镜像版本号
./scripts/build-texlive.sh -z /实际路径/wps-office-fonts.zip
./scripts/build-texlive.sh -v 2026.1 -d /实际路径/Fonts
./scripts/build-texlive.sh -b my-texlive:2026.1 -f /实际路径/simsun.ttc -o szcq/texlive-custom:2026.1
```

选项同时支持长名称：`--version`、`--base-image`、`--output-image`、`--zip`、`--font-dir`、`--font-file`；`-h/--help` 查看帮助。三种字体输入必须三选一，版本号与完整基础镜像名互斥。

脚本在临时目录中准备字体，复用本目录的 Dockerfile 和 `build.sh` 完成镜像检查、必要时拉取和构建。成功后打印完整镜像名；失败时中止，退出时自动清理临时文件。原字体及仓库目录保持原样。zip 方式依赖运行主机的 `unzip`，脚本不自动安装主机软件，也不自动推送镜像。

完成后直接进入下方“配置 Toolkit”。如果需要手动管理本目录的字体和构建过程，也可以按下面步骤操作。

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

## 配置 Toolkit

以下配置适用于 Ayaka Toolkit 或 Overleaf 官方 Toolkit。

修改 `config/overleaf.rc` 中对应配置项：
```ini
SERVER_PRO=true
SIBLING_CONTAINERS_ENABLED=true
SIBLING_CONTAINERS_PULL=false
```

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
