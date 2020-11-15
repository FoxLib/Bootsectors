if (fasm kernel.asm)
then

    mv kernel.bin disk/kernel.bin
    bochs -f c.bxrc -q

fi
