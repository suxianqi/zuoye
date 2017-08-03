#!/bin/bash
u=/dev/sdb

#1> 准备U盘 分区，格式化，设置为引导分区
  fdisk -l $u
  dd if=/dev/zero of=$u bs=500 count=1
  fdisk -cu $u <<EOF
n
p
1

a
1
p
w
EOF

  mkfs.ext4 "$u"1
  mkdir /mnt/usb
  mount "$u"1 /mnt/usb


#2> 安装文件系统与BASH程序，重要命令（工具）、基础服务
  mount /dev/cdrom /media
  echo "[iso] \n  baseurl=file:///media \n enabled=1 \n gpgcheck=0">>/etc/yum.repos.d/iso.repo
  mkdir -p /dev/shm/usb
  yum -y install filesystem bash coreutils passwd shadow-utils openssh-clients rpm yum net-tools bind-utils vim-enhanced findutils lvm2 util-linux-ng --installroot=/dev/shm/usb/
  cp -arv /dev/shm/usb/* /mnt/usb/


#3> 安装内核
  cp /boot/vmlinuz-2.6.32-279.el6.x86_64  /mnt/usb/boot/
  cp /boot/initramfs-2.6.32-279.el6.x86_64.img  /mnt/usb/boot/
  cp -arv /lib/modules/2.6.32-279.el6.x86_64/  /mnt/usb/lib/modules/


#4> 安装GRUB程序
rpm -ivh grub-0.97-77.el6.x86_64.rpm  --root=/mnt/usb/ --nodeps --force

#安装驱动:
grub-install --root-directory=/mnt/usb/  --recheck  $u

#定义grub.conf
  cp /boot/grub/grub.conf /mnt/usb/boot/grub/
  UUID=$(blkid "$u"1 |awk -F " " '{print $2 }' |sed 's/"//g')

  vim /mnt/usb/boot/grub/grub.conf <<EOF
default=0
timeout=5
splashimage=/boot/grub/splash.xpm.gz
title My USB System from hugo
        root (hd0,0)
        kernel /boot/vmlinuz-2.6.32-279.el6.x86_64 ro root=$UUID
        initrd /boot/initramfs-2.6.32-279.el6.x86_64.img
        selinux=0
EOF

#完善环境变量与配置文件:
cp /etc/skel/.bash* /mnt/usb/root/

#网络：
vim /mnt/usb/etc/sysconfig/network <<EOF
NETWORKING=yes
HOSTNAME=usb.hugo.org
EOF

cp /etc/sysconfig/network-scripts/ifcfg-eth0 /mnt/usb/etc/sysconfig/network-scripts/

echo " " >>/mnt/usb/etc/sysconfig/network-scripts/ifcfg-eth0
vim /mnt/usb/etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
DEVICE=eth0
BOOTPROTO=none
ONBOOT=yes
USERCTL=no
IPADDR=192.168.0.123
NETMASK=255.255.255.0
GATEWAY=192.168.0.254
EOF

vim /mnt/usb/etc/fstab <<EOF
$UUID ext4 defaults 0 0
sysfs                   /sys                    sysfs   defaults        0 0
proc                    /proc                   proc    defaults        0 0
tmpfs                   /dev/shm                tmpfs   defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
EOF

grub-md5-crypt <<EOF
123456
123456
EOF

sed -i  'root:*/c/root:$1$mcGxQ/$ii9Rs925VSaPy8HeVLewB.'  /mnt/usb/etc/shadow

#同步脏数据
sync

