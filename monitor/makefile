all:
	rm -f *.lock
	fasm boot.asm
	dd conv=notrunc if=boot.bin of=disk.img bs=446 count=1
	bochs -f c.bxrc -q > /dev/null 2>&1
