# Retroid Pocket 6 LineageOS build

This repository contains the RP6 device tree and the Buildkite pipeline used to build it with the NTSync-enabled QCS8550 kernel.

## Buildkite setup

Run the pipeline on a Linux Buildkite agent with the Android 17/Lineage source tree and RP6 proprietary vendor files already present. The default source path is `/home/makin/retroid6-android17`; set `RP6_ANDROID_ROOT` on the agent if it differs. The agent needs the Android build dependencies, enough disk space for a full Android build, and the `buildkite-agent` CLI.

Add a Buildkite cluster secret named `RP6_NTSYNC_DEPLOY_KEY` containing a read-only SSH deploy key for `Pepelespooder/android_kernel_ayn_qcs8550_ntsync`. The pipeline uses it to fetch the `rp6-ntsync` branch during checkout. Keep the key and Buildkite API token in Buildkite's secret store; do not commit either value.

The pipeline copies this device tree into the Android source checkout, checks the NTSync config, builds `RP6`, and uploads generated ZIP and IMG files as Buildkite artifacts.
