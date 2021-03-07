# hiveos-docker

Run HiveOS in a Docker instance or on Kubernetes. This project is not officially affiliated with HiveOS in any way.

Running this docker instance will download the latest HiveOS, insert your `rig.conf` HiveOS
configuration file into the image, and it will use QEMU to run it. The image file that is downloaded
and modified will be saved to the volume you pass in that's mounted at `/hiveos-rig`.

Note the `docker` command requires several flags to passthrough your GPUs (can be NVidia or AMD). You must have the kernel command line options `iommu=pt intel_iommu=on` (for Intel) to enable IOMMU/VT-d to get these GPUs to show up correctly in the VM.

## Running

1. Create your `rig.conf` as per the HiveOS website and put in `$(pwd)/hiveos-rig`
2. Run the following docker command (this will be interactive)

```bash
docker run -it \
  --restart unless-stopped \
  --name hiveos \
  -v $(pwd)/hiveos-rig:/hiveos-rig \
  --privileged \
  --device /dev/kvm \
  --device /dev/vfio/vfio \
  --device /dev/vfio/1 \
  -v /lib/modules:/lib/modules:ro \
  --ulimit memlock=-1:-1 \
  ghcr.io/lg/hiveos-docker
```

3. After the image creating and modifications are done, it should show up on your HiveOS Farm.
4. Exit your current `docker run` session (but keep things running with CTRL+P CTRL+Q)
4. To run in the background going forward, replace the `-it --rm` piece with `-d` and run it again.

## Pushing to github

```bash
docker build . -t ghcr.io/lg/hiveos-docker:TEMP_TAG
docker push ghcr.io/lg/hiveos-docker:TEMP_TAG
```

or

```bash
docker buildx build --platform linux/amd64 --push -t ghcr.io/lg/hiveos-docker:TEMP_TAG .
```