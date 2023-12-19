#!/bin/bash

# TODO: --splash

/usr/lib/systemd/ukify \
 --linux /boot/vmlinuz-linux \
 --initrd /boot/initramfs-linux.img \
 --initrd /boot/amd-ucode.img \
 --cmdline @/boot/cmdline.txt \
 --os-release @/etc/os-release \
 --uname "$(uname -r)" \
 --efi-arch x64 \
 --stub /usr/lib/systemd/boot/efi/linuxx64.efi.stub \
 --output /boot/EFI/BOOT/BOOTX64.EFI \
 build
