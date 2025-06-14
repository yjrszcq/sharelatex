FROM immortal6736/sharelatex:5.0.3

RUN apt update

RUN wget https://mirror.ctan.org/systems/texlive/tlnet/update-tlmgr-latest.sh & sh ./update-tlmgr-latest.sh -- --upgrade

RUN apt install -y latex-cjk-all texlive-lang-chinese texlive-lang-english
RUN apt install -y xfonts-wqy

RUN apt install -y texlive-xetex texlive-latex-extra texlive-science
