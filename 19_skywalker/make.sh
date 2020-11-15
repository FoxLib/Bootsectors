# sudo mount disk.img -t vfat -o loop,rw,uid="fox",sync,offset=$[1048576] disk/

if (fasm core.asm)
then
    mv core.bin disk/
    bochs -f c.bxrc -q
fi
