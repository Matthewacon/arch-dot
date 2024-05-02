#!/bin/bash
#size of image in GB/10
IMAGE_SIZE_GB=35
DD_COUNT=$((($IMAGE_SIZE_GB * 1024 * 1024) / 10))

#create blank 8GB disk image
printf '[builder]: Creating disk image...\n'
dd if=/dev/zero bs=1024 count=$DD_COUNT of=arch-live-usb.img status=progress

#create GPT disk label and all partitions \
printf '[builder]: Creating partition scheme and layout...\n'
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk arch-live-usb.img
 g #create new gpt partition layout
 n #create new EFI system partition
 1
 2048
 1048610
 t #set partition type to EFI
 1
 #mark first partition as bootable
 M
 a
 r
 n #create new linux partition
 2
 1048611
 #enter newline to select default all remaining space
 p #print the in-memory partition table
 w #write the partition table
EOF
