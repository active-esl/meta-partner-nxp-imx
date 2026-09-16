# Jaguar Screen R16 Waydroid boot and display test

Status: **bench hotpatch pass, 2026-09-16**. This is not a Foundries/OTA
acceptance pass. The test machine is `imx8mm-jaguar-screen-2210a09dab86563`
on the isolated `r16-jaguar-screen` target lane (host target 2943).

## Tested pair and observed result

- Android R16 / LineageOS 23.2 `arm64_2gb` `userdebug` images came from
  [CI run 35084191413](https://github.com/active-esl/waydroid-product-manifest/actions/runs/35084191413).
  `system.img` SHA-256 is
  `d03e25327e7cf588b70488b7aecf6d9b51403f50f3d00dd30f8b817371d213d4`;
  `vendor.img` SHA-256 is
  `8d8c2004c717ea32db044ae8f3b3a8cf66d5f5182b386d59d4d3312e1d373465`.
- The board's selected images and provisioning pin point to that R16 pair.
  Inactive R13/older R16 image copies were removed in development mode;
  they are **not** an on-board rollback set. `/var` had 5.0 GB free after
  provisioning. Before cleanup, `/var` was full and Android repeatedly
  crashed `system_server` in `NetworkStatsService` after `ENOSPC`.
- On a warm reboot observed through RustDesk, the Active-Edge splash remained
  while Android started; LineageOS then became visible without a manual
  compositor restart. Android reported `sys.boot_completed=1`, the session
  reported `waydroid.background_start=true`, and the UI service logged its
  one-time post-boot hardware-composer restart. Alex confirmed the visual
  transition. This proves the bench hotpatch, not the baked firmware.

## Expected boot sequence

1. Host boots and presents the Active-Edge splash. Waydroid starts in the
   background; an empty Android toplevel must not cover the splash.
2. `waydroid-jaguar-ui.service` requests full UI and waits for Android's
   `sys.boot_completed=1` via `waydroid-jaguar-present-after-boot`.
3. Once only, the hook restarts Android `vendor.hwcomposer-2-1` to create a
   visible Wayland toplevel; LineageOS replaces the splash. The hook fails
   visibly if boot never completes, rather than reporting a false pass.

## Reboot acceptance check

Watch the **physical panel or live camera/RustDesk feed** from reboot until
the first usable LineageOS screen. Record the times of splash, any black
interval, and first Lineage frame. A running container or
`sys.boot_completed=1` alone is not display acceptance.

On the board, collect one bounded evidence bundle after the visual result:

```sh
systemctl show -p ActiveState -p Result waydroid-jaguar-session.service waydroid-jaguar-ui.service
journalctl -b -u waydroid-jaguar-ui.service -n 30 -o cat
waydroid shell -- getprop sys.boot_completed
waydroid shell -- getprop waydroid.background_start
df -h /var
```

Pass requires the splash to remain intentional until Lineage appears, no
manual `setprop ctl.restart`, Android boot completion, a successful one-time
hook result, and enough `/var` space for Android writes. Retain **all** error
messages in CI/board evidence; do not filter errors to manufacture a pass.

If it stays black or on the splash after Android boot completion, capture
`journalctl -b -u waydroid-jaguar-ui.service -n 80 -o cat` and a bounded Android
crash log (`waydroid shell -- logcat -b crash -d -t 120`) before intervening.
Check `/var` capacity first; `ENOSPC` can make Android fail before display
handover. Do not repeatedly restart the composer or reboot an unchanged image.

## Remaining gates

- Build the partner-layer change into a successor Foundries target, deploy
  through the intended OTA path, remove the bench-only `/etc/systemd` and
  `/var/lib/waydroid/hotpatch` overrides, and repeat the reboot check.
- Separately verify cold boot, update/recovery boot, touch, Etnaviv GPU,
  V4L2 media, memory pressure and lifecycle. The warm-reboot display pass
  does not imply these gates passed or establish an R13 rollback on this board.
