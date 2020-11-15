all:
	make floppy.bin
	cd .. && make bochs

floppy.bin: floppy.asm
	fasm floppy.asm
	dd conv=notrunc if=floppy.bin of=../floppy.img bs=512 count=1
