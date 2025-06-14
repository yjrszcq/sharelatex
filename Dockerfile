# FROM immortal6736/sharelatex:5.0.3
FROM darktohka/sharelatex-arm64:base-arm64

RUN apt update

RUN tlmgr install scheme-full # FROM immortal6736/sharelatex:5.0.3 should comment out this line

RUN apt install -y latex-cjk-all texlive-lang-chinese texlive-lang-english
RUN apt install -y xfonts-wqy

RUN apt install -y texlive-xetex texlive-latex-extra texlive-science
