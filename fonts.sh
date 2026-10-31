#!/usr/bin/env bash
set -euo pipefail

if [ -t 0 ]; then
    exec 3<&0
elif { true </dev/tty; } 2>/dev/null; then
    exec 3</dev/tty
else
    echo "An interactive terminal is required. / 请在交互式终端中运行。" >&2
    exit 1
fi

SCRIPT_LANG=en
say() {
    if [ "$SCRIPT_LANG" = zh ]; then printf '%s\n' "$2"; else printf '%s\n' "$1"; fi
}
ask() {
    if [ "$SCRIPT_LANG" = zh ]; then printf '%s ' "$2"; else printf '%s ' "$1"; fi
    IFS= read -r -u 3 REPLY || exit 1
    REPLY="${REPLY:-${3:-}}"
}
fail() { say "$1" "$2" >&2; exit 1; }

printf 'Language / 语言:\n  1) English (default)\n  2) 中文\n'
ask 'Select [1]:' '请选择 [1]：' 1
case "$REPLY" in
    1) SCRIPT_LANG=en ;;
    2) SCRIPT_LANG=zh ;;
    *) fail 'Invalid language selection.' '语言选择无效。' ;;
esac
export SCRIPT_LANG

say 'Add fonts to: 1) Main container  2) Sandbox image' '字体目标：1) 主容器  2) 沙盒编译镜像'
ask 'Select 1 or 2:' '请选择 1 或 2：'
TARGET="$REPLY"
case "$TARGET" in
    1)
        ask 'Running container name [sharelatex]:' '运行中的容器名称 [sharelatex]：' sharelatex
        CONTAINER="$REPLY"
        ;;
    2)
        say 'Base image: 1) Official version tag  2) Full image name (including locally imported images)' '基础镜像：1) 官方版本号  2) 完整镜像名（支持本地已导入镜像）'
        ask 'Select [1]:' '请选择 [1]：' 1
        case "$REPLY" in
            1) SOURCE_OPTION=-v; ask 'Official TeX Live version tag:' '官方 TeX Live 版本号：' ;;
            2) SOURCE_OPTION=-b; ask 'Full base image name:' '完整基础镜像名：' ;;
            *) fail 'Invalid base image selection.' '基础镜像选择无效。' ;;
        esac
        SOURCE="$REPLY"
        [ -n "$SOURCE" ] || fail 'A version or base image name is required.' '必须填写版本号或基础镜像名。'
        ask 'Output image name (Enter for texlive-custom:<base tag>):' '输出镜像名（回车使用 texlive-custom:<基础镜像tag>）：'
        OUTPUT_IMAGE="$REPLY"
        ;;
    *) fail 'Invalid target selection.' '字体目标选择无效。' ;;
esac

say 'Font source: 1) ZIP archive  2) Directory  3) Single font file' '字体来源：1) ZIP 压缩包  2) 字体目录  3) 单个字体文件'
ask 'Select 1, 2 or 3:' '请选择 1、2 或 3：'
case "$REPLY" in
    1) FONT_OPTION=-z ;;
    2) FONT_OPTION=-d ;;
    3) FONT_OPTION=-f ;;
    *) fail 'Invalid font source selection.' '字体来源选择无效。' ;;
esac
ask 'Font path on this host (spaces supported; do not add quotes):' '本机字体路径（支持空格，无需加引号）：'
FONT_PATH="$REPLY"
case "$FONT_PATH" in
    '~/'*) FONT_PATH="$HOME/${FONT_PATH:2}" ;;
esac
if [ "$FONT_OPTION" = -d ]; then
    [ -d "$FONT_PATH" ] || fail "Directory not found: $FONT_PATH" "找不到目录：$FONT_PATH"
else
    [ -f "$FONT_PATH" ] || fail "File not found: $FONT_PATH" "找不到文件：$FONT_PATH"
fi

REPO_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    LOCAL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$LOCAL_DIR/scripts/build-texlive.sh" ] && [ -f "$LOCAL_DIR/scripts/install-sharelatex-fonts.sh" ]; then
        REPO_DIR="$LOCAL_DIR"
    fi
fi

if [ -z "$REPO_DIR" ]; then
    REPO_DIR="$(mktemp -d "${TMPDIR:-/tmp}/sharelatex-fonts.XXXXXX")"
    trap 'rm -rf "$REPO_DIR"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    DOWNLOAD_BASE=https://raw.githubusercontent.com/yjrszcq/sharelatex/master
    fetch() {
        mkdir -p "$(dirname -- "$REPO_DIR/$1")"
        curl -fsSL "$DOWNLOAD_BASE/$1" -o "$REPO_DIR/$1"
    }
    say 'Fetching helper files into a temporary directory...' '正在临时获取配套文件……'
    if [ "$TARGET" = 1 ]; then
        fetch scripts/install-sharelatex-fonts.sh
    else
        fetch scripts/build-texlive.sh
        fetch texlive-custom/build.sh
        fetch texlive-custom/Dockerfile
    fi
fi

if [ "$TARGET" = 1 ]; then
    bash "$REPO_DIR/scripts/install-sharelatex-fonts.sh" -c "$CONTAINER" "$FONT_OPTION" "$FONT_PATH"
    say 'Fonts installed in the main container. This does not update sandbox images.' '字体已安装到主容器；沙盒镜像不会随之更新。'
else
    set -- "$SOURCE_OPTION" "$SOURCE" "$FONT_OPTION" "$FONT_PATH"
    if [ -n "$OUTPUT_IMAGE" ]; then set -- "$@" -o "$OUTPUT_IMAGE"; fi
    bash "$REPO_DIR/scripts/build-texlive.sh" "$@"
    say 'Use the printed image name in your Toolkit sandbox configuration. The image was loaded locally; it was not pushed.' '请将上面打印的镜像名填入 Toolkit 沙盒配置。镜像已加载到本地，未自动推送。'
fi
