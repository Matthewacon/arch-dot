#!/bin/bash

#NOTE: losetup does not work correctly inside of docker containers, so we need
#to manually setup child device nodes for each partition inside of a loop
#device

#[[exit handlers]]
#add an exit handler and defered exit stack to allow us to clean up devices
#created in this script under all circumstances
declare -a exit_handlers
handle_exit() {
 local i
 local handler
 for ((i=${#exit_handlers[*]} - 1; i > -1; i--)); do
  handler="${exit_handlers[$i]}"
  $handler
 done
 exit_handlers=()
}

push_exit_handler() {
 if [[ -z $1 ]]; then
  printf 'push_exit_handler(): missing name of exit callback!\n'
  exit -1
 fi
 exit_handlers[${#exit_handlers[*]}]=$1
}

trap handle_exit EXIT SIGTERM SIGKILL SIGQUIT
set -e

#[[parent loop device]]
#setup up loop device and child partitions
printf '[builder]: Setting up loop device...\n'
LOOP_DEVICE=$(losetup -f -P --show arch-live-usb.img)
printf '[builder]: Loop device "%s" created!\n' "$LOOP_DEVICE"

#register exit handler to clean up root loop device
destroy_loop_device() {
 printf '[builder]: Cleaning up loop device "%s"...\n' "$LOOP_DEVICE"
 losetup -d "$LOOP_DEVICE"
 if [[ $? -ne 0 ]]; then
  printf '[builder]: WARNING: Failed to clean up loop device "%s", you will have to do this manually!\n' "$LOOP_DEVICE"
 else
  printf '[builder]: Cleaned up loop device!\n'
 fi
}
push_exit_handler destroy_loop_device

#[[child loop devices]]
#find partitions inside of loop device (if any)
LOOP_PARTITIONS=$(lsblk --raw --output "MAJ:MIN" --noheadings "$LOOP_DEVICE" | tail -n +2)

#register exit handler to clean up all child loop devices
declare -a child_loop_devices
push_child_loop_device() {
 if [[ -z $1 ]]; then
  printf 'push_child_loop_device(): missing path for child loop device!\n'
  exit -1
 fi
 child_loop_devices[${#child_loop_devices[*]}]=$1
}

clean_up_child_loop_devices() {
 local i
 local child_loop_device
 for ((i=${#child_loop_devices[*]} - 1; i >= 0; i--)); do
  child_loop_device=${child_loop_devices[$i]}
  printf '[builder]: Cleaning up child loop device "%s"...\n' "$child_loop_device"
  rm "$child_loop_device"
  if [[ $? -ne 0 ]]; then
   printf '[builder]: WARNING: Failed to clean up child loop device "%s", you will have to do this manually!\n' "$child_loop_device"
  else
   printf '[builder]: Cleaned up child loop device!\n'
  fi
 done
 child_loop_devices=()
}
push_exit_handler clean_up_child_loop_devices

#set up devices for each partition
set_up_child_loop_devices() {
 local i=1
 local maj
 local min
 local child_device_name
 for partition in $LOOP_PARTITIONS; do
  maj=$(echo $partition | cut -d: -f1)
  min=$(echo $partition | cut -d: -f2)
  if [[ ! -e "${LOOP_DEVICE}p${i}" ]]; then
   child_device_name="${LOOP_DEVICE}p${i}"
   printf '[builder]: Setting up child loop device partition "%s"...\n' "$child_device_name"
   mknod "${child_device_name}" b $maj $min
   printf '[builder]: Child loop device "%s" created!\n' "$child_device_name"
   push_child_loop_device "${child_device_name}"
  fi
  i=$((i + 1))
 done
}
set_up_child_loop_devices

#[[create filesystems on loop device partitions]]
printf '[builder]: Creating EFI FAT32 filesystem...\n'
EFI_PARTITION="${LOOP_DEVICE}p1"
mkfs.fat -F32 "$EFI_PARTITION"

printf '[builder]: Creating root EXT4 filesystem...\n'
ROOT_PARTITION="${LOOP_DEVICE}p2"
mkfs.ext4 "$ROOT_PARTITION"

#[[mount filesystems]]
#mount root partition
printf '[builder]: Mounting root partition...\n'
clean_up_root_partition() {
 printf '[builder]: Unmounting root partition...\n'
 umount "$ROOT_PARTITION"
 printf '[builder]: Umounted root partition!\n'
}
mount "$ROOT_PARTITION" /mnt
push_exit_handler clean_up_root_partition
printf '[builder]: Mounted root partition!\n'

#mount efi partition
printf '[builder]: Mounting EFI partition...\n'
clean_up_efi_partition() {
 printf '[builder]: Unmounting EFI partition...\n'
 umount "$EFI_PARTITION"
 printf '[builder]: Umounted EFI partition!\n'
}
mkdir -p /mnt/boot
mount "$EFI_PARTITION" /mnt/boot
push_exit_handler clean_up_efi_partition
printf '[builder]: Mounted EFI partition!\n'

#[[configure fstab and efistub]]
#setup fstab
printf '[builder]: Configuring fstab in installation...\n'
EFI_UUID=$(blkid -s UUID -o value "${EFI_PARTITION}")
ROOT_UUID=$(blkid -s UUID -o value "${ROOT_PARTITION}")
sed -i -e "s/EFI_UUID/$EFI_UUID/g" /installation/etc/fstab
sed -i -e "s/ROOT_UUID/$ROOT_UUID/g" /installation/etc/fstab

#configure efistub
printf '[builder]: Configuring efistub in installation...\n'
sed -i -e "s/ROOT_UUID/$ROOT_UUID/g" /installation/etc/efistub.conf

#rebuild initramfs and efistub
printf '[builder]: Rebuilding initramfs and efistub...\n'
arch-chroot /installation /usr/bin/bash -c "\
 mkinitcpio -p linux \
 && efistub \
"

#[[copy installation into final image]]
printf '[builder]: Copying installation to destination filesystems...\n'
du -hs /installation
rsync -aq --info=progress2 --info=name0 /installation/* /mnt
printf '[builder]: Finished copying installation to destination filesystems!\n'
