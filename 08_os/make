#!/bin/sh

# Ассемблирование ядра
gcc -S -Os -m32 -masm=intel -nostdlib -nostdinc -fno-stack-protector -fno-asynchronous-unwind-tables -c kernel.c

# Конвертор
php tools/s2fasm.php kernel.s kernel.asm

# Выполнение полной сборки и запуск
fasm os.asm && dd conv=notrunc if=os.bin of=c.img bs=512 seek=1 count=128 && bochs -f os.bxrc -q
