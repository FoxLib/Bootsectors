WHO=$(shell whoami)
all: disk boot.bin main.bin
	rm -f *.lock
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
floppy: floppy.img
	sudo losetup -o 0 /dev/loop1 floppy.img
	sudo mkfs.fat -F12 /dev/loop1
	sudo losetup -d /dev/loop1
floppy.img:
	dd if=/dev/zero of=floppy.img bs=1024 count=1440
fdd: floppy
	mkdir -p fdd
	sudo mount floppy.img -t vfat -o loop,rw,uid="$(WHO)",sync,offset=$$[0] fdd
