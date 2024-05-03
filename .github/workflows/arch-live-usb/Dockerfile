# syntax=docker/dockerfile:1-labs
#NOTE: We need to use the experimental buildkit dockerfile parser to get
#support for the `--security` RUN directive flag

#To build this image:
#docker -D buildx build . --allow security.insecure -t arch-live-usb:latest --build-arg CACHEBUST="$(date)" --progress=plain

#TODO: use a bind mount in the last step to copy the disk image out of the
#intermediate layer and then add an empty layer with absolutely nothing

FROM archlinux:latest AS base

WORKDIR /root

#override makepkg and pacman configurations
COPY files/etc/pacman.conf /etc/pacman.conf
COPY files/etc/makepkg.conf /etc/makepkg.conf

#install all prereqs
RUN pacman -Syu --noconfirm \
 dosfstools \
 util-linux \
 wget \
 rsync \
 base \
 base-devel \
 git \
 arch-install-scripts \
 sudo \
 go \
 archlinux-keyring

#override sudoers config
COPY files/etc/sudoers /etc/sudoers

#build and install yay
RUN /usr/bin/bash -c "\
 #create user \
 printf '[builder]: Creating user to build makepkg packages...\n' \
 && useradd matthew \
 && usermod -aG wheel matthew \
 && mkhomedir_helper matthew \
 && chown -R matthew:matthew /home/matthew \
 #build and install yay \
 && printf '[builder]: Building packages for new installation...\n' \
 && su matthew -c /usr/bin/bash -c \"\
  #create directory for all packages built that need to be copied to the new installation \
  cd \
  && mkdir -p installation_packages \
  #build and install yay \
  && printf '[builder]: Building and installing yay...\n' \
  && git clone --depth 1 https://aur.archlinux.org/yay.git \
  && cd yay \
  && makepkg -si --noconfirm \
  && sudo cp yay-*.pkg.tar /yay.pkg.tar \
 \"\
"

#build zfs-utils for new installation
FROM base AS base-zfs-utils
RUN su matthew -c /usr/bin/bash -c "\
 #build zfs-utils \
 printf '[builder]: Retrieving PKGBUILDs for zfs-utils...\n' \
 && cd \
 && yay --getpkgbuild zfs-utils \
 && printf '[builder]: Building zfs-utils...\n' \
 && cd zfs-utils \
 && makepkg -s --noconfirm --skippgpcheck \
 && sudo cp zfs-utils-*.pkg.tar /zfs-utils.pkg.tar \
"

#build zfs-dkms for new installation
FROM base AS base-zfs-dkms
RUN su matthew -c /usr/bin/bash -c "\
 #build zfs-dkms \
 printf '[builder]: Retrieving PKGBUILDs for zfs-dkms...\n' \
 && cd \
 && yay --getpkgbuild zfs-dkms \
 && printf '[builder]: Building zfs-dkms...\n' \
 && cd zfs-dkms \
 && makepkg -s --noconfirm --skippgpcheck \
 && sudo cp zfs-dkms-*.pkg.tar /zfs-dkms.pkg.tar \
"

#download linux packages
FROM base AS base-linux
RUN /usr/bin/bash -c "\
 #download linux packages \
 printf '[builder]: Downloading linux kernel packages for new installation...\n' \
 && mkdir -p /packages \
 && cd /packages \
 && wget -q https://archive.archlinux.org/packages/l/linux/linux-6.7.9.arch1-1-x86_64.pkg.tar.zst \
 && wget -q https://archive.archlinux.org/packages/l/linux-api-headers/linux-api-headers-6.7-1-any.pkg.tar.zst \
 && wget -q https://archive.archlinux.org/packages/l/linux-headers/linux-headers-6.7.9.arch1-1-x86_64.pkg.tar.zst \
"

#create minimum required directories to bootstrap a new installation
FROM base AS installation-builder
RUN /usr/bin/bash -c "\
 #create temporary installation directory \
 printf '[builder]: Setting up minimum required diretories for new installation...\n' \
 && mkdir -p /installation/built_packages \
 #set up required directories and devices for pacman \
 && mkdir -p /installation/usr/bin \
 && mkdir -m 0755 -p /installation/var/{cache/pacman/pkg,lib/pacman,log} /installation/{dev,run,etc} \
 && mkdir -m 1777 -p /installation/tmp \
 && mkdir -m 0555 -p /installation/{sys,proc} \
 && mknod /installation/dev/null c 1 3 \
"

#copy packages built above into new installation
COPY --from=base /yay.pkg.tar /installation/built_packages/
COPY --from=base-zfs-utils /zfs-utils.pkg.tar /installation/built_packages/
COPY --from=base-zfs-dkms /zfs-dkms.pkg.tar /installation/built_packages/
COPY --from=base-linux /packages/* /installation/built_packages/

#set up base installation
#NOTE: unprivileged installation bootstrap code taken from: https://github.com/lopsided98/archlinux-docker/blob/master/pacstrap-docker
RUN /usr/bin/bash -c "\
 #setup up arch base \
 printf '[builder]: Installing base system packages into new installation...\n' \
 && pacman -r /installation -Sy --noconfirm \
  base \
  base-devel \
  pacman \
  go \
  wget \
 #configure locales \
 && printf '[builder]: Configuring locales in new installation...\n' \
 && echo -e \"LANG=en_US.UTF-8\nLC_ALL=C\nLANGUAGE=en_US\" > /installation/etc/locale.conf \
 && echo -e \"en_US.UTF-8 UTF-8\" >> /installation/etc/locale.gen \
 #copy over pacman configuration and mirrorlist \
 && printf '[builder]: Copying pacman configuration and mirrorlist into new installation...\n' \
 && cp /etc/pacman.conf /installation/etc/ \
 && cp /etc/pacman.d/mirrorlist /installation/etc/pacman.d/ \
"

#copy configurations into installation
COPY files/etc/makepkg.conf /installation/etc/
COPY files/etc/sudoers /installation/etc/
COPY files/etc/mkinitcpio.conf /installation/etc/
COPY files/etc/mkinitcpio.d/linux.preset /installation/etc/mkinitcpio.d/linux.preset
#NOTE: fstab and efistub filesystem UUIDs are replaced in `finalize-disk-image.sh`
COPY files/etc/fstab /installation/etc/
COPY files/etc/efistub.conf /installation/etc/

#set up installation
RUN --security=insecure arch-chroot /installation /usr/bin/bash -c "\
 #generate locales \
 printf 'Generating locales...\n' \
 && locale-gen \
 #add user \
 && printf \"[installation]: Creating user 'matthew'...\n\" \
 && useradd matthew \
 && usermod -aG wheel matthew \
 && mkhomedir_helper matthew \
 && chown -R matthew:matthew /home/matthew \
 #initialize user gnupg database \
 && printf '[installation]: Initializing user 'matthew' gpg database...\n' \
 && su matthew -c /usr/bin/bash -c \"\
  cd \
  && gpg --refresh-keys \
 \"\
 #initialize root gnupg database\
 && printf '[installation]: Initializing root gpg database...\n' \
 && gpg --refresh-keys \
 #initialize pacman \
 && printf '[installation]: Initializing pacman keyring...\n' \
 && pacman-key --init \
 && pacman-key --populate archlinux \
 && pacman -Sy --noconfirm archlinux-keyring pacman \
 #setup reflector \
 && printf '[installation]: Configuring reflector...\n'\
 && pacman -S --noconfirm reflector \
 && reflector \
  --save /etc/pacman.d/mirrorlist \
  --country Canada,\"United States\" \
  --threads 32 \
  --protocol https \
  --fastest 15 \
  --latest 15 \
 && echo -e \"--save /etc/pacman.d/mirrorlist\n--country Canada,\"United States\"\n--threads 32\n--protocol https\n--fastest 15\n--latest 15\" > /etc/xdg/reflector/reflector.conf \
 && systemctl enable reflector \
 #install all packages copied over from builder \
 && printf '[installation]: Installing copied packages from builder...\n' \
 && pacman -U --noconfirm /built_packages/* \
 && rm -r /built_packages \
 #install extra system utilities and reinstall base utilities so that \
 #post-install hooks are run (pacman -r does not run post-install hooks) \
 && printf '[installation]: Installing extra packages...\n' \
 && pacman -S --noconfirm \
  base \
  base-devel \
  go \
  wget \
  llvm \
  clang \
  lldb \
  cmake \
  zsh \
  neovim \
  git \
  efibootmgr \
  dkms \
  arch-install-scripts \
  pv \
  pigz \
  sudo \
  dhcpcd \
  udisks2 \
  tmux \
  htop \
  openssh \
  dosfstools \
  systemd-ukify \
  sbsigntools \
  man-db \
  iw \
  wpa_supplicant \
  unzip \
  wireguard-tools \
  rsync \
  zstd \
  unzip \
  cryptsetup \
 #enable dhcpcd \
 && printf '[installation]: Enabling dhcpcd systemd service at boot...\n' \
 && systemctl enable dhcpcd \
 #create EFI boot directory \
 && printf '[installation]: Creating EFI boot directory...\n' \
 && mkdir -p /boot/EFI/BOOT \
 #install zfs, mkinitcpio, efistub \
 && printf '[installation]: Installing intel-ucode, mkinitcpio-firmware and efistub...\n' \
 && su matthew -c /usr/bin/bash -c \"\
  yay -Sy --noconfirm --sudoloop \
   intel-ucode \
   mkinitcpio-sd-zfs \
   mkinitcpio-firmware \
   arch-efistub-git \
 \"\
 #rebuild initramfs and efistub \
 && printf '[installation]: Rebuilding initramfs...\n' \
 && mkinitcpio -p linux \
 #clean up pacman and yay package caches \
 && printf '[installation]: Cleaning up package caches...\n' \
 && rm -r \
  /var/cache/pacman/pkg/* \
  /var/lib/pacman/sync/* \
  /home/matthew/.cache/yay/* \
"

#bust cache here so the loop device is always setup if the dockerfile is re-run
FROM installation-builder AS image-builder

#set up 8GB disk image
COPY files/make-disk-image.sh .
RUN ./make-disk-image.sh

ARG CACHEBUST

#build final image file
COPY files/finalize-disk-image.sh .
RUN --security=insecure ./finalize-disk-image.sh

#create minimum required directories to bootstrap an empty image with busybox
FROM base AS busybox-builder
RUN /usr/bin/bash -c "\
 #create temporary busybox directory \
 printf '[builder]: Setting up minimum required diretories for new busybox image...\n' \
 && mkdir -p /busybox \
 #set up required directories and devices for pacman \
 && mkdir -p /busybox/usr/bin \
 && mkdir -m 0755 -p /busybox/var/{cache/pacman/pkg,lib/pacman,log} /busybox/{dev,run,etc} \
 && mkdir -m 1777 -p /busybox/tmp \
 && mkdir -m 0555 -p /busybox/{sys,proc} \
 && mknod /busybox/dev/null c 1 3 \
 && pacman -r /busybox -Sy --noconfirm busybox \
"

#copy final image and busybox into empty layer
FROM scratch AS final
ENTRYPOINT ["/bin/busybox"]
CMD ["sh"]
COPY --from=image-builder /root/arch-live-usb.img /
COPY --from=busybox-builder /busybox/* /
