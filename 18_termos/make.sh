#!/bin/sh

if (fasm main.asm)
then

    dd conv=notrunc if=main.bin of=disk.img bs=512 seek=1 count=64
    rm main.bin
    bochs -f bochs.bxrc -q

fi

