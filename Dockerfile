FROM pibsas/sharelatex-base:5.5.4

RUN apt update

# from the images with texlive should comment out this line
RUN tlmgr install scheme-full

RUN apt install -y latex-cjk-all texlive-lang-chinese texlive-lang-english
RUN apt install -y xfonts-wqy

RUN apt install -y texlive-xetex texlive-latex-extra texlive-science
