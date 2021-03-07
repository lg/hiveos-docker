#!/bin/ash

if ! test -f /hiveos-rig/hiveos.qcow2; then
  echo "The file /hiveos-rig/hiveos.qcow2 doesnt exist (or isnt volume linked), going to create it now."
  if ! test -f /hiveos-rig/rig.conf; then
    echo "Missing /hiveos-rig/rig.conf file. Aborting."
    exit 1
  fi

  cd /hiveos-rig
  echo "Downloading HiveOS..."
  curl -o hiveos.img.xz "https://download.hiveos.farm/$(curl 'https://download.hiveos.farm/VERSIONS.txt' 2>&1 | sed -rn 's/.*(hiveos-.*\.img\.xz)/\1/p' | head -1)"
  echo "Decompressing..."
  xz --decompress hiveos.img.xz
  echo "Converting to qcow2 and recompressing..."
  qemu-img convert -c -O qcow2 hiveos.img hiveos.qcow2
  rm hiveos.img

  echo "Updating config with supplied rig.conf..."
  modprobe nbd
  qemu-nbd -d /dev/nbd0
  qemu-nbd -c /dev/nbd0 hiveos.qcow2
  fdisk -l /dev/nbd0

  mkdir /mnt/hiveos-config
  mount -t ntfs-3g /dev/nbd0p1 /mnt/hiveos-config
  cp /hiveos-rig/rig.conf /mnt/hiveos-config/rig.conf

  umount /mnt/hiveos-config
  rm -r /mnt/hiveos-config
  qemu-nbd -d /dev/nbd0
  rmmod nbd
  echo "Image ready."
fi

cd /hiveos-docker

# disconnect all virtual terminals (for GPU passthrough to work)
echo "Unbinding consoles..."
test -e /sys/class/vtconsole/vtcon0/bind && echo 0 > /sys/class/vtconsole/vtcon0/bind
test -e /sys/class/vtconsole/vtcon1/bind && echo 0 > /sys/class/vtconsole/vtcon1/bind
test -e /sys/devices/platform/efi-framebuffer.0/driver && echo "efi-framebuffer.0" > /sys/devices/platform/efi-framebuffer.0/driver/unbind

echo "Binding vfio to all NVIDIA/AMD cards..."
modprobe vfio_pci
modprobe vfio_iommu_type1
for pci_id in $(lspci | grep -e NVIDIA -e AMD | awk '{print "0000:"$1}'); do
  test -e /sys/bus/pci/devices/$pci_id/driver && echo -n "$pci_id" > /sys/bus/pci/devices/$pci_id/driver/unbind
  echo "$(cat /sys/bus/pci/devices/$pci_id/vendor) $(cat /sys/bus/pci/devices/$pci_id/device)" > /sys/bus/pci/drivers/vfio-pci/new_id
done
while [ ! -e /dev/vfio ]; do sleep 1; done

echo "Starting QEMU..."
exec qemu-system-x86_64 \
  -monitor stdio \
  -nodefaults \
  \
  -smp cpus=2 \
  -m 4G \
  -enable-kvm \
  -cpu host,check,enforce,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time,l3-cache=on,-hypervisor,kvm=off,migratable=no,+invtsc,hv_vendor_id=1234567890ab \
  -machine type=q35 \
  -drive if=pflash,format=raw,readonly,file=/usr/share/OVMF/OVMF_CODE.fd `# read-only UEFI bios` \
  -drive if=pflash,format=raw,file=qemu.nvram `# UEFI writeable NVRAM` \
  -rtc clock=host,base=localtime \
  -device qemu-xhci `# USB3 bus` \
  \
  -drive file=/hiveos-rig/hiveos.qcow2 \
  \
  $(for x in $(lspci | grep -e NVIDIA -e AMD | awk '{print $1}'); do echo "-device vfio-pci,host=$x "; done | xargs) \
  \
  -nic user,model=rtl8139 \
  -vga none \
  -nographic
