# Ассемблировать boot-сектор
if (fasm main.asm)
then

    # Записать его на диск
    dd conv=notrunc if=main.bin of=../disk.img bs=446 count=1

    # Запустить bochs
    cd .. && bochs -f c.bxrc -q

fi

