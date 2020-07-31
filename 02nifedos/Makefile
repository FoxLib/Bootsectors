WHO=$(shell whoami)
all: boot.bin core.bin
	rm -f *.lock
	cp core.bin fdd/
	bochs -f a.bxrc -q > /dev/null 2>&1
boot.bin: boot.asm floppy.img
	fasm boot.asm
	dd conv=notrunc if=boot.bin of=floppy.img bs=512 count=1
core.bin: core.asm
	fasm core.asm
floppy.img:
	dd if=/dev/zero of=floppy.img bs=1024 count=1440
# Сервисные
mkfs: floppy.img
	sudo losetup -o 0 /dev/loop1 floppy.img
	sudo mkfs.fat -F12 /dev/loop1
	sudo losetup -d /dev/loop1
fdd:
	mkdir -p fdd
	sudo mount floppy.img -t vfat -o loop,rw,uid="$(WHO)",sync,offset=$$[0] fdd
clean:
	rm -rf bx_*.ini *.bin fdd *.img
