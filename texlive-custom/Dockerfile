ARG BASE_IMAGE=ghcr.io/ayaka-notes/texlive-full:2026.1
FROM ${BASE_IMAGE}

USER root
COPY fonts/ /usr/share/fonts/addfonts/
RUN chmod -R a+rX /usr/share/fonts/addfonts && fc-cache -fv
