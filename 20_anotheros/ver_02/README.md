# Preamble
Bochs-oriented OS for older computers and fun

* This OS supports for 386-486SX processors.
* IDE Controller supports for Hard Drive.
* SATA not support
* ACPI not support
* PCI not support
* VESA BIOS LFB on startup only
* OS written just for fun.

# How install it

First, install bochs with config:

1. ./configure --enable-x86-64 --enable-debugger --enable-disasm --enable-readline --with-all-libs --with-x11
2. make
3. make install
4. Configure *.bxrc file with it:

  display_library: x, options="gui_debug"
  magic_break: enabled=1
  boot: disk
  
5. dd if=/dev/zero of=disk.img bs=1024 count=262144
6. fdisk disk.img
7. Commands: n / p / 1 / 2048 / 524287 / t / 06 / w
8. losetup -o 1048576 /dev/loop1 disk.img
9. mkfs.fat -F16 /dev/loop1
10. losetup -d /dev/loop1
11. mkdir disk
12. sudo mount disk.img -t vfat -o loop,rw,uid="`whoami`",sync,offset=$[1048576] disk/

# Special notes

P.S. На русском.
