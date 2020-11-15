all: boot.bin

boot.bin: boot.asm
	fasm boot.asm
	dd conv=notrunc if=boot.bin of=../disk.img bs=446 count=1 2> /dev/null
