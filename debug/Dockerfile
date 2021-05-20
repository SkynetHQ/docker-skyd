FROM golang:1.15
LABEL maintainer="NebulousLabs <devs@nebulous.tech>"

ENV GOOS linux
ENV GOARCH amd64
ENV GO111MODULE on

ARG SU_EXEC="su-exec-musl-static"
ARG SU_EXEC_VERSION="1.3-skynetlabs-0.2.0"
ARG SU_EXEC_RELEASE="https://github.com/SkynetLabs/su-exec/releases/download/${SU_EXEC_VERSION}/${SU_EXEC}"

WORKDIR /root

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get -y autoremove && \
    apt-get -y install python3-pip sudo wget curl zip vim nano nload psmisc less mime-support logrotate cron && \
    apt-get clean && \
    mv /etc/cron.daily/logrotate /etc/cron.hourly && \
    wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s v1.30.0 && \
    pip3 install codespell && \
    go get gitlab.com/NebulousLabs/analyze && \
    git clone https://gitlab.com/NebulousLabs/Sia.git && \
    cd Sia && \
    make release && \
    cd - && \
    cd / && \
    wget "$SU_EXEC_RELEASE" && \
    cd -

# Setup the actual Sia environment.
ARG SIA_DIR="/sia"
ARG SIA_DATA_DIR="/sia-data"
ARG SIAD_DATA_DIR="/sia-data"

COPY ./debug/.vimrc ./debug/.bashrc scripts/*.sh ./
COPY scripts/logrotate-sia /etc/logrotate.d/sia

ENV SIA_DATA_DIR "$SIA_DATA_DIR"
ENV SIAD_DATA_DIR "$SIAD_DATA_DIR"
ENV SIA_MODULES gctwhr

# Preparation for su-exec
ENV SU_EXEC "$SU_EXEC"
RUN mv "/${SU_EXEC}" /usr/bin/ && \
    chmod +x "$GOPATH/bin/siac" && \
    chmod +x "$GOPATH/bin/siad" && \
    chmod +x "/usr/bin/${SU_EXEC}"

EXPOSE 9980

ENTRYPOINT ["./run.sh"]
