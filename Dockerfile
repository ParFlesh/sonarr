FROM ubuntu:latest as artifact

RUN apt-get update && \
    apt-get install -y curl jq && \
    curl -o /repo-mediaarea.deb https://mediaarea.net/repo/deb/repo-mediaarea_1.0-19_all.deb

FROM ubuntu:latest
LABEL maintainer='ParFlesh'

COPY --chown=1001:0 --from=artifact /repo-mediaarea.deb /repo-mediaarea.deb

COPY test.sh /

ENV TZ=Etc/UTC \
    DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

RUN apt-get update && \
    apt-get install -y apt-transport-https gnupg ca-certificates && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8 && \
    UBUNTU_CODENAME=$(grep UBUNTU_CODENAME /etc/os-release|awk -F'=' '{print $NF}') && \
    echo "deb https://apt.sonarr.tv/ubuntu $UBUNTU_CODENAME main" | tee /etc/apt/sources.list.d/sonarr.list && \
    echo "deb http://download.mono-project.com/repo/ubuntu $UBUNTU_CODENAME main" | tee /etc/apt/sources.list.d/mono-official.list && \
    dpkg -i /repo-mediaarea.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests sonarr && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /config && \
    chown 1001:0 /config && \
    chmod 770 /config

EXPOSE 8989
VOLUME ["/config"]
WORKDIR /config
ENTRYPOINT ["/usr/bin/mono", "/usr/lib/sonarr/bin/Sonarr.exe"]
CMD ["-nobrowser", "-data=/config"]
