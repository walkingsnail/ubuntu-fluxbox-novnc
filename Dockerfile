# ubuntu with Miniconda and noVNC, mongodb
# noVNC port: 6080, passwd: 888888 ($VNC_PW)
# docker run -itd --name demo -p 6080:6080 -p 28017:28017 image_Name

FROM ubuntu

# Setup environment variables
ENV VNC_PW=888888 \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    DISPLAY=:0.0 \
    DISPLAY_WIDTH=1680 \
    DISPLAY_HEIGHT=1050

# 使用传统的 bash 作为 shell 解释器
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# 时区设置
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install git, supervisor, VNC, & X11 packages
RUN echo "" > /etc/apt/sources.list \
    && echo "deb http://mirrors.163.com/ubuntu/ xenial main multiverse restricted universe" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.163.com/ubuntu/ xenial-backports main multiverse restricted universe" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.163.com/ubuntu/ xenial-proposed main multiverse restricted universe" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.163.com/ubuntu/ xenial-security main multiverse restricted universe" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.163.com/ubuntu/ xenial-updates main multiverse restricted universe" >> /etc/apt/sources.list \
    && echo "deb-src http://mirrors.163.com/ubuntu/ xenial main multiverse restricted universe" >> /etc/apt/sources.list \
    && echo "deb-src http://mirrors.163.com/ubuntu/ xenial-backports main multiverse restricted universe" >> /etc/apt/sources.list \
    && echo "deb-src http://mirrors.163.com/ubuntu/ xenial-proposed main multiverse restricted universe" >> /etc/apt/sources.list \
    && echo "deb-src http://mirrors.163.com/ubuntu/ xenial-security main multiverse restricted universe" >> /etc/apt/sources.list \
    && echo "deb-src http://mirrors.163.com/ubuntu/ xenial-updates main multiverse restricted universe" >> /etc/apt/sources.list \
    && apt-get clean \
    && apt-get update -y && \
    apt-get install -y supervisor bzip2 curl rsync wget git fluxbox libgl1-mesa-glx qt5-default ttf-wqy-microhei net-tools iputils-ping x11vnc python python-numpy tar gzip xvfb vim && \
    apt-get install -y build-essential libboost-all-dev python-dev cmake && \
    apt-get autoclean && apt-get autoremove && \
    rm -rf /var/lib/apt/lists/*

# Clone noVNC from github
RUN mkdir ~/.vnc && \
    x11vnc -storepasswd ${VNC_PW} ~/.vnc/passwd && \
    mkdir -p /root/noVNC/utils/websockify && \
    wget -qO- https://github.com/ConSol/noVNC/archive/consol_1.0.0.tar.gz | tar xz --strip 1 -C /root/noVNC && \
    wget -qO- https://github.com/kanaka/websockify/archive/v0.7.0.tar.gz | tar xz --strip 1 -C /root/noVNC/utils/websockify && \
    cd /root/noVNC && ln -s vnc.html index.html && \
    mkdir /tmp/conda/ && \
    cd /tmp/conda

COPY ./Miniconda*.sh /tmp/conda/

RUN bash /tmp/conda/Miniconda*.sh -b -p /opt/conda && \
    rm -rf /tmp/conda && \
    echo "设置 conda 和 python 的环境路径" && \
    ln -s /opt/conda/bin/python /usr/local/bin/python && \
    ln -s /opt/conda/bin/conda /usr/local/bin/conda && \
    ln -s /opt/conda/bin/pip /usr/local/bin/pip

RUN echo "安装 mongodb 服务" && \
    # mkdir -p /data/db && \
    apt-get update -y && \
    apt-get install -y mongodb && \
    systemctl enable mongodb.service && \
    sed -i 's/bind_ip = 127.0.0.1/\#bind_ip = 127.0.0.1/g' /etc/mongodb.conf

COPY light-grey.png /usr/share/images/fluxbox/ubuntu-light.png
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Modify the launch script 'ps -p'
RUN sed -i -- "s/ps -p/ps -o pid | grep/g" /root/noVNC/utils/launch.sh

WORKDIR /home

EXPOSE 6080 28017

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
