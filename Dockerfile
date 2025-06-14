FROM immortal6736/sharelatex:5.0.3

# 解决跨版本问题的关键步骤
RUN \
    # 1. 指定使用 2024 版镜像仓库
    sed -i 's|http://mirror.ctan.org|https://mirrors.tuna.tsinghua.edu.cn/CTAN|g' \
        /usr/local/texlive/2024/tlpkg/texlive.tlpdb && \
    # 2. 更新基础系统包
    apt-get update && apt-get install -y --no-instend-recommends \
        wget \
        perl-tk \
        ghostscript \
        && \
    # 3. 强制升级 tlmgr 核心组件
    tlmgr update --self --force && \
    # 4. 指定使用特定年份的仓库
    tlmgr option repository https://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet/archive/2024 && \
    # 5. 分阶段安装避免超时
    tlmgr install \
        scheme-infraonly \
        collection-fontsrecommended \
        collection-latexrecommended && \
    tlmgr install \
        scheme-full \
        && \
    # 6. 清理缓存减小镜像体积
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 中文支持及扩展包
RUN \
    apt-get update && apt-get install -y --no-instend-recommends \
        latex-cjk-all \
        texlive-lang-chinese \
        texlive-lang-english \
        texlive-xetex \
        texlive-latex-extra \
        texlive-science \
        xfonts-wqy \
        && \
    # 重建格式文件
    fmtutil-sys --all && \
    mktexlsr && \
    # 二次清理
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*
