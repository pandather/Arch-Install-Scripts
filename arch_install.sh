#!/bin/bash
set BIOS=MBR
VERBOSE=1
if [ -d /sys/firmware/efi/efivars ]
then
    BIOS=EFI
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
echo 'Which disk would you like to store the EFI System Partition? (format `/dev/xxx`, 512MB+, blank if already partitioned): '
echo 'This should be the first partition on the disk, blank if already partitioned.'
read ESPDISK
[[ -n "$ESPDISK" ]] && fdisk $ESPDISK

echo I see these partitions:
fdisk $ESPDISK -l
echo 'Which partition is the ESP? (format `/dev/xxx#`): '
read ESP
[[ -z "$ESP" ]] && exit
export ESP
mkfs.fat -F32 $ESP


echo "Want to create a swap partition?"
echo '`no` means no, all else goes: '
read RESPONSE
if [ 'yes' == "${RESPONSE:-no}" ]
then
  echo Okay.
else
  lsblk
  echo 'Which disk would you like to use for swap? (format `/dev/xxx`, 512MiB+, blank if already partitioned): '
  read SWAPDISK
  [[ -n "$SWAPDISK" ]] && fdisk $SWAPDISK
  fdisk $SWAPDISK
  echo I see these partitions:
  fdisk $SWAPDISK -l
  echo 'Which partition is the swap? (format `/dev/xxx#`:) '
  read SWAP
  [[ -z "SWAP" ]] && exit
  mkswap $SWAP
  swapon $SWAP
fi


echo 'Which disk would you like to use for root? (btrfs, format `/dev/xxx`, blank if already partitioned): '
read ROOTDISK
[[ -n "$ROOTDISK" ]] && fdisk $ROOTDISK
echo I see these partitions:
fdisk $ROOTDISK -l
echo 'Which partition is your root? (format `/dev/xxx#`:) '
read ROOT
[[ -z "$ROOT" ]] && exit
mkfs.btrfs $ROOT

mkdir -p /mnt/arch
mount $ROOT /mnt/arch
mkdir /mnt/arch/efi
mount $ESP /mnt/arch/efi

[[ -n "$BIOS" ]] && [[ "${BIOS:-MBR}" == "EFI" ]] && pacstrap /mnt/arch base linux linux-firmware refind emacs

genfstab -U /mnt/arch >> /mnt/arch/etc/fstab

echo 'Now verify your fstab (in nano!)'

nano /mnt/arch/etc/fstab

echo '#!/bin/bash' > /mnt/arch/startup.sh
echo "ESP=$ESP" >> /mnt/arch/startup.sh
cat ./chroot-x86_64-btrfs-root-efi.sh >> /mnt/arch/startup.sh
chmod 755 /mnt/arch/startup.sh

arch-chroot /mnt/arch /startup.sh

umount -R /mnt/arch

echo 'bootable install created, want to reboot? [`yes` else exits]'
read RESPONSE
if [ 'yes' == "${RESPONSE:-no}" ]
then
  reboot
fi

