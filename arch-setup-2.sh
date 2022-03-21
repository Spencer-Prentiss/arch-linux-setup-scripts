#!/bin/sh
#
# References
#	https://www.tecmint.com/arch-linux-installation-and-configuration-guide/
#	https://fedoramagazine.org/managing-partitions-with-sgdisk/
#	http://www.infotinks.com/writing-new-partition-tables-via-sgdisk-gpt-and-sfdisk-mbr/
#	https://stackoverflow.com/questions/34515193/sed-pacman-conf-remove-for-multilib-include
#	http://sudoadmins.com/how-to-enable-networking-in-arch-linux-guide/


hostname=host_to_replace
user=user_to_replace
pass=pass_to_replace

echo "Setting hostname"
echo $hostname > /etc/hostname
echo $hostname >> /etc/hosts

echo "Installing nano"
yes | pacman -S nano >nul 2>nul

echo "Configuring system language"
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen

echo "Generating system language layout"
locale-gen >nul
echo LANG=en_US.UTF-8 > /etc/locale.conf
export LANG=en_US.UTF-8

echo "Configuring system time zone"
ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime >nul 2>nul

echo "Configuring hardware clock to use UTC"
hwclock --systohc --utc

echo "Syncing and updating database mirrors"
yes | pacman -Syu >nul 2>nul

echo "Changing root password"
echo "root:$pass" | chpasswd

echo "Adding user"
useradd -mg users -G wheel,storage,power -s /bin/bash $user

echo "Changing user password"
echo "$user:$pass" | chpasswd

echo "Installing sudo and vim"
yes | pacman -S sudo >nul 2>nul
yes | pacman -S vim >nul 2>nul

echo "Allowing members of wheel group to execute any command"
sed -i "/%wheel ALL=(ALL) ALL/"'s/^# //' /etc/sudoers

echo "Installing GRUB and tools"
yes | pacman -S grub efibootmgr dosfstools os-prober mtools dhcpcd >nul 2>nul
mkdir /boot/EFI
mount /dev/sda1 /boot/EFI
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck >nul 2>nul

echo "Create GRUB configuration"
grub-mkconfig -o /boot/grub/grub.cfg >nul 2>nul

echo "Finding network adapter"
netadapter=$(ip -o link show | awk -F': ' '$1 == 2 {print $2}')

echo "Enabling $netadapter network adapter service"
systemctl enable dhcpcd@$netadapter.service >nul 2>nul

echo "Unmounting GRUB directory"
umount -a > /dev/null 2>&1 || /bin/true

echo "Installing Cinnamon"
yes | pacman -S cinnamon nemo-fileroller >nul 2>nul

echo "Exiting from mounted 'root' partition"
exit
