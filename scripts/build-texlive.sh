#!/usr/bin/env bash
set -euo pipefail

msg() {
    if [ "${SCRIPT_LANG:-zh}" = en ]; then printf '%s\n' "$1"; else printf '%s\n' "$2"; fi
}

prepare_fonts() {
    local mode="$1" source="$2" destination="$3"
    local archive_list archive extract_dir

    mkdir -p "$destination"
    case "$mode" in
        -d|--font-dir)
            if [ ! -d "$source" ]; then
                msg "Error: font directory not found: $source" "错误：找不到字体目录 $source" >&2
                return 1
            fi
            cp -R "$source/." "$destination/"
            ;;
        -z|--zip|-f|--font-file)
            if [ ! -f "$source" ]; then
                msg "Error: font file not found: $source" "错误：找不到字体文件 $source" >&2
                return 1
            fi
            cp "$source" "$destination/"
            ;;
    esac

    archive_list="$(mktemp "$destination/../.font-zips.XXXXXX")"
    while :; do
        find "$destination" -type f -iname '*.zip' -print0 > "$archive_list"
        [ -s "$archive_list" ] || break
        if ! command -v unzip >/dev/null 2>&1; then
            msg "Error: install unzip on this host first" "错误：请先在运行脚本的主机上安装 unzip" >&2
            return 1
        fi
        while IFS= read -r -d '' archive; do
            # Each ZIP has its own directory so equal font names cannot collide.
            extract_dir="$archive.unpacked"
            mkdir -p "$extract_dir"
            unzip -o "$archive" -d "$extract_dir" || return $?
            # Delete only the staged copy, and only after extraction succeeds.
            rm -f "$archive"
        done < "$archive_list"
    done
    rm -f "$archive_list"
}

VERSION=""
BASE_IMAGE=""
IMAGE_NAME=""
FONT_MODE=""
FONT_SOURCE=""

usage() {
    cat <<EOF
用法：
  $0 -v 版本号 -z 字体.zip [-o 输出镜像名]
  $0 -b 基础镜像名 -d 字体目录 [-o 输出镜像名]
  $0 -v 版本号 -f 字体文件 [-o 输出镜像名]

选项：
  -v, --version       官方 TeX Live 沙盒镜像版本号
  -b, --base-image    完整基础镜像名，可使用已导入本地的镜像
  -o, --output-image  输出镜像名，默认 texlive-custom:<基础镜像tag>
  -z, --zip           字体 zip 文件（本机需安装 unzip）
  -d, --font-dir      字体目录，递归解压 ZIP 并整理字体
  -f, --font-file     单个字体文件
  -h, --help          显示帮助

-v 与 -b 不能同时使用。不指定两者时，交互输入官方镜像版本号。
-z、-d、-f 必须且只能指定一种。成功后打印镜像名，临时文件自动清理。
EOF
}

require_value() {
    if [ "$#" -lt 2 ] || [[ -z "$2" || "$2" == -* ]]; then
        msg "Error: missing value for $1" "错误：$1 缺少参数值" >&2
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
        -z|--zip|-d|--font-dir|-f|--font-file)
            require_value "$@"
            if [ -n "$FONT_MODE" ]; then
                msg "Error: choose exactly one of -z, -d and -f" "错误：-z、-d、-f 必须三选一" >&2
                exit 1
            fi
            FONT_MODE="$1"
            FONT_SOURCE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            msg "Error: unknown option $1; use -h for help" "错误：未知参数 $1，请使用 -h 查看帮助" >&2
            exit 1
            ;;
    esac
done

if [[ -n "$VERSION" && -n "$BASE_IMAGE" ]]; then
    msg "Error: --version and --base-image cannot be used together" "错误：-v/--version 与 -b/--base-image 不能同时使用" >&2
    exit 1
fi

case "$FONT_MODE" in
    -d|--font-dir)
        if [ ! -d "$FONT_SOURCE" ]; then
            msg "Error: font directory not found: $FONT_SOURCE" "错误：找不到字体目录 $FONT_SOURCE" >&2
            exit 1
        fi
        ;;
    -z|--zip|-f|--font-file)
        if [ ! -f "$FONT_SOURCE" ]; then
            msg "Error: font file not found: $FONT_SOURCE" "错误：找不到字体文件 $FONT_SOURCE" >&2
            exit 1
        fi
        ;;
    *)
        msg "Error: specify one font source using -z, -d or -f" "错误：必须指定 -z、-d、-f 其中一种字体来源" >&2
        exit 1
        ;;
esac

if [[ -z "$VERSION" && -z "$BASE_IMAGE" ]]; then
    if [ "${SCRIPT_LANG:-zh}" = en ]; then
        read -r -p "Official TeX Live sandbox image version tag: " VERSION
    else
        read -r -p "请输入官方 TeX Live 沙盒镜像版本号：" VERSION
    fi
fi

if [[ -z "$BASE_IMAGE" ]]; then
    if [[ ! "$VERSION" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]{0,127}$ ]]; then
        msg "Error: enter a valid image version tag" "错误：请输入有效的镜像版本 tag" >&2
        exit 1
    fi
    BASE_IMAGE="ghcr.io/ayaka-notes/texlive-full:$VERSION"
else
    if [[ "$BASE_IMAGE" == -* || "$BASE_IMAGE" == *[[:space:]]* ]]; then
        msg "Error: enter a valid base image name" "错误：请输入有效的基础镜像名" >&2
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
    msg "Error: enter a valid output image name (name or name:tag)" "错误：请输入有效的输出镜像名（名称或名称:tag）" >&2
    exit 1
fi

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/texlive-fonts.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$TEMP_DIR/fonts"
cat > "$TEMP_DIR/Dockerfile" <<'DOCKERFILE'
ARG BASE_IMAGE=ghcr.io/ayaka-notes/texlive-full:2026.1
FROM ${BASE_IMAGE}

USER root
COPY fonts/ /usr/share/fonts/addfonts/
RUN chmod -R a+rX /usr/share/fonts/addfonts && fc-cache -fv
DOCKERFILE

prepare_fonts "$FONT_MODE" "$FONT_SOURCE" "$TEMP_DIR/fonts"

docker info >/dev/null

if ! docker image inspect "$BASE_IMAGE" >/dev/null 2>&1; then
    msg "Base image not found locally; pulling: $BASE_IMAGE" "本地没有基础镜像，开始拉取：$BASE_IMAGE"
    docker pull "$BASE_IMAGE"
fi

docker build --load \
    --build-arg "BASE_IMAGE=$BASE_IMAGE" \
    -t "$IMAGE_NAME" \
    "$TEMP_DIR"

msg "Build complete. Image: $IMAGE_NAME" "构建完成，镜像名：$IMAGE_NAME"
