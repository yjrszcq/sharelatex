# Ayakaleaf Pro 自定义镜像

基于官方 `ghcr.io/ayaka-notes/overleaf-pro`，发布为 `szcq/sharelatex`，支持 amd64 和 arm64。

包含完整 TeX Live 2026、中文及常用字体、自定义 `fonts/`，以及可选启用的内置 Git Bridge。

## 使用

按 [部署说明](docs/deployment.md) 配置 `.env` 后，在仓库根目录启动：
```bash
docker compose pull
docker compose up -d
```

也支持 Ayaka Toolkit 和 Overleaf 官方 Toolkit。已有实例请先查看部署文档中的升级要求。

Git Bridge 通过 `GIT_BRIDGE_ENABLED` 统一开关，启用后默认使用内置服务，也可指定外部主机；详见 [Git Bridge 配置](docs/git-bridge.md)。

## 字体

在 Docker 主机上运行交互式工具，选择英语（默认）或中文，再选择主容器或沙盒：
```bash
bash fonts.sh
```

也可远程运行：
```bash
curl -fsSL https://raw.githubusercontent.com/yjrszcq/sharelatex/master/fonts.sh | bash
```

支持单个字体、ZIP 和混合目录；只清理临时副本，保留宿主机原文件。两个功能脚本可分别下载运行，详见 [字体工具说明](docs/fonts.md)。

## 详细文档

| 文档 | 内容 |
| --- | --- |
| [部署与升级](docs/deployment.md) | Compose、两种 Toolkit、配置及数据库升级 |
| [Git Bridge](docs/git-bridge.md) | 内置/外部模式、总开关、持久化及 Toolkit 配置 |
| [字体工具](docs/fonts.md) | 交互入口、独立脚本、ZIP/目录/文件导入 |
| [沙盒镜像](docs/sandbox.md) | 自定义编译镜像、字体、镜像传输及 Toolkit 配置 |
| [构建与发布](docs/build.md) | GitHub Actions、版本输入、双架构及本地构建 |

官方参考：[Ayakaleaf Pro](https://github.com/ayaka-notes/ayakaleaf-pro)、[Ayaka Toolkit](https://github.com/ayaka-notes/toolkit)。
