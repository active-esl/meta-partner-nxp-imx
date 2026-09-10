#!/bin/sh
# Non-destructive FRDM-IMX95 interface evidence collector.
# Run as root, or as the fio user with passwordless sudo for the inspected commands.

set -u

require_hdmi=0
require_waydroid=0
require_wifi=0
require_eth1=0

usage() {
    echo "usage: $0 [--require-hdmi] [--require-waydroid] [--require-wifi] [--require-second-ethernet]"
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --require-hdmi) require_hdmi=1 ;;
        --require-waydroid) require_waydroid=1 ;;
        --require-wifi) require_wifi=1 ;;
        --require-second-ethernet) require_eth1=1 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
    shift
done

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    echo "Run as root or install sudo" >&2
    exit 2
fi

pass=0 fail=0 info=0 skip=0
P() { pass=$((pass + 1)); }
F() { fail=$((fail + 1)); }
I() { info=$((info + 1)); }
S() { skip=$((skip + 1)); }
row() { printf '| %s | %s | **%s** |\n' "$1" "$2" "$3"; }
header() { printf '\n## %s\n\n| Check | Evidence | Result |\n|---|---|---|\n' "$1"; }
present() {
    if [ -e "$1" ]; then row "$2" "\`$1\`" PASS; P; else row "$2" "missing: \`$1\`" FAIL; F; fi
}
conditional() {
    # conditional DESCRIPTION REQUIRED(0/1) SHELL-COMMAND
    desc=$1 required=$2 command=$3
    if sh -c "$command" >/dev/null 2>&1; then
        row "$desc" "detected" PASS; P
    elif [ "$required" -eq 1 ]; then
        row "$desc" "not detected (required for this run)" FAIL; F
    else
        row "$desc" "not detected / peripheral not fitted" SKIP; S
    fi
}

printf '# FRDM-IMX95 interface test\n\n'
printf -- '- UTC: `%s`\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf -- '- Host: `%s`\n' "$(hostname)"
printf -- '- Kernel: `%s`\n' "$(uname -r)"

header "1. Platform and boot baseline"
model=$(tr -d '\000' </proc/device-tree/model 2>/dev/null || true)
case "$model" in
    *FRDM*i.MX*95*|*i.MX*95*FRDM*) row "Device-tree model" "\`$model\`" PASS; P ;;
    *) row "Device-tree model" "\`${model:-unavailable}\`" FAIL; F ;;
esac
case "$(uname -r)" in
    6.12*) row "Aligned Linux baseline" "\`$(uname -r)\`" PASS; P ;;
    *) row "Aligned Linux baseline" "\`$(uname -r)\` (expected 6.12.x)" FAIL; F ;;
esac
mt=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
if [ "${mt:-0}" -ge 7000000 ]; then row "8 GiB LPDDR4X" "MemTotal=${mt} kB" PASS; P; else row "8 GiB LPDDR4X" "MemTotal=${mt:-0} kB" FAIL; F; fi
if $SUDO journalctl -k -b 0 2>/dev/null | grep -qiE 'kernel panic|oops:|watchdog.*reset|Unhandled fault'; then
    row "Fatal kernel faults this boot" "fault signature found in journal" FAIL; F
else
    row "Fatal kernel faults this boot" "none found" PASS; P
fi
present /dev/tee0 "OP-TEE client device"

header "2. Foundries update and container surfaces"
conditional "OSTree deployment" 1 "test -d /ostree/deploy && ostree admin status"
conditional "U-Boot environment" 1 "$SUDO fw_printenv bootcount"
conditional "Docker daemon" 1 "$SUDO docker info"
if systemctl list-unit-files aktualizr-lite.service >/dev/null 2>&1; then
    row "aktualizr-lite unit" "installed; registration state is product-specific" PASS; P
else
    row "aktualizr-lite unit" "missing" FAIL; F
fi

header "3. eMMC and microSD"
emmc=""
for b in /sys/block/mmcblk[0-9]*; do
    [ -d "$b" ] || continue
    [ "$(cat "$b/device/type" 2>/dev/null)" = MMC ] && { emmc=$b; break; }
done
if [ -n "$emmc" ]; then row "32 GB eMMC" "\`/dev/$(basename "$emmc")\`" PASS; P; else row "eMMC" "not found" FAIL; F; fi
mmchosts=$(find /sys/class/mmc_host -mindepth 1 -maxdepth 1 -type l 2>/dev/null | wc -l)
if [ "$mmchosts" -ge 3 ]; then row "USDHC hosts" "$mmchosts (eMMC, microSD, IW612 SDIO)" PASS; P; else row "USDHC hosts" "$mmchosts (expected at least 3)" FAIL; F; fi
conditional "Inserted microSD card" 0 "for b in /sys/block/mmcblk[0-9]*; do test -d \"\$b\" || continue; test \"\$(cat \"\$b/device/type\" 2>/dev/null)\" = SD && exit 0; done; exit 1"

header "4. Display, GPU and Waydroid"
conditional "DRM card" 1 "find /dev/dri -maxdepth 1 -name 'card*' | grep -q ."
connector=""
for c in /sys/class/drm/card*-HDMI-A-*/status; do [ -f "$c" ] && { connector=$c; break; }; done
if [ -n "$connector" ]; then
    state=$(cat "$connector")
    mode=$(head -1 "$(dirname "$connector")/modes" 2>/dev/null || true)
    if [ "$state" = connected ]; then row "HDMI monitor" "\`$state\`, mode \`${mode:-unknown}\`" PASS; P
    elif [ "$require_hdmi" -eq 1 ]; then row "HDMI monitor" "\`$state\` (required)" FAIL; F
    else row "HDMI monitor" "\`$state\`" INFO; I; fi
elif [ "$require_hdmi" -eq 1 ]; then row "HDMI DRM connector" "absent (required)" FAIL; F
else row "HDMI DRM connector" "absent" INFO; I; fi
conditional "Weston compositor" "$require_hdmi" "systemctl is-active --quiet weston"
conditional "DRM render node" "$require_hdmi" "test -e /dev/dri/renderD128"
waydroid_cmd="command -v waydroid >/dev/null 2>&1 || systemctl list-unit-files 2>/dev/null | grep -q '^waydroid-container'"
conditional "Waydroid userspace/container" "$require_waydroid" "$waydroid_cmd"
if [ -d /dev/binderfs ] || [ -e /dev/binder ]; then row "Android binder surface" "present" PASS; P
elif [ "$require_waydroid" -eq 1 ]; then row "Android binder surface" "absent" FAIL; F
else row "Android binder surface" "absent; Waydroid not required for this image" SKIP; S; fi

header "5. Ethernet and wireless"
for iface in end0 end1; do
    required=0; [ "$iface" = end0 ] && required=1; [ "$iface" = end1 ] && required=$require_eth1
    if ip link show "$iface" >/dev/null 2>&1; then
        carrier=$(cat "/sys/class/net/$iface/carrier" 2>/dev/null || echo 0)
        if [ "$carrier" = 1 ]; then row "$iface NETC Ethernet" "carrier up" PASS; P
        elif [ "$required" -eq 1 ]; then row "$iface NETC Ethernet" "present, no carrier" FAIL; F
        else row "$iface NETC Ethernet" "present, no cable" INFO; I; fi
    elif [ "$required" -eq 1 ]; then row "$iface NETC Ethernet" "interface missing" FAIL; F
    else row "$iface NETC Ethernet" "interface missing" INFO; I; fi
done
wifi_if=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2; exit}')
if [ -n "$wifi_if" ]; then
    modules=$(lsmod | awk '$1=="moal" || $1=="mlan"{print $1}' | paste -sd, -)
    row "IW612 Wi-Fi" "\`$wifi_if\`, modules \`${modules:-built-in/unknown}\`" PASS; P
elif [ "$require_wifi" -eq 1 ]; then row "IW612 Wi-Fi" "no wireless interface" FAIL; F
else row "IW612 Wi-Fi" "no interface; module/card not required for this run" SKIP; S; fi
conditional "Bluetooth HCI" "$require_wifi" "test -d /sys/class/bluetooth/hci0"
conditional "IEEE 802.15.4 PHY" 0 "test -n \"\$(find /sys/class/ieee802154 -mindepth 1 -maxdepth 1 2>/dev/null | head -1)\""

header "6. USB, PCIe, CAN and audio"
conditional "USB 2.0 root hub" 1 "lsusb | grep -q 'root hub'"
conditional "USB 3.x controller" 1 "find /sys/bus/platform/drivers -maxdepth 2 -type l 2>/dev/null | grep -qE 'dwc3|xhci'"
conditional "M.2 Key-M PCIe link/device" 0 "lspci 2>/dev/null | grep -q ."
can_count=$(ip -details link show type can 2>/dev/null | grep -c '^[0-9]')
if [ "$can_count" -ge 2 ]; then row "CAN controllers" "$can_count interfaces" PASS; P
else row "CAN controllers" "$can_count interfaces (transceiver loopback requires bench wiring)" INFO; I; fi
cards=$(find /sys/class/sound -maxdepth 1 -name 'card*' 2>/dev/null | wc -l)
if [ "$cards" -ge 2 ]; then row "MQS/PDM/HDMI audio cards" "$cards cards" PASS; P; else row "Audio cards" "$cards" FAIL; F; fi

header "7. Board management and sensors"
conditional "External PCF2131 RTC" 1 "grep -qi pcf2131 /sys/class/rtc/rtc*/name"
conditional "GPIO expander PCAL6524" 1 "find /sys/bus/i2c/drivers -path '*/pca953x/*-*' -type l | grep -q ."
conditional "PCA963x LED controller" 1 "find /sys/class/leds -mindepth 1 -maxdepth 1 | grep -qi backlight"
conditional "On-board EEPROM nvmem" 1 "find /sys/bus/nvmem/devices -mindepth 1 -maxdepth 1 | grep -qi eeprom"
conditional "ADC IIO device" 1 "find /sys/bus/iio/devices -maxdepth 1 -name 'iio:device*' | grep -q ."
conditional "Thermal zones" 1 "find /sys/class/thermal -maxdepth 1 -name 'thermal_zone*' | grep -q ."
present /dev/watchdog0 "Hardware watchdog"

header "8. Accelerators, media and companion cores"
conditional "eIQ Neutron NPU" 1 "find /dev /sys -maxdepth 4 2>/dev/null | grep -qiE 'ethosu|neutron'"
conditional "VPU/media device" 1 "find /dev -maxdepth 1 2>/dev/null | grep -qE '/dev/video[0-9]+|/dev/mxc_vpu'"
conditional "Camera sensor/media graph" 0 "command -v media-ctl >/dev/null 2>&1 && media-ctl -p 2>/dev/null | grep -qiE 'imx|os08|ap1302|camera'"
rp=$(find /sys/class/remoteproc -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
if [ "$rp" -ge 1 ]; then row "Remoteproc controllers (M7/M33)" "$rp controller(s)" PASS; P; else row "Remoteproc controllers" "none" FAIL; F; fi
conditional "RPMsg endpoint/bus" 0 "test -d /sys/bus/rpmsg && find /sys/bus/rpmsg/devices -mindepth 1 -maxdepth 1 | grep -q ."

printf '\n## Summary\n\n'
printf -- '- PASS: **%d**\n- FAIL: **%d**\n- INFO: **%d**\n- SKIP: **%d**\n' "$pass" "$fail" "$info" "$skip"
[ "$fail" -eq 0 ]
