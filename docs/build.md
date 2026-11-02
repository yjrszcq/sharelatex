# 自己制作镜像

## 配置 GitHub Actions

- 保留工作流 `.github/workflows/docker.yaml`，通过 `workflow_dispatch` 手动触发。
- 在 `Actions → Build and Push Docker Image → Run workflow` 中填写必填输入 `image_version`。工作流直接使用输入值作为官方基础镜像版本和发布标签，无需配置仓库变量 `IMAGE_VERSION`；使用 `X.Y.Z` 格式，并确认该官方标签支持两种架构。
- 在 `Secrets` 设置 `DOCKER_TOKEN`，值为可向 `szcq/sharelatex` 推送的 Docker Hub 访问令牌。
- 镜像账号和名称继续由工作流中的 `IMAGE_OWNER: szcq`、`IMAGE_NAME: sharelatex` 决定；发布到自己的账号时修改这两项。

## 更新版本信息

- 基础镜像地址固定为 `ghcr.io/ayaka-notes/overleaf-pro`，仅通过 `IMAGE_VERSION` 指定 tag。Dockerfile 的 `ARG IMAGE_VERSION=6.3.2` 是本地构建的默认版本，可通过 `--build-arg IMAGE_VERSION=<版本号>` 覆盖。
- 运行工作流时填写对应的 `image_version`，部署时同步更新本文及 Compose/Toolkit 的镜像标签。
- Git Bridge 参照[官方 Dockerfile](https://github.com/ayaka-notes/ayakaleaf-pro/blob/pro-v6.3.2/services/git-bridge/Dockerfile)在构建阶段自行编译：`IMAGE_VERSION` 同时选择官方源码标签 `pro-v${IMAGE_VERSION}`，通过 `make package` 生成 JAR；`envsubst` 也使用 Go 从源码编译。不会从官方 Git Bridge 镜像提取二进制。
- 构建时需能访问 GitHub、Go 模块代理和 Maven Central；版本对应的官方源码标签必须存在。Maven、Go 和源码仅保留在构建阶段，最终镜像只包含编译产物、对应配置和运行依赖。
- 当前 `TEXLIVE_YEAR=2026`；更换基础镜像时检查其 TeX Live 年份，必要时同步更新 Dockerfile 和工作流。
- `TEXLIVE_BIN_SUBDIR` 默认使用 amd64 的 `x86_64-linux`，仅在 `TARGETARCH=arm64` 时改为 `aarch64-linux`。

## 编译镜像

在 `Actions` 中运行 `Build and Push Docker Image`，填写 `image_version` 后再点击 `Run workflow`。输入值会赋给工作流环境变量 `IMAGE_VERSION`。工作流使用 QEMU 和 Buildx，一次构建并推送 `linux/amd64,linux/arm64` 的 manifest，发布为 `szcq/sharelatex:${IMAGE_VERSION}`。不额外发布 `latest` 或 `-amd64` / `-arm64` 标签，也不再运行独立的单架构发布或 manifest 合并任务。

本地需要构建并推送时（需先 `docker login`，并具备支持双架构的 Buildx builder/QEMU）：
```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg IMAGE_VERSION=6.3.2 \
  --build-arg TEXLIVE_YEAR=2026 \
  -t szcq/sharelatex:6.3.2 --push .
```

保留 `fonts/` 中的自定义字体及安装脚本。新增字体放入 `fonts/` 后重新构建镜像，或按前述脚本导入已运行的容器。
