WHOAMI=$(shell whoami)

all:
	fasm boot.asm
	dd conv=notrunc if=boot.bin of=disk.img bs=446 count=1
	make bochs

bochs:
	rm -f *.lock
	bochs -f c.bxrc -q

disk:
	dd if=/dev/zero of=disk.img bs=1024 count=262144
	mkdir disk

mkfs:
	losetup -o 1048576 /dev/loop1 disk.img
	mkfs.fat -F32 /dev/loop1
	losetup -d /dev/loop1

mnt:
	mount disk.img -t vfat -o loop,rw,uid="$(WHOAMI)",sync,offset=1048576 disk
