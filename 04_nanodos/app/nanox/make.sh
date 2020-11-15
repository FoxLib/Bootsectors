if (fasm main.asm)
then

    mv main.com ../../disk/nanox.com
    cd ../.. && bochs -f c.bxrc -q

fi
