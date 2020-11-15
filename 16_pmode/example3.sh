#!/bin/sh

if (fasm example3.asm) 
then
    dd conv=notrunc if=example3.bin of=disk.img bs=446 count=1
    rm example3.bin
    bochs -f c.bxrc -q
fi

