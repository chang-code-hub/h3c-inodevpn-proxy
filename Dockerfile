FROM debian:11-slim AS builder
ENV DEBIAN_FRONTEND=noninteractive

# 更换源 Debian 12
# RUN sed -i 's/http:\/\/deb.debian.org/http:\/\/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources
# RUN sed -i 's/http:\/\/security.debian.org/http:\/\/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources

# 更换源 Debian 11
RUN sed -i 's/http:\/\/deb.debian.org/http:\/\/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list && \
  sed -i 's/http:\/\/security.debian.org/http:\/\/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
	
RUN apt-get update && \
  apt-get install -y tar && \
  apt-get clean

# 将 iNode 客户端安装包复制到容器中
COPY iNodeClient_Linux_X64_7.3_E632.tar.gz /opt/

# 解压 iNode 客户端
RUN tar -zxvf /opt/iNodeClient_Linux_X64_7.3_E632.tar.gz -C /opt/

FROM debian:11-slim
ENV DEBIAN_FRONTEND=noninteractive
COPY --from=builder /opt/iNodeClient /opt/iNodeClient

# 安装 依赖
# RUN sed -i 's/http:\/\/deb.debian.org/http:\/\/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources && \
#   sed -i 's/http:\/\/security.debian.org/http:\/\/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources
RUN sed -i 's/http:\/\/deb.debian.org/http:\/\/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list && \
  sed -i 's/http:\/\/security.debian.org/http:\/\/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
RUN apt-get update && \
  apt-get install --no-install-recommends -y xpra xvfb iptables squid libgtk2.0-0 iproute2 net-tools iputils-ping kmod procps dbus-x11 x11-utils && \
  apt-get install -y python3-pip && \
  pip3 install pillow==9.5.0 && \
  apt-get purge -y gcc make python3-pip wget curl && \
  apt-get autoremove -y && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  rm -rf /usr/share/icons/Adwaita && \
  rm -rf /usr/include/* /usr/lib/gcc && \
  rm -rf /usr/share/perl /usr/share/perl/5.32.1 && \
  rm -rf /usr/lib/x86_64-linux-gnu/dri /usr/lib/x86_64-linux-gnu/mfx && \
  rm -rf /lib/x86_64-linux-gnu/security /lib/terminfo && \
  rm -rf /usr/share/doc && \
  echo net.ipv4.ip_forward=1 >> nano /etc/sysctl.conf && \
  mkdir -p /etc/xdg/menuss && \
  mkdir -p /etc/squid/

  # Debian 11   
#   apt-get install -y python3-pip && \
#   pip3 install pillow==9.5.0 && \

# Ubuntu
COPY kde-debian-menu.menu /etc/xdg/menus/kde-debian-menu.menu
COPY squid.conf /etc/squid/squid.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 14500
EXPOSE 3128
VOLUME ["/opt/iNodeClient/log"]
VOLUME ["/opt/iNodeClient/conf"]
VOLUME ["/opt/iNodeClient/clientfiles"]

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
