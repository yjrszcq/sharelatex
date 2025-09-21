from sharelatex/sharelatex:5.5.4

RUN apt update

RUN tlmgr install scheme-full

RUN apt install -y latex-cjk-all texlive-lang-chinese texlive-lang-english
RUN apt install -y xfonts-wqy

RUN apt install -y texlive-xetex texlive-latex-extra texlive-science
