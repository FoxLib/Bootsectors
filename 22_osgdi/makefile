all: startup.o kernel.o
	ld -m elf_i386 -nostdlib -nodefaultlibs --oformat binary -Ttext=0x8000 -Tdata=0x280000 startup.o kernel.o -o boot.bin

clean:
	cp boot.bin floppy/boot.bin
	cp boot.bin disk/boot.bin
	rm boot.bin
	
bochs:
	bochs -f a.bxrc -q
	exit 0

startup.o: assembly/startup.asm
	nasm -felf32 -o startup.o assembly/startup.asm

#  $(wildcard kernel/*.c) $(wildcard kernel/fdc/*.c) $(wildcard gdi/*.c) $(wildcard app/*.c) $(wildcard kernel/*.c) $(wildcard kernel/fdc/*.c) $(wildcard gdi/*.c) $(wildcard app/*.c)
kernel.o: kernel.c kernel.h
	clang -Os -ffreestanding -m32 -march=i386 -mno-sse -c -o kernel.o kernel.c

