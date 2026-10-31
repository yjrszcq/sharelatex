#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [ "$#" -gt 1 ]; then
    echo "用法：$0 [版本号]" >&2
    exit 1
fi

VERSION="${1:-}"
if [ "$#" -eq 0 ]; then
    read -r -p "请输入官方 TeX Live 沙盒镜像版本号：" VERSION
fi

if [[ ! "$VERSION" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]{0,127}$ ]]; then
    echo "错误：请输入有效的镜像版本 tag" >&2
    exit 1
fi

BASE_IMAGE="ghcr.io/ayaka-notes/texlive-full:$VERSION"
IMAGE_NAME="texlive-custom:$VERSION"

docker info >/dev/null

if ! docker image inspect "$BASE_IMAGE" >/dev/null 2>&1; then
    echo "本地没有官方沙盒镜像，开始拉取：$BASE_IMAGE"
    docker pull "$BASE_IMAGE"
fi

docker build --load \
    --build-arg "TEXLIVE_VERSION=$VERSION" \
    -t "$IMAGE_NAME" \
    "$SCRIPT_DIR"

printf '\n构建完成，镜像名：%s\n' "$IMAGE_NAME"
