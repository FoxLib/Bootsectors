CC=clang
COPT=-Os -ffreestanding -fno-pie -nostdlib -m32 -mno-sse
DEPS=nasm.o fdc.o ata.o ps2mouse.o vga.o pic.o main.o

all: $(DEPS)
	ld -m elf_i386 -nostdlib -nodefaultlibs --oformat binary -Ttext=0x8000 -Tdata=0x100000 $(DEPS) -o ../disk/core.bin
nasm.o: main.asm
	nasm -felf32 -o nasm.o main.asm
main.o: main.h ata.h pic.h main.c
	$(CC) $(COPT) -c main.c -o main.o
pic.o: io.h pic.h pic.c main.asm
	$(CC) $(COPT) -c pic.c -o pic.o
ata.o: io.h ata.h ata.c
	$(CC) $(COPT) -c ata.c -o ata.o
vga.o: io.h vga.h vga.c
	$(CC) $(COPT) -c vga.c -o vga.o
fdc.o: io.h fdc.h fdc.c
	$(CC) $(COPT) -c fdc.c -o fdc.o
ps2mouse.o: io.h ps2mouse.h ps2mouse.c
	$(CC) $(COPT) -c ps2mouse.c -o ps2mouse.o
clean:
	rm -f *.o *.ini boot.bin

