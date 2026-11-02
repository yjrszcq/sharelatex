ARG IMAGE_VERSION=6.3.2
FROM ghcr.io/ayaka-notes/overleaf-pro/git-bridge:${IMAGE_VERSION} AS git-bridge
FROM ghcr.io/ayaka-notes/overleaf-pro:${IMAGE_VERSION} AS git-bridge-runtime

# Git Bridge: reuse the official JAR and configuration for the same release.
RUN apt-get update && \
    apt-get install -y --no-install-recommends openjdk-21-jre-headless git sqlite3 util-linux && \
    rm -rf /var/lib/apt/lists/* && \
    useradd --system --user-group --home-dir /data/git-bridge git-bridge

COPY --from=git-bridge /git-bridge.jar /opt/git-bridge/git-bridge.jar
COPY --from=git-bridge /opt/envsubst /opt/git-bridge/envsubst
COPY --from=git-bridge /envsubst_template.json /opt/git-bridge/envsubst_template.json
COPY --from=git-bridge /start.sh /opt/git-bridge/start.sh
COPY docker/git-bridge/init.sh /etc/my_init.d/190_git_bridge.sh
COPY docker/git-bridge/run /etc/service/git-bridge/run
RUN sed -i \
        -e 's|/opt/envsubst|/opt/git-bridge/envsubst|g' \
        -e 's|/envsubst_template.json|/opt/git-bridge/envsubst_template.json|g' \
        -e 's|/conf/runtime.json|/opt/git-bridge/conf/runtime.json|g' \
        -e 's|/git-bridge.jar|/opt/git-bridge/git-bridge.jar|g' \
        /opt/git-bridge/start.sh && \
    chmod +x /opt/git-bridge/start.sh /opt/git-bridge/envsubst \
        /etc/my_init.d/190_git_bridge.sh /etc/service/git-bridge/run && \
    touch /etc/service/git-bridge/down

ENV GIT_BRIDGE_HOST=127.0.0.1 GIT_BRIDGE_PORT=8000

FROM git-bridge-runtime

ARG TEXLIVE_YEAR=2026
ARG TARGETARCH
ARG TEXLIVE_BIN_SUBDIR=x86_64-linux

# ============================================================
# TeX Live
# ============================================================
RUN tlmgr update --self && \
    tlmgr install scheme-full

RUN if [ "${TARGETARCH}" = "arm64" ]; then \
        TEXLIVE_BIN_SUBDIR=aarch64-linux; \
    fi && \
    ln -sf /usr/local/texlive/${TEXLIVE_YEAR}/bin/${TEXLIVE_BIN_SUBDIR}/biber /usr/local/bin/biber

# ============================================================
# 系统字体: 中日韩全家桶 + 常见西文字体
# ============================================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # 文泉驿(中文开源字体,老模板常用)
        fonts-wqy-microhei \
        fonts-wqy-zenhei \
        # 思源字体(Google/Adobe,覆盖中日韩)
        fonts-noto-cjk \
        fonts-noto-cjk-extra \
        fonts-noto-color-emoji \
        fonts-noto-mono \
        # 方正、文鼎等开源中文字体
        fonts-arphic-ukai \
        fonts-arphic-uming \
        # 常见西文字体
        fonts-liberation \
        fonts-liberation2 \
        fonts-dejavu \
        fonts-dejavu-extra \
        fonts-freefont-ttf \
        fonts-freefont-otf \
        fonts-lmodern \
        fonts-texgyre \
        # 等宽/编程字体(代码块好看)
        fonts-firacode \
        fonts-hack \
        fonts-inconsolata \
        fonts-jetbrains-mono \
        # 数学符号字体
        fonts-stix \
        # 通用工具
        fontconfig && \
    fc-cache -fv && \
    rm -rf /var/lib/apt/lists/*

# ============================================================
# Windows 中文字体(宋体/黑体/楷体/仿宋)— xduts 模板要求
# ============================================================
# 注意: Windows 字体有版权,仅限自用。如果要公开分发镜像,
# 请删除这段,改用 Windows 机器本地挂载字体目录的方式。
# 用法: 把 fonts/ 目录放到 Dockerfile 同级,里面放:
#   simsun.ttc  simhei.ttf  simkai.ttf  simfang.ttf
#   (可从 C:\Windows\Fonts 复制)
# 如果没有这些字体,下面这两行会报错,可以注释掉。
COPY fonts/ /usr/share/fonts/addfonts/
RUN fc-cache -fv

# ============================================================
# 配置 XeLaTeX 使用系统字体
# ============================================================
RUN luaotfload-tool --update --force || true
