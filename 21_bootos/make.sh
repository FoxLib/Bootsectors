#!/bin/sh

# ----------------------------------------------------------------------
# dd if=/dev/zero of=floppy.img count=2880
# sudo losetup -o 0 /dev/loop1 floppy.img
# sudo mkfs.fat -F12 /dev/loop1
# sudo losetup -d /dev/loop1
# sudo mount floppy.img -t vfat -o loop,rw,uid="`whoami`",sync,offset=$[0] floppy
# ----------------------------------------------------------------------

if (fasm main.asm >> /dev/null) 
then

    dd conv=notrunc if=main.bin of=floppy.img bs=512 count=1
    bochs -f a.bxrc -q

fi

