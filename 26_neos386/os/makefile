all:
	fasm core.asm
	cp core.bin disk/
	make bochs

bochs:
	bochs -f a.bxrc -q

mkfs:
	losetup -o 0 /dev/loop1 floppy.img
	mkfs.fat -F12 /dev/loop1
	losetup -d /dev/loop1

mnt:
	sudo mount floppy.img -t vfat -o loop,rw,uid="`whoami`",sync,offset=0 disk
