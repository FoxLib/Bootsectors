#include "io.h"
#include "pic.h"

// Initialize Interrupt Vector, IRQ -> 20h-2Fh
void pic_init(uint16_t bitmask) {

    // Disable APIC
    asm volatile("pushl %eax"); asm volatile("pushl %ecx");
    asm volatile("movl $0x1B, %ecx");
    asm volatile("rdmsr");
    asm volatile("and $0xFFFFF7FF, %eax");
    asm volatile("wrmsr");
    asm volatile("popl %ecx"); asm volatile("pop %eax");

    // Redirect vectors
    IoWrite8(PIC1_COMMAND, ICW1_INIT + ICW1_ICW4);
    IoWrite8(PIC2_COMMAND, ICW1_INIT + ICW1_ICW4);

    IoWrite8(PIC1_DATA, 0x20); // Master 20h-27h
    IoWrite8(PIC2_DATA, 0x28); // Slave  28h-2Fh

    IoWrite8(PIC1_DATA, 4);
    IoWrite8(PIC2_DATA, 2);

    IoWrite8(PIC1_DATA, ICW4_8086);
    IoWrite8(PIC2_DATA, ICW4_8086);

    IoWrite8(PIC1_DATA, (~bitmask & 0xff));
    IoWrite8(PIC2_DATA, (~(bitmask>>8) & 0xff));
}

// Make IRQ
void irq_make(uint32_t id, void* ptr) {

    uint32_t addr = (uint32_t) ptr;

    struct IDT_Item* temp_int = (struct IDT_Item*) 8;

    temp_int[id-1].low_addr = addr & 0xffff;
    temp_int[id-1].hi_addr  = (addr>>16) & 0xffff;

    temp_int[id-1].selector = 0x0010; // DPL=0, CODE
    temp_int[id-1].attr     = 0x8E00;
}

// Init IRQ
void irq_init(uint16_t bitmask) {

    pic_init(bitmask);

    int id;
    for (id = 0; id < 256; id++) {

        if (id >= 0x20 && id < 0x28) {
            irq_make(id, &IRQ_master);

        } else if (id >= 0x28 && id <= 0x30) {
            irq_make(id, &IRQ_slave);

        } else {
            irq_make(id, &INT_null);
        }
    }

    irq_make(0x21, & IRQ_keyboard);
    irq_make(0x26, & IRQ_fdc);
    irq_make(0x2C, & IRQ_ps2);
}

// Keyboard
void pic_keyboard() {

    byte kbd = IoRead8(0x60);
}
