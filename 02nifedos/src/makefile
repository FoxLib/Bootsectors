CC=clang
COPT=-Os -ffreestanding -fno-pie -nostdlib -m32 -mno-sse
DEPS=nasm.o fdc.o ata.o ps2mouse.o vga.o pic.o main.o

all: $(DEPS)
	ld -m elf_i386 -nostdlib -nodefaultlibs --oformat binary -Ttext=0x8000 -Tdata=0x100000 $(DEPS) -o ../disk/core.bin
nasm.o: main.asm
	nasm -felf32 -o nasm.o main.asm
main.o: main.h ata.h pic.h main.c
	$(CC) $(COPT) -c main.c -o main.o
pic.o: pic.c io.h pic.h main.asm
	$(CC) $(COPT) -c pic.c -o pic.o
%.o: %.c %.h io.h
	$(CC) $(COPT) -c $< -o $@
clean:
	rm -f *.o *.ini

