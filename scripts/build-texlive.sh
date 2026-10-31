#!/usr/bin/env bash
set -euo pipefail

msg() {
    if [ "${SCRIPT_LANG:-zh}" = en ]; then printf '%s\n' "$1"; else printf '%s\n' "$2"; fi
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
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
  -d, --font-dir      字体目录，复制其中全部内容
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

if [[ "$FONT_MODE" == -z || "$FONT_MODE" == --zip ]]; then
    if ! command -v unzip >/dev/null 2>&1; then
        msg "Error: install unzip on this host first" "错误：请先在运行脚本的主机上安装 unzip" >&2
        exit 1
    fi
fi

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/texlive-fonts.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$TEMP_DIR/fonts"
cp "$REPO_DIR/texlive-custom/Dockerfile" "$REPO_DIR/texlive-custom/build.sh" "$TEMP_DIR/"

case "$FONT_MODE" in
    -z|--zip) unzip -o "$FONT_SOURCE" -d "$TEMP_DIR/fonts/" ;;
    -d|--font-dir) cp -R "$FONT_SOURCE/." "$TEMP_DIR/fonts/" ;;
    -f|--font-file) cp "$FONT_SOURCE" "$TEMP_DIR/fonts/" ;;
esac

if [ -n "$VERSION" ]; then
    set -- -v "$VERSION"
elif [ -n "$BASE_IMAGE" ]; then
    set -- -b "$BASE_IMAGE"
else
    set --
fi
if [ -n "$IMAGE_NAME" ]; then
    set -- "$@" -o "$IMAGE_NAME"
fi

bash "$TEMP_DIR/build.sh" "$@"
