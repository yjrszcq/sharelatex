FROM sharelatex/sharelatex:5.5.4

RUN apt update

# 先更新tlmgr自身
RUN tlmgr update --self --force

# 安装完整的TeX Live套件
RUN tlmgr install scheme-full \
    && apt install -y latex-cjk-all texlive-lang-chinese texlive-lang-english \
    && apt install -y xfonts-wqy \
    && apt install -y texlive-xetex texlive-latex-extra texlive-science

# 修复可能的依赖问题
RUN apt --fix-broken install -y
