#!/bin/sh
# Reject i.MX8-style bootloader2 writes in the FRDM-IMX95 factory and OTA paths.

set -eu

repo=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
mfgdir="$repo/recipes-support/mfgtool-files/mfgtool-files/imx95-frdm-evk"
bootcmd="$repo/recipes-bsp/u-boot/u-boot-ostree-scr-fit/imx95-frdm-evk/boot.cmd"
factory_cfg="$repo/recipes-bsp/u-boot/u-boot-fio/imx95-frdm-evk/factory-fastboot.cfg"
mfgtool_cfg="$repo/recipes-bsp/u-boot/u-boot-fio/imx95-frdm-evk/mfgtool-fastboot.cfg"
kernel_cfg="$repo/recipes-kernel/linux/linux-lmp-fslc-imx/imx95-15x15-lpddr4x-frdm.cfg"
wifi_append="$repo/recipes-kernel/kernel-modules/kernel-module-nxp-wlan_%.bbappend"
weston_append="$repo/recipes-graphics/wayland/weston-init.bbappend"
partner_image="$repo/recipes-samples/images/lmp-partner-nxp-imx-image.inc"
factory_image_append="$repo/recipes-samples/images/lmp-factory-image.bbappend"
runtime_group="$repo/recipes-core/packagegroups/packagegroup-partner-nxp-imx95-runtime.bb"
validation_group="$repo/recipes-core/packagegroups/packagegroup-partner-nxp-imx95-validation.bb"
neutron_append="$repo/dynamic-layers/imx-machine-learning/recipes-libraries/tensorflow-lite/tensorflow-lite-neutron-delegate_2.16.2.bbappend"
tflite_append="$repo/dynamic-layers/imx-machine-learning/recipes-framework/tensorflow/tensorflow-lite_2.%.bbappend"
g2d_samples_append="$repo/recipes-graphics/imx-g2d/imx-g2d-samples_%.bbappend"
alsa_plugins_append="$repo/recipes-multimedia/alsa/imx-alsa-plugins_git.bbappend"
machine_conf="$repo/conf/machine/imx95-frdm-evk.conf"
kas_smoke="$repo/kas/lmp-imx95-frdm-evk-6.12-partner.yml"
kas_v96="$repo/kas/lmp-v96-imx95-frdm-evk-6.12-partner.yml"
kas_accel="$repo/kas/lmp-v96-imx95-frdm-evk-6.12-partner-acceleration.yml"
imx_boot_append="$repo/recipes-bsp/imx-mkimage/imx-boot_%.bbappend"
waydroid_append="$repo/recipes-support/waydroid/waydroid.bbappend"
frdm_fstab="$repo/recipes-core/base-files/base-files/imx95-frdm-evk/fstab"
fw_env_config="$repo/recipes-bsp/u-boot/u-boot-fio-2025.04/fw_env.config"
uboot_append="$repo/recipes-bsp/u-boot/u-boot-fio_%.bbappend"
env_recipe="$repo/recipes-bsp/u-boot/frdm-uboot-env-bootstrap.bb"
env_bootstrap="$repo/recipes-bsp/u-boot/frdm-uboot-env-bootstrap/frdm-uboot-env-bootstrap"
env_service="$repo/recipes-bsp/u-boot/frdm-uboot-env-bootstrap/frdm-uboot-env-bootstrap.service"
production_env_cfg="$repo/recipes-bsp/u-boot/u-boot-fio/imx95-frdm-evk/lmp-spl-fit.cfg"
production_boot_cfg="$repo/recipes-bsp/u-boot/u-boot-fio/imx95-frdm-evk/ostree-boot.cfg"

# libubootenv reads /mnt/boot/uboot.env on this machine.  Without an fstab
# automount, aktualizr-lite cannot reset bootcount or arm verified rollback.
grep -Eq '^/dev/mmcblk0p1[[:space:]]+/mnt/boot[[:space:]]+vfat[[:space:]]+[^[:space:]]*x-systemd\.automount' "$frdm_fstab"
grep -Eq '^/dev/mmcblk0p1[[:space:]]+/mnt/boot[[:space:]]+vfat[[:space:]]+[^[:space:]]*sync' "$frdm_fstab"
grep -Eq '^/mnt/boot/uboot\.env[[:space:]]+0x0000[[:space:]]+0x4000$' "$fw_env_config"
grep -Fq 'UBOOT_INITIAL_ENV:imx95-frdm-evk = "u-boot-initial-env"' "$uboot_append"
grep -Fq 'mkenvimage -s 0x4000' "$uboot_append"
grep -Fq 'do_install[depends] += "u-boot-fio:do_deploy"' "$env_recipe"
grep -Fq 'frdm-uboot-env-bootstrap' "$partner_image"
sh -n "$env_bootstrap"
grep -Fqx 'Before=bootcount.service aktualizr-lite.service' "$env_service"
grep -Fq 'ls "${mountpoint}" >/dev/null' "$env_bootstrap"
grep -Fq 'fw_printenv >/dev/null' "$env_bootstrap"
grep -Fq 'elif ! fw_printenv >/dev/null 2>&1; then' "$env_bootstrap"
grep -Fq 'current=$(fw_printenv -n "${name}" 2>/dev/null || true)' "$env_bootstrap"
grep -Fq '[ -n "${current}" ] || fw_setenv "${name}" "${value}"' "$env_bootstrap"
grep -Fq 'ensure_variable bootlimit 3' "$env_bootstrap"
grep -Fq 'RDEPENDS:${PN} += "u-boot-fw-utils"' "$env_recipe"
grep -Fqx '# CONFIG_ENV_IS_IN_MMC is not set' "$production_env_cfg"
grep -Fqx '# CONFIG_ENV_IS_NOWHERE is not set' "$production_env_cfg"
grep -Fqx 'CONFIG_ENV_IS_IN_FAT=y' "$production_env_cfg"
grep -Fqx 'CONFIG_ENV_FAT_DEVICE_AND_PART="0:1"' "$production_env_cfg"
grep -Fqx 'CONFIG_CMD_NVEDIT_INFO=y' "$production_env_cfg"
grep -Fq 'if env info -p -d -q; then env save; fi' "$production_boot_cfg"
grep -Fq 'LMP_BOOT_FIRMWARE_VERSION:imx95-frdm-evk = "3"' "$machine_conf"

for script in "$mfgdir/full_image.uuu.in" "$mfgdir/bootloader.uuu.in"; do
    # These dollar expressions are intentional literals from the UUU script.
    # shellcheck disable=SC2016
    grep -Fq 'mmc dev ${mmcdev} 1' "$script"
    # shellcheck disable=SC2016
    grep -Fq 'mmc write ${loadaddr} 0x0 ${boot_blkcnt}' "$script"
    # shellcheck disable=SC2016
    grep -Fq 'mmc dev ${mmcdev} 2' "$script"
    # shellcheck disable=SC2016
    grep -Fq 'mmc write ${loadaddr} 0x300 ${fit_blkcnt}' "$script"
    if grep -Eq 'flash bootloader(2)?(_s)? ' "$script"; then
        echo "unsafe i.MX8-style bootloader alias write in $script" >&2
        exit 1
    fi
done

grep -Fqx '# CONFIG_FSL_FASTBOOT_BOOTLOADER2 is not set' "$factory_cfg"
if grep -Fqx '# CONFIG_FSL_FASTBOOT_BOOTLOADER2 is not set' "$mfgtool_cfg"; then
    echo "unsafe recovery override changes the hardware-proven MX95 flash_all SPL" >&2
    exit 1
fi
grep -Fqx 'CONFIG_FSL_FASTBOOT_BOOTLOADER2_OFFSET=0x300' "$mfgtool_cfg"

# LmP provides OP-TEE through optee-os-fio.  A direct dependency on the
# upstream recipe makes BitBake reject the selected virtual provider before it
# can build either the Jaguar or FRDM image.
grep -Fqx 'DEPENDS:remove = "optee-os"' "$imx_boot_append"
grep -Fqx "DEPENDS += \"\${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'virtual/optee-os', '', d)}\"" "$imx_boot_append"
grep -Fq "virtual/optee-os:do_deploy" "$imx_boot_append"
if grep -Eq "(^|[[:space:]'\"])optee-os:do_deploy" "$imx_boot_append"; then
    echo "imx-boot task dependency bypasses the selected virtual OP-TEE provider" >&2
    exit 1
fi

# The factory layer may already have normalized the hook before the partner
# bbappend runs.  Both product overrides must accept that safe second pass.
test "$(grep -Fc "elif ! grep -qx 'lxc.hook.post-stop = /bin/true'" "$waydroid_append")" -eq 2
test "$(grep -Fc "if grep -qx 'lxc.hook.post-stop = /dev/null'" "$waydroid_append")" -eq 2

# Local unsigned SOTA builds must override the same scoped secure default used
# by the BSP.  An unqualified value silently leaves SPL_FIT_SIGNATURE_STRICT on.
for kas_config in "$kas_smoke" "$kas_v96"; do
    grep -Fq 'UBOOT_SIGN_ENABLE:sota:mx95-generic-bsp = "0"' "$kas_config"
    if grep -Eq '^[[:space:]]+UBOOT_SIGN_ENABLE = "0"' "$kas_config"; then
        echo "unscoped i.MX95 local signing override in $kas_config" >&2
        exit 1
    fi
done

# Generic SCMI pinctrl intentionally refuses fsl,imx95 machines.  Without the
# NXP adapter every pinctrl consumer (including GPIO and eMMC) defers forever.
grep -Fqx 'CONFIG_PINCTRL_IMX_SCMI=y' "$kernel_cfg"

# LmP uses the nft-backed iptables binaries.  Without these options the base
# iptables service exits 4 and Docker cannot create its bridge network.
grep -Fqx 'CONFIG_NF_TABLES=m' "$kernel_cfg"
grep -Fqx 'CONFIG_NFT_COMPAT=m' "$kernel_cfg"
grep -Fqx 'CONFIG_NFT_NAT=m' "$kernel_cfg"
grep -Fqx 'CONFIG_NFT_MASQ=m' "$kernel_cfg"

# The v96 standard kernel fragments omit the i.MX95 GPU and Wave6 codec even
# though their matching NXP userspace and firmware are present in the image.
grep -Fqx 'CONFIG_IMX_DPU_BLIT=y' "$kernel_cfg"
grep -Fqx 'CONFIG_FORCE_MAX_ZONEORDER=14' "$kernel_cfg"
grep -Fqx 'CONFIG_MALI_MIDGARD=y' "$kernel_cfg"
grep -Fqx 'CONFIG_MALI_CSF_SUPPORT=y' "$kernel_cfg"
grep -Fqx 'CONFIG_MXC_VIDEO_WAVE6_CTRL=m' "$kernel_cfg"
grep -Fqx 'CONFIG_MXC_VIDEO_WAVE6=m' "$kernel_cfg"
grep -Fqx 'CONFIG_VIDEO_IMX8_JPEG=m' "$kernel_cfg"
grep -Fqx 'CONFIG_SND_AUDIO_GRAPH_CARD2=m' "$kernel_cfg"
grep -Fqx 'CONFIG_ZRAM_BACKEND_LZ4=y' "$kernel_cfg"
grep -Fqx 'CONFIG_SECURITY_APPARMOR=y' "$kernel_cfg"
grep -Fqx 'CONFIG_DEFAULT_SECURITY_APPARMOR=y' "$kernel_cfg"
grep -Fqx 'CONFIG_LSM="landlock,lockdown,yama,loadpin,safesetid,apparmor,bpf"' "$kernel_cfg"
grep -Fqx 'CONFIG_CRYPTO_AES_ARM64_CE=y' "$kernel_cfg"
grep -Fqx 'CONFIG_CRYPTO_GHASH_ARM64_CE=y' "$kernel_cfg"
grep -Fqx 'CONFIG_CRYPTO_SHA2_ARM64_CE=y' "$kernel_cfg"
grep -Fqx 'CONFIG_IMX_ELE_TRNG=y' "$kernel_cfg"
grep -Fqx 'CONFIG_HW_RANDOM_OPTEE=y' "$kernel_cfg"

# Product display and Wi-Fi policy are deliberately machine-scoped.  FRDM is
# a station-only client, routine scan messages stay off the console, Weston
# uses the Mali GL path proven with Waydroid DMA-BUFs, and the Foundries splash
# is absent.
grep -Fq 'module_conf_moal:imx95-frdm-evk = "options moal mod_para=nxp/wifi_mod_para.conf drv_mode=1 drvdbg=0x6"' "$wifi_append"
grep -Eq 'PACKAGECONFIG:remove:imx95-frdm-evk[[:space:]]*=.*["[:space:]]use-g2d(["[:space:]]|$)' "$weston_append"
if grep -Eq 'PACKAGECONFIG:append:imx95-frdm-evk.*use-pixman' "$weston_append"; then
    echo "FRDM falls back to the software Weston renderer in $weston_append" >&2
    exit 1
fi
grep -Fq 'CORE_IMAGE_BASE_INSTALL:remove:imx95-frdm-evk = "psplash"' "$partner_image"
grep -Fq 'IMAGE_FEATURES:remove:imx95-frdm-evk = "splash"' "$partner_image"
grep -Fq 'require recipes-samples/images/lmp-partner-nxp-imx-image.inc' "$factory_image_append"

# The partner layer consumes NXP's pinned camera, Neutron and EdgeLock
# implementations.  Keep bring-up tools out of non-development images.
for kas_config in "$kas_smoke" "$kas_v96"; do
    grep -Fq 'meta-imx-sdk:' "$kas_config"
    grep -Fq 'meta-imx-ml:' "$kas_config"
done
grep -Fq 'imx95-neo-isp imx95-neutron imx95-ele-hsm' "$machine_conf"
grep -Fq 'PREFERRED_VERSION_gcc-arm-none-eabi-native = "14.2.rel1"' "$machine_conf"
grep -Fq 'meta-imx-sdk/recipes-fsl/fsl-rc-local/fsl-rc-local.bbappend' "$machine_conf"
grep -Fq 'EXTRA_OECONF:imx95-frdm-evk = ""' "$alsa_plugins_append"
grep -Fq 'CFLAGS:append:imx95-frdm-evk = " ${INCLUDE_DIR}"' "$alsa_plugins_append"
grep -Fq 'packagegroup-partner-nxp-imx95-runtime' "$partner_image"
grep -Fq "oe.utils.conditional('DEV_MODE', '1', 'packagegroup-partner-nxp-imx95-validation'" "$partner_image"
for package in imx-secure-enclave libcamera libcamera-gst neutron tensorflow-lite-neutron-delegate; do
    grep -Fq "    ${package} \\" "$runtime_group"
done
grep -Fq '0001-drop-source-directory-runpath.patch' "$neutron_append"
grep -Fq -- '-ffile-prefix-map=${WORKDIR}=' "$neutron_append"
grep -Fq 'tflite_runtime-${PV}.dist-info/direct_url.json' "$tflite_append"
grep -Fq '${libexecdir}/g2d-samples' "$g2d_samples_append"
for package in cryptodev-tests imx-g2d-samples media-ctl v4l-utils; do
    grep -Fq "    ${package} \\" "$validation_group"
done
for target in imx-secure-enclave libcamera neutron tensorflow-lite-neutron-delegate imx-g2d-samples; do
    grep -Fq "  - ${target}" "$kas_accel"
done

grep -Fq "setenv update_image_user '" "$bootcmd"
# shellcheck disable=SC2016
grep -Fq 'mmc dev ${devnum} 0 && mmc write ${loadaddr} ${start_blk} ${blkcnt}' "$bootcmd"
grep -Fq "setenv update_primary_image2 '" "$bootcmd"
grep -Fq 'run update_image_user' "$bootcmd"
if grep -F 'setenv update_primary_image2 ' "$bootcmd" | grep -Fq 'run update_image_boot0'; then
    echo "unsafe i.MX95 OTA FIT write to eMMC boot0 in $bootcmd" >&2
    exit 1
fi

echo 'PASS: FRDM-IMX95 boot layout, kernel, acceleration runtimes, display and station-only Wi-Fi policy are retained'
