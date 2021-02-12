# hiveos-docker

Run HiveOS in a Docker instance or on Kubernetes. This project is not officially affiliated with HiveOS in any way.

Running this docker instance will download the latest HiveOS, insert your `rig.conf` HiveOS
configuration file into the image, and it will use QEMU to run it. The image file that is downloaded
and modified will be saved to the volume you pass in that's mounted at `/hiveos-image`.

Note the `docker` command requires several flags to passthrough your GPUs (can be NVidia or AMD). You must have the kernel command line options `iommu=pt intel_iommu=on` (for Intel) to enable IOMMU/VT-d to get these GPUs to show up correctly in the VM.

## Running

1. Create your `rig.conf` as per the HiveOS website
2. Run the following docker command (this will be interactive)

```bash
docker run -it --rm \
  --name hiveos \
  -v $(pwd)/hiveos-docker-image:/hiveos-image \
  --privileged \
  --device /dev/kvm \
  --device /dev/vfio/vfio \
  --device /dev/vfio/1 \
  -v /lib/modules:/lib/modules:ro \
  --ulimit memlock=-1:-1 \
  ghcr.io/lg/hiveos-docker
```

3. After the image creating and modifications are done, it should show up on your HiveOS Farm.
4. To run in the background going forward, replace the `-it --rm` piece with `-d` and run it again.