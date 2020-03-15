FROM ubuntu:rolling as artifact

ARG SONARR_VERSION=latest
ARG SONARR_BRANCH="phantom-develop"

RUN apt-get update && \
    apt-get install -y curl jq && \
    if [ "latest" != "$SONARR_VERSION" ];then VERSION=$SONARR_VERSION ; else VERSION=$(curl -sX GET https://services.sonarr.tv/v1/download/${SONARR_BRANCH}?version=3 | jq -r '.version');fi && \
    curl -L "https://download.sonarr.tv/v3/${SONARR_BRANCH}/${VERSION}/Sonarr.${SONARR_BRANCH}.${VERSION}.linux.tar.gz" | tar zxvf - && \
    mv Sonarr* sonarr && \
    curl -L "https://mediaarea.net/repo/deb/repo-mediaarea_1.0-12_all.deb" -o /sonarr/mediaarea.deb && \
    chown -R 1001:0 /sonarr && \
    chmod -R g=u /sonarr

ADD test.sh /sonarr/

RUN chmod 755 /sonarr/test.sh && \
    chown 1001:0 /sonarr/test.sh

FROM ubuntu:rolling
MAINTAINER ParFlesh

COPY --chown=1001:0 --from=artifact /sonarr /sonarr

RUN apt-get update && \
    apt-get install -y apt-transport-https gnupg ca-certificates && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    UBUNTU_CODENAME=$(grep UBUNTU_CODENAME /etc/os-release|awk -F'=' '{print $NF}') && \
    echo "deb http://download.mono-project.com/repo/ubuntu bionic main" | tee /etc/apt/sources.list.d/mono-official.list && \
    dpkg -i /sonarr/mediaarea.deb && \
    #echo "deb https://mediaarea.net/repo/deb/ubuntu $UBUNTU_CODENAME main" | tee /etc/apt/sources.list.d/mediaarea.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests bzip2 ca-certificates-mono libcurl4-openssl-dev mediainfo mono-devel mono-vbnc python sqlite3 unzip && \
    rm -rf /var/lib/apt/lists/* && \
    echo "UpdateMethod=docker\nBranch=${SONARR_BRANCH}\nPackageVersion=${VERSION}\nPackageAuthor=ParFlesh" > /sonarr/package_info && \
    rm -rf /sonarr/bin/Sonarr.Update && \
    mkdir /config && \
    chown 1001:0 /config && \
    chmod 770 /config

EXPOSE 8989
VOLUME ["/config"]
WORKDIR /sonarr
ENTRYPOINT ["mono", "--debug", "Sonarr.exe"]
CMD ["-nobrowser", "-data=/config"]