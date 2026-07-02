FROM sharelatex/sharelatex:6.2.0

# ============================================================
# TeX Live: 切到 2025 冻结快照,安装完整方案
# ============================================================
RUN tlmgr option repository https://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2025/tlnet-final && \
    tlmgr update --self && \
    tlmgr install scheme-full

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
# 用法: 把 win-fonts/ 目录放到 Dockerfile 同级,里面放:
#   simsun.ttc  simhei.ttf  simkai.ttf  simfang.ttf
#   (可从 C:\Windows\Fonts 复制)
# 如果没有这些字体,下面这两行会报错,可以注释掉。
COPY fonts/ /usr/share/fonts/addfonts/
RUN fc-cache -fv

# ============================================================
# 配置 XeLaTeX 使用系统字体
# ============================================================
RUN luaotfload-tool --update --force || true
