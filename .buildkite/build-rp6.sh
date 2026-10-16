#!/usr/bin/env bash
set -euo pipefail

checkout_root="${BUILDKITE_BUILD_CHECKOUT_PATH:-$(git rev-parse --show-toplevel)}"
android_root="${RP6_ANDROID_ROOT:-/home/makin/retroid6-android17}"
android_root="$(realpath -e "$android_root")"
device_tree="$android_root/device/retroidpocket/RP6"
kernel_tree="$android_root/kernel/ayn/qcs8550"

test -f "$android_root/build/envsetup.sh" || { echo "Android source tree missing at $android_root"; exit 1; }
test -d "$android_root/.repo" || { echo "Android source tree has no .repo metadata"; exit 1; }
test -d "$android_root/vendor/retroidpocket/RP6/proprietary" || { echo "RP6 proprietary vendor files are missing"; exit 1; }
test -d "$android_root/vendor/ayn/qcs8550-common/proprietary" || { echo "QCS8550 common proprietary vendor files are missing"; exit 1; }
test -d "$device_tree" || { echo "RP6 device tree path is missing"; exit 1; }
test -f "$kernel_tree/.git" || test -d "$kernel_tree/.git" || { echo "Kernel project checkout is missing"; exit 1; }

if [ "$(realpath -e "$checkout_root")" != "$(realpath -e "$device_tree")" ]; then
    rsync -a --delete --exclude='.git' "$checkout_root/" "$device_tree/"
fi

while IFS= read -r status_line; do
    path="${status_line:3}"
    case "$path" in
        Documentation/userspace-api/index.rst|Documentation/userspace-api/ntsync.rst|arch/arm64/configs/vendor/moorechip/kalama_GKI.config|drivers/misc/Kconfig|drivers/misc/Makefile|drivers/misc/ntsync.c|include/uapi/linux/ntsync.h) ;;
        *) echo "Unexpected local kernel change: $path"; exit 1 ;;
    esac
done < <(git -C "$kernel_tree" status --porcelain)

private_kernel="$(mktemp -d "${TMPDIR:-/tmp}/rp6-kernel.XXXXXX")"
private_key="$private_kernel/id_ed25519"
known_hosts="$private_kernel/known_hosts"
trap 'rm -rf "$private_kernel"' EXIT
buildkite-agent secret get RP6_NTSYNC_DEPLOY_KEY > "$private_key"
chmod 600 "$private_key"
curl --fail --silent --show-error https://api.github.com/meta | python3 -c \
    'import json,sys; print("\n".join("github.com " + key for key in json.load(sys.stdin)["ssh_keys"]))' \
    > "$known_hosts"
chmod 600 "$known_hosts"
export GIT_SSH_COMMAND="ssh -i $private_key -o IdentitiesOnly=yes -o UserKnownHostsFile=$known_hosts -o StrictHostKeyChecking=yes"

git clone --quiet --depth 1 --branch rp6-ntsync \
    git@github.com:Pepelespooder/android_kernel_ayn_qcs8550_ntsync.git \
    "$private_kernel/source"

git -C "$kernel_tree" fetch --no-tags "$private_kernel/source" rp6-ntsync
git -C "$kernel_tree" checkout --detach --force FETCH_HEAD

grep -q '^CONFIG_NTSYNC=y$' "$device_tree/configs/kernel/ntsync.config"
grep -q '^CONFIG_NTSYNC=y$' "$kernel_tree/arch/arm64/configs/vendor/moorechip/kalama_GKI.config"

cd "$android_root"
source build/envsetup.sh
brunch RP6

product="$android_root/out/target/product/RP6"
mapfile -t artifacts < <(find "$product" -maxdepth 1 -type f \( -name '*.zip' -o -name '*.img' \) -print)
test "${#artifacts[@]}" -gt 0 || { echo "No flashable package or images were produced"; exit 1; }
buildkite-agent artifact upload "${artifacts[@]}"
