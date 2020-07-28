all: disk boot.bin main.bin
	bochs -f c.bxrc -q > /dev/null 2>&1
disk:
	dd if=/dev/zero of=disk.img count=524288
	mkdir disk
boot.bin: boot.asm
	fasm boot.asm
	dd conv=notrunc if=boot.bin of=disk.img bs=512 count=1
main.bin: main.asm $(wildcard inc/*.asm)
	fasm main.asm
	dd conv=notrunc if=main.bin of=disk.img bs=512 seek=1
clean:
	rm -rf bx_*.ini *.bin disk disk.img
