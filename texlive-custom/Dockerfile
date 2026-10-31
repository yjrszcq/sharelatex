ARG TEXLIVE_VERSION=2026.1
FROM ghcr.io/ayaka-notes/texlive-full:${TEXLIVE_VERSION}

USER root
COPY fonts/ /usr/share/fonts/addfonts/
RUN chmod -R a+rX /usr/share/fonts/addfonts && fc-cache -fv
