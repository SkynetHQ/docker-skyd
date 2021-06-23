FROM debian:stretch-slim AS zip_downloader
LABEL maintainer="SkynetLabs <devs@siasky.net>"

# TODO: verify once skyd release process is defined
ARG SKYD_VERSION="1.6.0"
ARG SKYD_PACKAGE="Skyd-v${SKYD_VERSION}-linux-amd64"
ARG SKYD_ZIP="${SKYD_PACKAGE}.zip"
ARG SKYD_RELEASE="https://sia.tech/releases/${SKYD_ZIP}"
ARG QEMU_BIN="https://github.com/multiarch/qemu-user-static/releases/download/v4.2.0-7/qemu-aarch64-static"

# TODO: verify once skyd release process is defined
RUN apt-get update && \
    apt-get install -y wget unzip && \
    wget "$SKYD_RELEASE" && \
    mkdir /sia && \
    unzip -j "$SKYD_ZIP" "${SKYD_PACKAGE}/siac" -d /sia && \
    unzip -j "$SKYD_ZIP" "${SKYD_PACKAGE}/siad" -d /sia && \
    wget "$QEMU_BIN" && \
    chmod +x qemu-aarch64-static

FROM arm64v8/debian:stretch-slim
LABEL maintainer="SkynetLabs <devs@siasky.net>"

# NOTE: Leaving as sia and sia-data for backwards compatibility
ARG SIA_DIR="/sia"
ARG SIA_DATA_DIR="/sia-data"
ARG SIAD_DATA_DIR="/sia-data"

# We need qemu in order to run ARM commands on an AMD64 CI machine.
COPY --from=zip_downloader qemu-aarch64-static /usr/bin

RUN apt-get update && apt-get install -y mime-support

# Workaround for backwards compatibility with old images, which hardcoded the
# Sia data directory as /mnt/sia. Creates a symbolic link so that any previous
# path references stored in the Sia host config still work.
#
# NOTE: Leaving as /mnt/sia for backwards compatibility
RUN ln -s "$SIA_DATA_DIR" /mnt/sia

WORKDIR "$SIA_DIR"

ENV SIA_DATA_DIR "$SIA_DATA_DIR"
ENV SIAD_DATA_DIR "$SIAD_DATA_DIR"
ENV SIA_MODULES gctwhr

COPY --from=zip_downloader /sia/siac /sia/siad /usr/bin/
COPY scripts/*.sh ./

EXPOSE 9980

ENTRYPOINT ["./run.sh"]
