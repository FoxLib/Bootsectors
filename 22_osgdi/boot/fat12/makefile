all: boot.bin
	dd conv=notrunc if=boot.bin of=../../floppy.img bs=512 count=1

run:
	cd ../.. && bochs -f a.bxrc -q

boot.bin: boot.asm
	fasm boot.asm 