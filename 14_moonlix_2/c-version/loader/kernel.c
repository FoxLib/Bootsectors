#include <stdint.h>
#include "../headers/memory.h"
#include "../headers/paging.h"
#include "../headers/events.h"
#include "../headers/messages.h"

#define BRK asm("xchg bx,bx");

// 100hz таймер
// -----------------------------------------
void timer_interrupt_handler()
{
    // Сброс флагов занятости у задач
    // ----

    // Сбросить флаг Busy у предыдущей задачи    
    uint32_t Nested = read(TSS_TIMER); 
    uint32_t Addr   = (Nested & 0xF8) + 0x18004;

    // Сбросить флаг Busy у предыдущей задачи
    write(Addr, read(Addr) & 0xFFFFFDFF);

    // Сбросить флаг Busy у главной задачи
    Addr = (read(TSS_SEG_MAIN) & 0xF8) + 0x18004;
    write(Addr, read(Addr) & 0xFFFFFDFF);

    // ----
    // Встроенный таймер просто пишет интервал
    write(TIMER32_P, read(TIMER32_P) + 1);

    outb(0x20, 0x20); // EOI Master
}
