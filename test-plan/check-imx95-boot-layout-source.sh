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
neutron_append="$repo/recipes-libraries/tensorflow-lite/tensorflow-lite-neutron-delegate_2.16.2.bbappend"
tflite_append="$repo/recipes-framework/tensorflow/tensorflow-lite_2.16.1.bbappend"
g2d_samples_append="$repo/recipes-graphics/imx-g2d/imx-g2d-samples_%.bbappend"
machine_conf="$repo/conf/machine/imx95-frdm-evk.conf"
kas_smoke="$repo/kas/lmp-imx95-frdm-evk-6.12-partner.yml"
kas_v96="$repo/kas/lmp-v96-imx95-frdm-evk-6.12-partner.yml"
kas_accel="$repo/kas/lmp-v96-imx95-frdm-evk-6.12-partner-acceleration.yml"

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
grep -Fqx 'CONFIG_SECURITY_SELINUX=y' "$kernel_cfg"
grep -Fqx 'CONFIG_LSM="landlock,lockdown,yama,loadpin,safesetid,selinux,ipe,bpf"' "$kernel_cfg"
grep -Fqx 'CONFIG_CRYPTO_AES_ARM64_CE=y' "$kernel_cfg"
grep -Fqx 'CONFIG_CRYPTO_GHASH_ARM64_CE=y' "$kernel_cfg"
grep -Fqx 'CONFIG_CRYPTO_SHA2_ARM64_CE=y' "$kernel_cfg"
grep -Fqx 'CONFIG_IMX_ELE_TRNG=y' "$kernel_cfg"
grep -Fqx 'CONFIG_HW_RANDOM_OPTEE=y' "$kernel_cfg"

# Product display and Wi-Fi policy are deliberately machine-scoped.  FRDM is
# a station-only client, routine scan messages stay off the console, Weston
# uses NXP's DPU G2D path, and the Foundries splash is absent.
grep -Fq 'module_conf_moal:imx95-frdm-evk = "options moal mod_para=nxp/wifi_mod_para.conf drv_mode=1 drvdbg=0x6"' "$wifi_append"
if grep -Eq 'PACKAGECONFIG:(remove|append):imx95-frdm-evk.*(use-g2d|use-pixman)' "$weston_append"; then
    echo "FRDM overrides NXP's accelerated Weston renderer in $weston_append" >&2
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
grep -Fq 'meta-imx-sdk/recipes-fsl/fsl-rc-local/fsl-rc-local.bbappend' "$machine_conf"
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
