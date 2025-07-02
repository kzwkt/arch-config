wget https://pkgbuild.com/~morganamilo/pacman-static/x86_64/bin/pacman-static
#curl -O https://pkgbuild.com/~morganamilo/pacman-static/x86_64/bin/pacman-static
chmod +x pacman-static

cat <<EOF > pacman.conf
[options]
HoldPkg = pacman glibc
Architecture = auto
CheckSpace
CleanMethod = KeepInstalled

[core]
SigLevel = Never DatabaseOptional
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/core/os/\$arch

[extra]
SigLevel = Never DatabaseOptional
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/extra/os/\$arch
EOF

sudo mkdir /mnt/var/lib/pacman/ -p
sudo mkdir /mnt/etc
echo "nameserver 1.1.1.1" | sudo tee /mnt/etc/resolv.conf 
sudo ./pacman-static -Syu --config ./pacman.conf  --root /mnt
sudo ./pacman-static -Syu --config ./pacman.conf  --root /mnt base



mnt=/mnt

for dir in dev dev/pts proc sys; do
    mount --rbind /$dir "$mnt/$dir" && mount --make-rslave "$mnt/$dir"
done

sudo chroot "$mnt" /bin/bash

# select mirror 
# you could use reflector to select best mirror 
sed -i 's|^#Server = http://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch|Server = http://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch|' /etc/pacman.d/mirrorlist
sed -i 's|^#Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch|Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch|' /etc/pacman.d/mirrorlist

# keyring 
pacman-key --init
pacman-key --populate

# pkgs install
pacman -S nano
pacman -S base-devel
pacman -S plasma-desktop
pacman -S  linux intel-ucode  linux-firmware-atheros   linux-firmware-intel fwupd
pacman -S networkmanager plasma-nm iwd
pacman -S   bluedevil  breeze-gtk   kde-gtk-config  kinfocenter  kscreen   plasma-pa
pacman -S arch-install-scripts
pacman -S grub efibootmgr dosfstools
pacman -S sddm sddm-kcm 
pacman -S dolphin konsole  okular gwenview
pacman -S kdegraphics-thumbnailers  ffmpegthumbs

# set hostname, locale
echo "x" > /etc/hostname

cat <<EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   x.localdomain x
EOF

sed -i 's/^#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf
ln -sf /usr/share/zoneinfo/Asia/Kathmandu /etc/localtime

hwclock --systohc


cat <<EOF > /etc/NetworkManager/conf.d/wifi_backend.conf
[device]
wifi.backend=iwd
EOF

mkdir /boot/efi
mount /dev/sda1 /boot/efi

genfstab -U / > /etc/fstab

grub-install --target=x86_64-efi --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg

pacman -S sddm sddm-kcm 

mkdir -p /etc/sddm.conf.d

cat <<EOF > /etc/sddm.conf.d/10-wayland.conf
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1
EOF

 useradd -G wheel k
 passwd k 

 systemctl enable sddm


 sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

 

