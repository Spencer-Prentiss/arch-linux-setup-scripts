#!/bin/sh
#
# mount /dev/sdb1 /mnt
# cp /mnt/scripts/* /tmp
# umount /mnt
# sh /tmp/arch-setup-1.sh
#
# References
#	https://www.tecmint.com/arch-linux-installation-and-configuration-guide/
#	https://fedoramagazine.org/managing-partitions-with-sgdisk/
#	http://www.infotinks.com/writing-new-partition-tables-via-sgdisk-gpt-and-sfdisk-mbr/
#	https://stackoverflow.com/questions/34515193/sed-pacman-conf-remove-for-multilib-include
#	http://sudoadmins.com/how-to-enable-networking-in-arch-linux-guide/


clear
echo
echo

# Get hostname
read -p "Enter hostname: " hostname

# Get sudo user
read -p "Enter username: " user

# Get password
read -s -p "Enter password: " pass

echo
echo
echo "Setting variables in secondary script"
sed -i "s/host_to_replace/$hostname/" /tmp/arch-setup-2.sh
sed -i "s/user_to_replace/$user/" /tmp/arch-setup-2.sh
sed -i "s/pass_to_replace/$pass/" /tmp/arch-setup-2.sh

echo "Enabling Network Time Protocols (NTP) and allow the system to update the time via the Internet"
echo -ne '\n' | timedatectl set-ntp true >nul

echo "Wiping all partitions from primary disk /dev/sda"
sgdisk -Z /dev/sda >nul

echo "Creating 512MB partition, change name to 'boot', change type to 'EFI System'"
sgdisk -n 1:0:1050623 /dev/sda >nul
sgdisk -c 1:boot /dev/sda >nul
sgdisk -t 1:ef00 /dev/sda >nul

echo "Creating 4096MB partition, change name to 'swap', change type to 'Linux swap'"
sgdisk -n 2:1050624:9439231 /dev/sda >nul
sgdisk -c 2:swap /dev/sda >nul
sgdisk -t 2:8200 /dev/sda >nul

echo "Creating partition with remainder of disk space, change name to 'root', change type to 'Linux filesystem'"
sgdisk -n 3:9439232 /dev/sda >nul
sgdisk -c 3:root /dev/sda >nul
sgdisk -t 3:8300 /dev/sda >nul

echo "Creating FAT32 filesystem on 'boot' partition"
mkfs.fat -F32 /dev/sda1 >nul 2>nul

echo "Creating EXT4 filesystem on 'root' partition"
mkfs.ext4 /dev/sda3 >nul 2>nul

echo "Creating swap filesystem on 'swap' partition"
mkswap /dev/sda2 >nul 2>nul

echo "Mounting 'root' partition"
mount /dev/sda3 /mnt

echo "Copying mount script to /mnt"
cp /tmp/arch-setup-2.sh /mnt/arch-setup-2.sh

echo "Initializing 'swap' partition"
swapon /dev/sda2 >nul 2>nul

echo "Enabling pacman multilib"
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

echo "Installing Arch Linux to mounted 'root' partition"
yes | pacstrap /mnt base base-devel linux linux-firmware nano vim >nul 2>nul

echo "Generating fstab"
genfstab -U -p /mnt >> /mnt/etc/fstab

echo "Tunneling into 'root' partition mounted in /mnt"
arch-chroot /mnt /arch-setup-2.sh

echo "Unmounting 'root' partition"
umount -a > /dev/null 2>&1 || /bin/true

echo "Rebooting"
reboot