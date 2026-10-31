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

CONTAINER_NAME="sharelatex"
ZIP_FILE=""
FONT_DIR=""
FONT_FILE=""
TARGET_DIR="/usr/share/fonts/addfonts"

usage() {
    cat <<EOF
用法：
  $0 -z Fonts.zip [-c sharelatex]
  $0 -d Fonts     [-c sharelatex]
  $0 -f simsun.ttc [-c sharelatex]

参数：
  -c  容器名，默认 sharelatex
  -z  本地字体 zip 文件，例如 Fonts.zip
  -d  本地字体目录，支持多个 ZIP、字体和子目录混合
  -f  本地单个字体文件，例如 simsun.ttc / simhei.ttf / simkai.ttf
  -h  显示帮助

示例：
  $0 -z Fonts.zip
  $0 -d Fonts
  $0 -f simsun.ttc

  $0 -c overleaf -z Fonts.zip
  $0 -z Fonts.zip -c overleaf
  $0 -f simhei.ttf -c overleaf
EOF
}

while getopts ":c:z:d:f:h" opt; do
    case "$opt" in
        c)
            CONTAINER_NAME="$OPTARG"
            ;;
        z)
            ZIP_FILE="$OPTARG"
            ;;
        d)
            FONT_DIR="$OPTARG"
            ;;
        f)
            FONT_FILE="$OPTARG"
            ;;
        h)
            usage
            exit 0
            ;;
        :)
            msg "Error: missing value for -$OPTARG" "错误：-$OPTARG 缺少参数"
            usage
            exit 1
            ;;
        \?)
            msg "Error: unknown option -$OPTARG" "错误：未知参数 -$OPTARG"
            usage
            exit 1
            ;;
    esac
done

input_count=0
[ -n "$ZIP_FILE" ] && input_count=$((input_count + 1))
[ -n "$FONT_DIR" ] && input_count=$((input_count + 1))
[ -n "$FONT_FILE" ] && input_count=$((input_count + 1))

if [ "$input_count" -eq 0 ]; then
    msg "Error: specify one input using -z, -d or -f" "错误：必须指定 -z、-d、-f 其中一种输入"
    usage
    exit 1
fi

if [ "$input_count" -gt 1 ]; then
    msg "Error: choose exactly one of -z, -d and -f" "错误：-z、-d、-f 只能三选一"
    usage
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    msg "Error: docker command not found" "错误：未找到 docker 命令"
    exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    msg "Error: container is not running: $CONTAINER_NAME" "错误：容器 $CONTAINER_NAME 未运行"
    msg "Running containers:" "当前运行中的容器："
    docker ps --format '  {{.Names}}'
    exit 1
fi

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/container-fonts.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [ -n "$ZIP_FILE" ]; then
    prepare_fonts -z "$ZIP_FILE" "$TEMP_DIR/fonts"
elif [ -n "$FONT_DIR" ]; then
    prepare_fonts -d "$FONT_DIR" "$TEMP_DIR/fonts"
else
    prepare_fonts -f "$FONT_FILE" "$TEMP_DIR/fonts"
fi
chmod -R a+rX "$TEMP_DIR/fonts"

msg "Creating container font directory: $TARGET_DIR" "创建容器字体目录：$TARGET_DIR"
docker exec -u root "$CONTAINER_NAME" mkdir -p "$TARGET_DIR"
msg "Copying prepared fonts into container: $TARGET_DIR" "将整理后的字体复制到容器：$TARGET_DIR"
docker cp "$TEMP_DIR/fonts/." "$CONTAINER_NAME:$TARGET_DIR/"

msg "Refreshing font cache..." "刷新字体缓存..."
docker exec -u root "$CONTAINER_NAME" sh -c '
set -e

if ! command -v fc-cache >/dev/null 2>&1; then
    echo "Installing fontconfig (fc-cache)..."
    apt-get update
    apt-get install -y --no-install-recommends fontconfig
    rm -rf /var/lib/apt/lists/*
fi

fc-cache -fv
'

msg "Done: fonts installed in $TARGET_DIR" "完成：字体已安装到 $TARGET_DIR"
