#define brk __asm__ __volatile__("xchg %bx, %bx"); // Отладка
#define cli __asm__ __volatile__("cli");
#define sti __asm__ __volatile__("sti");

// Типы
#define u8      unsigned char
#define s8      signed char
#define u16     unsigned short
#define uint    unsigned int
#define u32     unsigned int
