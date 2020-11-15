#!/bin/sh

# dd conv=notrunc if=boot.bin of=/dev/sdX bs=446 count=1

if (fasm boot.asm >> /dev/null) 
then

    dd conv=notrunc if=boot.bin of=../../disk.img bs=446 count=1
    # rm boot.bin
    cd ../.. && bochs -f c.bxrc -q

fi

