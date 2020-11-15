WHOAMI=`whoami`

all:
	fasm boot.asm
	dd conv=notrunc if=boot.bin of=floppy.img bs=512 count=1

bochs:
	bochs -f a.bxrc -q

disk:
	dd if=/dev/zero of=floppy.img bs=1024 count=1440
	mkdir disk
	
mkfs:
	losetup -o 0 /dev/loop1 floppy.img
	mkfs.fat -F12 /dev/loop1
	losetup -d /dev/loop1

# Бессмысленно выполнять это
mnt:
	mount floppy.img -t vfat -o loop,rw,uid="$(WHOAMI)",sync,offset=0 disk	

clean:
	rm -f *.o
	rm -f *.ini
	rm -f boot.bin
