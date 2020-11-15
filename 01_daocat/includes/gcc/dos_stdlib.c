void sprint(char* nstring, ...);

#define brk asm("xchg bx, bx");
#define halt asm("jmp $+0");

// #define outb(a) asm("")
// #define inb(a) asm("")
// #define outw(a) asm("")
// #define inw(a) asm("")
// #define outd(a) asm("")
// #define ind(a) asm("")

// ----------------------------------------------------------

// Подсчет длины строки
int str_len(char* b)
{
    int k = 0;
    while (*b++) k++;

    return k;
}

// Записать символ в телетайп
void term_put_char(unsigned char chr)
{
    asm ("mov al, %0" : : "r"(chr)  );
    asm ("mov ah, 0x0E" );
    asm ("mov bl, 0x07" );
    asm ("int 0x10" );
}

void term_waitkey()
{
    asm ("xor eax, eax");
    asm ("int 0x16");
}

__inline void exit_program()
{
    asm ("int 0x20" );
}

// dos дебаг
void prints(char* input_string)
{
    char* pstring = input_string;
    while (*pstring) term_put_char(*pstring++);
}

// Печать целого знакового числа
void printi(int a)
{
    char buf[256];
    int  c = 0, i;

    if (a < 0)
    {
        a = -a;
        term_put_char('-');
    }

    while (a)
    {
        buf[c++] = a % 10;
        a /= 10;
    }

    for (i = c - 1; i >= 0; i--) term_put_char(buf[i] + 0x30);
}

// Печать дробной части числа
void print_float(float a)
{
    int s = 16;

    if (a < 0)
    {
        a = -a;
        term_put_char('-');
    }

    printi(a);
    term_put_char('.');

    a = a - (int)a;
    while (a > 0 && s--)
    {
        a *= 10;
        while (a >= 10) a -= 10;

        // Если есть что выводить на экран
        if (a > 0) term_put_char((int)a + 0x30);
    }
}

// Печать строки
void sprint(char* nstring, ...)
{
    int i = 0, i32;
    float f32;

    while (*nstring)
    {
        // Печать 32-битного long
        // -----------------------
        if (nstring[0] == '%' && nstring[1] == 'd')
        {
            asm ("mov ebx, %0" : : "r"(i)  );

            // +0  esp
            // +4  ret32
            // +8  nstrting (32 pointer)
            // +12 parameter 1

            asm ("mov %0, dword [ebp + ebx + 12]" : "=r"(i32) : );
            printi(i32);

            nstring += 2;
            i += 4;
        }
        // Печать 32-битного float
        // -----------------------
        if (nstring[0] == '%' && nstring[1] == 'f')
        {
            asm ("mov ebx, %0" : : "r"(i)  );
            asm ("fld  qword [ebp + ebx + 12]");

            // Сохранение 32-битного значения в f32
            asm ("fstp %0" : : "m"(f32));
            print_float(f32);

            nstring += 2;
            i += 4;
        }
        else
        {
            term_put_char(*nstring);
            nstring++;
        }
    }
}