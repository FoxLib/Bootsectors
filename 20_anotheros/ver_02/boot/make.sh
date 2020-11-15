# Ассемблировать boot-сектор
if (fasm boot.asm)
then

    # Записать его на диск
    dd conv=notrunc if=boot.bin of=../disk.img bs=446 count=1

    # Запустить bochs
    cd .. && bochs -f c.bxrc -q

fi

