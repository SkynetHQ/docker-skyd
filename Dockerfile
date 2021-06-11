FROM debian:stretch-slim AS zip_downloader
LABEL maintainer="NebulousLabs <devs@nebulous.tech>"

ARG SIA_VERSION="1.5.5"
ARG SIA_PACKAGE="Sia-v${SIA_VERSION}-linux-amd64"
ARG SIA_ZIP="${SIA_PACKAGE}.zip"
ARG SIA_RELEASE="https://sia.tech/releases/${SIA_ZIP}"

ARG SU_EXEC="su-exec-musl-static"
ARG SU_EXEC_VERSION="1.3-skynetlabs-0.2.0"
ARG SU_EXEC_RELEASE="https://github.com/SkynetLabs/su-exec/releases/download/${SU_EXEC_VERSION}/${SU_EXEC}"

RUN apt-get update && \
    apt-get install -y wget unzip && \
    wget "$SIA_RELEASE" && \
    mkdir /sia && \
    unzip -j "$SIA_ZIP" "${SIA_PACKAGE}/siac" -d /sia && \
    unzip -j "$SIA_ZIP" "${SIA_PACKAGE}/siad" -d /sia && \
    wget "$SU_EXEC_RELEASE"

FROM debian:stretch-slim
LABEL maintainer="NebulousLabs <devs@nebulous.tech>"

ARG SIA_DIR="/sia"
ARG SIA_DATA_DIR="/sia-data"
ARG SIAD_DATA_DIR="/sia-data"

RUN apt-get update && apt-get install -y mime-support

# Workaround for backwards compatibility with old images, which hardcoded the
# Sia data directory as /mnt/sia. Creates a symbolic link so that any previous
# path references stored in the Sia host config still work.
RUN ln -s "$SIA_DATA_DIR" /mnt/sia

WORKDIR "$SIA_DIR"

ENV SIA_DATA_DIR "$SIA_DATA_DIR"
ENV SIAD_DATA_DIR "$SIAD_DATA_DIR"
ENV SIA_MODULES gctwhr

COPY --from=zip_downloader /sia/siac /sia/siad /usr/bin/
COPY scripts/*.sh ./

# Preparation for su-exec
ENV SU_EXEC="su-exec-musl-static"
COPY --from=zip_downloader "/${SU_EXEC}" /usr/bin/
RUN chmod +x /usr/bin/siac && \
    chmod +x /usr/bin/siad && \
    chmod +x "/usr/bin/${SU_EXEC}"

EXPOSE 9980

ENTRYPOINT ["./run.sh"]
