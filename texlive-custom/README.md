# 自定义 TeX Live 沙盒镜像

本目录提供 Dockerfile、`build.sh` 和空的 `fonts/` 目录，供手动准备字体并构建编译镜像。

- [沙盒镜像完整说明](../docs/sandbox.md)：构建参数、镜像传输和 Toolkit 配置。
- [字体工具说明](../docs/fonts.md)：通过根目录的 `fonts.sh` 交互操作，或单独使用 `scripts/build-texlive.sh`，支持 ZIP、目录和字体文件。

主容器内编译的字体导入与沙盒镜像分别处理；给主容器加字体不会自动影响沙盒。
