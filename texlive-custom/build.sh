#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VERSION=""
BASE_IMAGE=""
IMAGE_NAME=""

usage() {
    cat <<EOF
用法：
  $0 -v 版本号 [-o 输出镜像名]
  $0 -b 完整基础镜像名 [-o 输出镜像名]

选项：
  -v, --version       官方 TeX Live 沙盒镜像版本号
  -b, --base-image    完整基础镜像名，可使用已导入本地的镜像
  -o, --output-image  输出镜像名，默认 texlive-custom:<基础镜像tag>
  -h, --help          显示帮助

-v 与 -b 不能同时使用。不指定两者时，交互输入官方镜像版本号。
EOF
}

require_value() {
    if [ "$#" -lt 2 ] || [[ -z "$2" || "$2" == -* ]]; then
        echo "错误：$1 缺少参数值" >&2
        exit 1
    fi
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -v|--version)
            require_value "$@"
            VERSION="$2"
            shift 2
            ;;
        -b|--base-image)
            require_value "$@"
            BASE_IMAGE="$2"
            shift 2
            ;;
        -o|--output-image)
            require_value "$@"
            IMAGE_NAME="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "错误：未知参数 $1，请使用 -h 查看帮助" >&2
            exit 1
            ;;
    esac
done

if [[ -n "$VERSION" && -n "$BASE_IMAGE" ]]; then
    echo "错误：-v/--version 与 -b/--base-image 不能同时使用" >&2
    exit 1
fi

if [[ -z "$VERSION" && -z "$BASE_IMAGE" ]]; then
    read -r -p "请输入官方 TeX Live 沙盒镜像版本号：" VERSION
fi

if [[ -z "$BASE_IMAGE" ]]; then
    if [[ ! "$VERSION" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]{0,127}$ ]]; then
        echo "错误：请输入有效的镜像版本 tag" >&2
        exit 1
    fi
    BASE_IMAGE="ghcr.io/ayaka-notes/texlive-full:$VERSION"
else
    if [[ "$BASE_IMAGE" == -* || "$BASE_IMAGE" == *[[:space:]]* ]]; then
        echo "错误：请输入有效的基础镜像名" >&2
        exit 1
    fi
    IMAGE_REF="${BASE_IMAGE%@*}"
    IMAGE_COMPONENT="${IMAGE_REF##*/}"
    if [[ "$IMAGE_COMPONENT" == *:* ]]; then
        VERSION="${IMAGE_COMPONENT##*:}"
    else
        VERSION=latest
    fi
fi

IMAGE_NAME="${IMAGE_NAME:-texlive-custom:$VERSION}"
if [[ "$IMAGE_NAME" == -* || "$IMAGE_NAME" == *[[:space:]]* || "$IMAGE_NAME" == *@* ]]; then
    echo "错误：请输入有效的输出镜像名（名称或名称:tag）" >&2
    exit 1
fi

docker info >/dev/null

if ! docker image inspect "$BASE_IMAGE" >/dev/null 2>&1; then
    echo "本地没有基础镜像，开始拉取：$BASE_IMAGE"
    docker pull "$BASE_IMAGE"
fi

docker build --load \
    --build-arg "BASE_IMAGE=$BASE_IMAGE" \
    -t "$IMAGE_NAME" \
    "$SCRIPT_DIR"

printf '\n构建完成，镜像名：%s\n' "$IMAGE_NAME"
