FROM alpine
WORKDIR /hiveos-docker
VOLUME /hiveos-image

RUN apk add qemu-system-x86_64 ovmf curl qemu-img xz ntfs-3g pciutils
RUN cp /usr/share/OVMF/OVMF_VARS.fd qemu.nvram

COPY start.sh ./
CMD ["./start.sh"]