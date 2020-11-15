all: core.bin

bochs:
	bochs -f c.bxrc -q

core.bin: core.asm
	fasm core.asm
	dd conv=notrunc if=core.bin of=disk.img bs=512 seek=1 2> /dev/null
