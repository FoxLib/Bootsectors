#include "stddef.h"

// ---------------------------------------------------------------------
// DECLARES
// ---------------------------------------------------------------------

void INT_null();
void INT_timer();       // 18.2 -- 100
void IRQ_keyboard();
void IRQ_fdc();         // 6
void IRQ_ps2();         // 12
void IRQ_master();      // 0-7
void IRQ_slave();       // 8-F

// ---------------------------------------------------------------------
// Descriptor Interrupt
// ---------------------------------------------------------------------

struct __attribute__((__packed__)) IDT_Item {
    
    uint16_t low_addr;
    uint16_t selector;
    uint16_t attr;
    uint16_t hi_addr;
};

// ---------------------------------------------------------------------
// PIC Defines
// ---------------------------------------------------------------------

#define PIC1            0x20    // IO address master PIC
#define PIC2            0xA0    // IO address slave PIC

#define PIC1_COMMAND    PIC1
#define PIC1_DATA       (PIC1+1)

#define PIC2_COMMAND    PIC2
#define PIC2_DATA       (PIC2+1)

#define PIC_EOI         0x20

#define ICW1_ICW4        0x01 // ICW4
#define ICW1_SINGLE      0x02 // Cascade mode
#define ICW1_INTERVAL4   0x04 // 4
#define ICW1_LEVEL       0x08 // Edge Mode
#define ICW1_INIT        0x10 // Init

#define ICW4_8086        0x01 // 8086
#define ICW4_AUTO        0x02
#define ICW4_BUF_SLAVE   0x08
#define ICW4_BUF_MASTER  0x0C
#define ICW4_SFNM        0x10

#define IRQ_TIMER        (1<<0)
#define IRQ_KEYB         (1<<1)
#define IRQ_CASCADE      (1<<2)
#define IRQ_FDC          (1<<6)
#define IRQ_PS2MOUSE     (1<<12)

// ---------------------------------------------------------------------
// Prototypes
// ---------------------------------------------------------------------

void irq_init(uint16_t);
void pic_init(uint16_t);
void irq_make(uint32_t id, void* ptr);

void pic_timer();
void pic_keyboard();
