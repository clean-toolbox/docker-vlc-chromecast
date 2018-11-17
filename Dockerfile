FROM ubuntu

RUN echo "deb-src http://archive.ubuntu.com/ubuntu/ bionic universe" >> /etc/apt/sources.list \
    && echo "deb-src http://archive.ubuntu.com/ubuntu/ bionic-updates universe" >> /etc/apt/sources.list \
    && echo "deb-src http://archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse" >> /etc/apt/sources.list

RUN DEBIAN_FRONTEND=noninteractive && apt-get update -y

# Very important because we must use source and pass variables from one script to another
#with default /bin/sh its not posible not use source or . to execute scripts and teh variable are only for local use

SHELL ["/bin/bash", "-c"]

RUN apt-get install git build-essential pkg-config libtool nano gnutls-bin automake autopoint gettext -y

RUN apt-get build-dep vlc -y

RUN cd / && git clone git://git.videolan.org/vlc.git

COPY ./chromecast_communication.cpp /vlc/modules/stream_out/chromecast/chromecast_communication.cpp

RUN cd /vlc && ./bootstrap

RUN cd /vlc && ./configure --enable-chromecast --disable-xcb

RUN make -C /vlc

RUN useradd -m -d /data -s /bin/bash -u 1000 vlc

COPY  entrypoint /entrypoint

COPY  sample.mp4 /sample.mp4

WORKDIR /vlc

ENTRYPOINT ["/entrypoint/entrypoint.sh"]

EXPOSE 8010

CMD ["-vvv", "--network-caching=1000","/sample.mp4",  "--demux-filter=cc_demux", "--play-and-exit"]

RUN apt-get install sudo -y