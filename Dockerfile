#
# Stage 1: Builder
#
FROM ubuntu:eoan

ARG DEBIAN_FRONTEND=noninteractive

ENV \
  LANG='C.UTF-8' \
  LC_ALL='C.UTF-8' \
  WINEDEBUG=-all

RUN dpkg --add-architecture i386 \
  && echo 'i386 Architecture Added'

RUN apt-get update \
  && apt-get install -y \
    wine32:i386 \
    winetricks:amd64 \
    \
    # https://github.com/wszqkzqk/deepin-wine-ubuntu/issues/188#issuecomment-554599956
    # https://zj-linux-guide.readthedocs.io/zh_CN/latest/tool-install-configure/%5BUbuntu%5D%E4%B8%AD%E6%96%87%E4%B9%B1%E7%A0%81/
    ttf-wqy-microhei \
    ttf-wqy-zenhei \
    xfonts-wqy \
    \
    apt-transport-https:amd64 \
    ca-certificates:amd64 \
    cabextract:amd64 \
    curl:amd64 \
    gosu \
    language-pack-zh-hans \
    tzdata:amd64 \
    unzip:amd64 \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -fr /tmp/*

RUN groupadd group \
  && useradd -m -g group user \
  && usermod -a -G audio user \
  && usermod -a -G video user \
  && chsh -s /bin/bash user \
  && echo 'User created'

COPY --chown=user:group ./container_root/ /

ARG HOME_URL=https://github.com/huan/docker-wechat/releases/download/v0.1/home.tgz
RUN curl -sL "$HOME_URL" | tar zxf - \
  && chown -R user.group /home/user \
  && echo 'Artifacts: downlaoded'

ARG GECKO_VER=2.47
ARG MONO_VER=4.9.4
RUN mkdir -p /usr/share/wine/gecko /usr/share/wine/mono \
  && curl -sL -o /usr/share/wine/gecko/wine_gecko-${GECKO_VER}-x86.msi \
    "https://dl.winehq.org/wine/wine-gecko/${GECKO_VER}/wine_gecko-${GECKO_VER}-x86.msi" \
  # && wget https://dl.winehq.org/wine/wine-mono/${MONO_VER}/wine-mono-${MONO_VER}.msi \
  #     -O /usr/share/wine/mono/wine-mono-${MONO_VER}.msi \
  && chown -R user:group /usr/share/wine/gecko /usr/share/wine/mono \
  && echo 'Gecko & Mono installed'

USER user

RUN WINEARCH=win32 wine wineboot \
  \
  # wintricks
  && winetricks -q win7 \
  && winetricks -q riched20 \
  \
  # Regedit
  && wine regedit.exe /s 'C:\Program Files\Tencent\WeChat\install.reg' \
  && wine reg query 'HKEY_CURRENT_USER\Software\Tencent\WeChat' \
  \
  # Clean
  && rm -fr /home/user/.cache/* /home/user/tmp/* /tmp/* \
  && echo "Wine: initialized"

ENV \
  LANG=zh_CN.UTF-8 \
  LC_ALL=zh_CN.UTF-8 \
  TZ=Asia/Shanghai

VOLUME [ "/home/user/WeChat Files" ]

# FIXME: reg set success or not ???
RUN wine reg query 'HKEY_CURRENT_USER\Software\Tencent\WeChat' || echo "Graceful FAIL. REG NOT FOUND"

USER root
ENTRYPOINT [ "/entrypoint.sh" ]

LABEL \
    org.opencontainers.image.authors="Huan (李卓桓) <zixia@zixia.net>" \
    org.opencontainers.image.description="A Docker Image for Running PC Windows WeChat on Your Linux Desktop" \
    org.opencontainers.image.documentation="https://github.com/huan/docker-wechat/#readme" \
    org.opencontainers.image.licenses="Apache-2.0" \
    org.opencontainers.image.source="git@github.com:huan/docker-wechat.git" \
    org.opencontainers.image.title="docker-wechat" \
    org.opencontainers.image.url="https://github.com/huan/docker-wechat" \
    org.opencontainers.image.vendor="huan"
