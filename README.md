Device tree for the Retroid Pocket 6

Information about the device, build and install instructions can be found [here](http://wiki.lineageos.org/devices/RP6/)

## NTSync

The RP6 kernel source is maintained separately from this device tree. Apply the included kernel patch from the Android source root before building:

```sh
git apply --directory=kernel/ayn/qcs8550 device/retroidpocket/RP6/patches/kernel/ntsync.patch
```

The device tree adds `CONFIG_NTSYNC=y` through `configs/kernel/ntsync.config` when building the RP6 kernel. The driver source must be present in the kernel tree for this configuration option to take effect.
