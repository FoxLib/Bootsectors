FREESTAND=-Os -ffreestanding -m32 -march=i386 -mno-sse
FILES=startup.o kernel.o core.o

all: $(FILES)
	ld -m elf_i386 -nostdlib -nodefaultlibs --oformat binary -Ttext=0x8000 -Tdata=0x280000 $(FILES) -o core.bin
	cp core.bin disk/core.bin
	rm core.bin

startup.o: startup.asm
	nasm -felf32 -o startup.o startup.asm

core.o: core.c 
	clang $(FREESTAND) -c -o core.o core.c

kernel.o: core/kernel.c core/kernel.h
	clang $(FREESTAND) -c -o kernel.o core/kernel.c 

clean:
	rm *.o
	
bochs:
	bochs -f c.bxrc -q
	exit 0
