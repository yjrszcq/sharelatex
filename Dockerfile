FROM fuckery/sharelatex:5.5.1-arm64-basic

RUN apt update

# from the images with texlive should comment out this line
RUN tlmgr install scheme-full

RUN apt install -y latex-cjk-all texlive-lang-chinese texlive-lang-english
RUN apt install -y xfonts-wqy

RUN apt install -y texlive-xetex texlive-latex-extra texlive-science
