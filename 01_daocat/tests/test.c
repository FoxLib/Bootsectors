// Компиляция из GCC через fasm в бинарный код
// gcc -S -masm=intel -m32 test.c && cat test.s | php ../tools/gcc2fasm.php > test.asm && fasm test.asm

#include "../includes/gcc/dos_stdlib.c"

void main()
{
    char* test = "\ntest\n";

    int a = 5001;
    float b = 5.2;

    sprint("wow %d!!! and %f\n", 511, 0.5);

    term_waitkey();
    exit_program();
}