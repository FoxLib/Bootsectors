CC=clang
COPT=-Os -ffreestanding -fno-pie -nostdlib -m32 -mno-sse
DEPS=nasm.o fdc.o ata.o ps2mouse.o vga.o pic.o stdlib.o fs.o gui.o stdio.o main.o

all: $(DEPS)
	ld -m elf_i386 -nostdlib -nodefaultlibs --oformat binary -Ttext=0x8000 -Tdata=0x100000 $(DEPS) -o ../disk/core.bin
	cd .. && bochs -f a.bxrc -q > /dev/null 2>&1
nasm.o: main.asm
	nasm -felf32 -o nasm.o main.asm
%.o: %.c %.h io.h
	$(CC) $(COPT) -c $< -o $@
clean:
	rm -f *.o *.ini

