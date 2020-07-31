#define brk	asm volatile("xchg %bx, %bx")
#define cli asm volatile("cli")
#define sti asm volatile("sti")
