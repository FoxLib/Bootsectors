// Компиляция
// gcc -S -masm=intel -m32 stub_test.c && cat stub_test.s | php ../tools/gcc2fasm.php > stub_test_c.asm && fasm stub_test_c.asm

// Запись на виртуальный диск (
// php ../tools/fat32.php disk.img write loader12.run stub_test_c.bin

// Общая сборка
// ----------------------
// gcc -S -masm=intel -m32 stub_test.c && cat stub_test.s | php ../tools/gcc2fasm.php > stub_test_c.asm && fasm stub_test_c.asm && php ../tools/fat32.php disk.img write loader16.run stub_test_c.bin
// ----------------------

#include "../includes/gcc/dos_stdlib.c"

void main()
{
    brk

    sprint("Hello, real world for real peoples\r\n");
    sprint("А тут идет вообще нечто нереальное\r\n"); // фиксануть в fasmе

    // fdisk_load_bios("filename", &buffer, 2048)

    halt
}