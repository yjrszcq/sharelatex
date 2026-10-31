# 带自定义中文字体的 TeX Live 沙盒镜像

用于 Ayakaleaf Pro 的沙盒编译，基于 `ghcr.io/ayaka-notes/texlive-full:2026.1`，保留官方完整 TeX Live，只添加 `fonts/` 中的字体并刷新缓存。

本仓库有两种编译方式：

- 主容器内编译：使用仓库根目录的主镜像，`SIBLING_CONTAINERS_ENABLED=false`。可通过根目录的 `install-sharelatex-fonts.sh` 给运行中的主容器注入字体。
- 沙盒编译：`SIBLING_CONTAINERS_ENABLED=true`，使用独立的 TeX Live 编译镜像。给主容器注入字体不会自动影响沙盒，需使用本目录构建带字体的编译镜像。

官方参考：[TeX Live 沙盒镜像与配置](https://github.com/ayaka-notes/texlive-full)、[Toolkit 沙盒配置](https://github.com/ayaka-notes/toolkit/blob/master/doc/overleaf-rc.md)。

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
├── README.md
└── fonts/
    └── wps-office/
        └── 字体文件.ttf
```

`fonts/` 初始仅有占位文件；请自行放入所需字体。本目录不会自动复制仓库根目录的 `fonts/` 或主容器中已导入的字体。

## 构建镜像

在本目录执行：
```bash
docker build -t texlive-custom:2026.1 .
```

默认构建当前 Docker builder 对应架构。官方基础镜像支持 amd64 和 arm64；如需明确指定部署架构，可添加 `--platform linux/amd64` 或 `--platform linux/arm64`。

TeX Live 镜像版本 `2026.1` 与 Ayakaleaf 主镜像版本（如 `6.3.2`）分别管理。

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
