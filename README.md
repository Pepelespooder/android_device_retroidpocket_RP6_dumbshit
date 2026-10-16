# Retroid Pocket 6 device tree

LineageOS device configuration for the Retroid Pocket 6. Device setup and manual build instructions are in the [LineageOS RP6 guide](https://wiki.lineageos.org/devices/RP6/).

## NTSync kernel

The kernel source and NTSync driver are maintained in the private [RP6 kernel repository](https://github.com/Pepelespooder/android_kernel_ayn_qcs8550_ntsync). Its `rp6-ntsync` branch is based on the LineageOS QCS8550 kernel and enables `CONFIG_NTSYNC` in the RP6 GKI configuration. This device tree adds the matching kernel config fragment through `TARGET_KERNEL_CONFIG_EXT`.

## GitHub Actions build

The `RP6 Android build` workflow can be started manually from the `lineage-24.0` branch. It runs on a self-hosted Linux runner with the `rp6-android` label and uses a pre-synced Lineage source tree containing the extracted RP6 and QCS8550 common vendor files.

Configure these repository settings before starting a build:

- Add the `NTSYNC_REPO_TOKEN` Actions secret using a fine-grained token with read-only Contents access to `Pepelespooder/android_kernel_ayn_qcs8550_ntsync`.
- Set the `RP6_ANDROID_ROOT` Actions variable to the synced Android source directory on the runner.

The workflow checks out the private kernel branch, updates the kernel project in the Android tree, builds RP6, and uploads produced ZIP and image files as a workflow artifact.
