FROM pibsas/sharelatex:6.0.1

# 避免 apt 交互
ENV DEBIAN_FRONTEND=noninteractive

# 1. 基础工具 + 中文字体（系统级）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        perl \
        xz-utils \
        xfonts-wqy \
        fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/*

# 2. 可选：配置 TeX Live 仓库（国内镜像，默认注释掉）
# RUN tlmgr repository set https://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet

# 3. 更新 tlmgr 自身（使用当前 TeX Live 默认仓库）
RUN tlmgr update --self

# 4. 安装完整 scheme-full
RUN tlmgr install scheme-full

# 5. 确保 TeX Live 2025 的 bin 在 PATH 里
ENV PATH="/usr/local/texlive/2025/bin/x86_64-linux:${PATH}"
