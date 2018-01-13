# ubuntu with Miniconda and noVNC, mongodb
# noVNC port: 6080, passwd: 888888 ($VNC_PW)
# docker run -itd --name demo -p 6080:6080 -p 27017:27017 -p 28017:28017 image_Name

FROM hub.c.163.com/public/ubuntu:16.04-tools

ENV VNC_PW=888888 \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    DISPLAY=:0.0 \
    DISPLAY_WIDTH=1680 \
    DISPLAY_HEIGHT=1050 \
    TZ=Asia/Shanghai

RUN rm /bin/sh && ln -s /bin/bash /bin/sh && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

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
    apt-get install -y supervisor bzip2 curl rsync wget git fluxbox libgl1-mesa-glx qt5-default ttf-wqy-microhei net-tools iputils-ping tcpdump x11vnc python python-numpy tar gzip xvfb vim htop && \
    apt-get install -y build-essential libboost-all-dev libboost-python-dev libsnappy-dev python-dev cmake mongodb python-qt4 && \
    apt-get autoclean && apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /data/db && \
    mkdir /tmp/conda/

COPY ./Miniconda*.sh /tmp/conda/
COPY ./vnpy-1.7.2 /root/vnpy/vnpy-1.7.2

RUN mkdir ~/.vnc && \
    x11vnc -storepasswd ${VNC_PW} ~/.vnc/passwd && \
    mkdir -p /root/noVNC/utils/websockify && \
    wget -qO- https://github.com/ConSol/noVNC/archive/consol_1.0.0.tar.gz | tar xz --strip 1 -C /root/noVNC && \
    wget -qO- https://github.com/kanaka/websockify/archive/v0.7.0.tar.gz | tar xz --strip 1 -C /root/noVNC/utils/websockify && \
    cd /root/noVNC && ln -s vnc.html index.html && \
    bash /tmp/conda/Miniconda*.sh -b -p /opt/conda && \
    rm -rf /tmp/conda && \
    ln -s /opt/conda/bin/python /usr/local/bin/python && \
    ln -s /opt/conda/bin/conda /usr/local/bin/conda && \
    ln -s /opt/conda/bin/pip /usr/local/bin/pip

COPY light-grey.png /usr/share/images/fluxbox/ubuntu-light.png
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN sed -i -- "s/ps -p/ps -o pid | grep/g" /root/noVNC/utils/launch.sh

WORKDIR /root/vnpy/vnpy-1.7.2

# 后述指令建议手工执行
RUN pip install -r requirements.txt
RUN conda install pyqt=4.11
RUN conda install -c quantopian ta-lib=0.4.9
RUN pip install qtpy zmq
RUN bash install.sh
RUN cp  /root/vnpy/vnpy-1.7.2/vnpy/api/ctp/build/lib/vnctp*.so /opt/conda/lib/python2.7/site-packages/vnpy/api/ctp/
    
EXPOSE 6080 5900 27017 28017

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]