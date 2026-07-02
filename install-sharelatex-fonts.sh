#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="sharelatex"
ZIP_FILE=""
FONT_DIR=""
FONT_FILE=""
TARGET_DIR="/usr/share/fonts/addfonts"
TMP_ZIP="/tmp/sharelatex-fonts.zip"

usage() {
    cat <<EOF
用法：
  $0 -z Fonts.zip [-c sharelatex]
  $0 -d Fonts     [-c sharelatex]
  $0 -f simsun.ttc [-c sharelatex]

参数：
  -c  容器名，默认 sharelatex
  -z  本地字体 zip 文件，例如 Fonts.zip
  -d  本地字体目录，例如 Fonts
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
            echo "错误：-$OPTARG 缺少参数"
            usage
            exit 1
            ;;
        \?)
            echo "错误：未知参数 -$OPTARG"
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
    echo "错误：必须指定 -z、-d、-f 其中一种输入"
    usage
    exit 1
fi

if [ "$input_count" -gt 1 ]; then
    echo "错误：-z、-d、-f 只能三选一"
    usage
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "错误：未找到 docker 命令"
    exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    echo "错误：容器 $CONTAINER_NAME 未运行"
    echo "当前运行中的容器："
    docker ps --format '  {{.Names}}'
    exit 1
fi

echo "创建容器字体目录：$TARGET_DIR"
docker exec -u root "$CONTAINER_NAME" mkdir -p "$TARGET_DIR"

if [ -n "$ZIP_FILE" ]; then
    if [ ! -f "$ZIP_FILE" ]; then
        echo "错误：找不到 zip 文件 $ZIP_FILE"
        exit 1
    fi

    echo "复制 zip 文件到容器：$ZIP_FILE"
    docker cp "$ZIP_FILE" "$CONTAINER_NAME:$TMP_ZIP"

    echo "解压到容器目录：$TARGET_DIR"
    docker exec -u root "$CONTAINER_NAME" bash -lc "
set -e

if ! command -v unzip >/dev/null 2>&1; then
    apt-get update
    apt-get install -y --no-install-recommends unzip
    rm -rf /var/lib/apt/lists/*
fi

unzip -o '$TMP_ZIP' -d '$TARGET_DIR'
rm -f '$TMP_ZIP'
"
fi

if [ -n "$FONT_DIR" ]; then
    if [ ! -d "$FONT_DIR" ]; then
        echo "错误：找不到字体目录 $FONT_DIR"
        exit 1
    fi

    echo "复制字体目录内容到容器：$TARGET_DIR"
    docker cp "$FONT_DIR/." "$CONTAINER_NAME:$TARGET_DIR/"
fi

if [ -n "$FONT_FILE" ]; then
    if [ ! -f "$FONT_FILE" ]; then
        echo "错误：找不到字体文件 $FONT_FILE"
        exit 1
    fi

    echo "复制单个字体文件到容器：$TARGET_DIR"
    docker cp "$FONT_FILE" "$CONTAINER_NAME:$TARGET_DIR/"
fi

echo "刷新字体缓存..."
docker exec -u root "$CONTAINER_NAME" fc-cache -fv

echo "完成：字体已安装到 $TARGET_DIR"