#!/bin/bash

VERBOSE=1
if [ -s /sys/firmware/efi/efivars ]
then
    BIOS=EFI
    export BIOS
else
  echo 'script unfully implemented bc no efi modules are present, exiting...'
  exit
  echo 'No EFI modules present, do you still want to proceed? [`no` to exit]: '
  read RESPONSE
  if [ 'no' == $RESPONSE ]
  then
    exit
  fi
fi

echo "Let's begin.\n\nStop the script if you aren't connected to the internet...\n"

timedatectl set-ntp true


echo We have the following disks:
lsblk
echo '-----'
echo 'Which disk would you like to store the EFI System Partition? (format `/dev/xxx`): '
echo 'This should be the first partition on the disk, GPT is required for the script.'
read ESPDISK
fdisk $ESPDISK

echo I see these partitions:
fdisk $ESPDISK -l
echo 'Which partition is the ESP? (format `/dev/xxx#`, 512MiB+:) '
read ESP
export ESP
mkfs.fat -F32 $ESP


echo "Want to create a swap partition?"
echo '`no` means no, all else goes: '
read RESPONSE
if [ 'no' != $RESPONSE ]
then
  lsblk
  echo 'Which disk would you like to use for swap? (format `/dev/xxx`, 512MiB+): '
  read SWAPDISK
  fdisk $SWAPDISK
  echo I see these partitions:
  fdisk $SWAPDISK -l
  echo 'Which partition is the swap? (format `/dev/xxx#`:) '
  read SWAP
  mkswap $SWAP
  swapon $SWAP
fi


echo 'Which disk would you like to use for root? (btrfs, format `/dev/xxx`): '
read ROOTDISK
fdisk $ROOTDISK
echo I see these partitions:
fdisk $ROOTDISK -l
echo 'Which partition is your root? (format `/dev/xxx#`:) '
read ROOT
mkfs.btrfs $ROOT

mkdir -p /mnt/arch
mount $ROOT /mnt/arch
mkdir /mnt/arch/efi
mount $ESP /mnt/arch/efi


if [ 'EFI' = $BIOS ]
then
    pacstrap /mnt/arch base linux linux-firmware refind emacs
else
    pacstrap /mnt/arch base linux linux-firmware grub emacs
fi


genfstab -U /mnt >> /mnt/arch/etc/fstab

echo Now verify your fstab (in vi!)

vi /mnt/arch/etc/fstab





arch-chroot /mnt/arch
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc

echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
locale-gen

echo 'LANG=en_US.UTF-8' > /etc/locale.conf

echo 'What is my hostname: '
read HOSTNAME
echo $HOSTNAME > /etc/hostname

echo 'What domain am I on: '
read DOMAINNAME

echo "Do you have a static IP address?"
echo '`no` means no, all else uses 127.0.1.1: '
STATICADDR=127.0.0.1
read RESPONSE
if [ 'no' != $RESPONSE ]
then
  echo 'Which IP address would you like to use: '
  read STATICADDR
fi

echo "127.0.0.1	localhost" > /etc/hosts
echo "::1	localhost" >> /etc/hosts
echo "$STATICADDR	$HOSTNAME.$DOMAINNAME	$HOSTNAME" >> /etc/hosts

echo \n---\nNow time to set your root password: \n
passwd

if [ 'EFI' = $BIOS ]
then
    refind-install --usedefault $ESP
else
    echo Install grub manually.
    exit
fi

exit
umount -R /mnt/arch

echo 'bootable install created, want to reboot? [`yes` else exits]'
read RESPONSE
if [ 'yes' == $RESPONSE ]
then
  reboot
fi
