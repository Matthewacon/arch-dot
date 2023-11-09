#!/bin/bash

# TODO:
# 1. Signing + SecureBoot
# 2. Pacman rebuild hooks (see arch-efiboot repo hook) 
# 3. --splash

/usr/lib/systemd/ukify \
 --linux /boot/vmlinuz-linux \
 --initrd /boot/initramfs-linux.img \
 --initrd /boot/amd-ucode.img \
 --cmdline @/boot/cmdline.txt \
 --os-release @/etc/os-release \
 --uname "$(uname -r)" \
 --efi-arch x64 \
 --stub /usr/lib/systemd/boot/efi/linuxx64.efi.stub \
 --output /boot/linux.efi \
 build
