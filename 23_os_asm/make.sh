#!/bin/sh

if (fasm main.asm >> /dev/null)
then

    mv main.bin floppy/boot.bin
    bochs -f a.bxrc -q
fi

