// ---------------------------------------------------------
// Некоторые инструкции 
// ---------------------------------------------------------

#define brk __asm__ __volatile__("xchg %bx, %bx");
#define sti __asm__ __volatile__("sti");
#define cli __asm__ __volatile__("cli");

// ---------------------------------------------------------
// Описание типов
// ---------------------------------------------------------

#define int8_t      signed char
#define uint8_t     unsigned char
#define byte        unsigned char

#define int16_t     signed short
#define uint16_t    unsigned short
    
#define int32_t     signed int
#define uint32_t    unsigned int
#define size_t      unsigned int
#define dword       unsigned int

#define int64_t     long long
#define uint64_t    unsigned long long

// ---------------------------------------------------------
// PIC: Programming Interrupt Controller
// ---------------------------------------------------------

#define PIC1             0x20  /* IO базовый адрес для master PIC */
#define PIC2             0xA0  /* IO базовый адрес для slave PIC */

#define PIC1_COMMAND     PIC1
#define PIC1_DATA        (PIC1+1)

#define PIC2_COMMAND     PIC2
#define PIC2_DATA        (PIC2+1)

#define PIC_EOI          0x20  /* End-of-interrupt command code */

#define ICW1_ICW4        0x01  /* ICW4 (not) needed */
#define ICW1_SINGLE      0x02  /* Single (cascade) mode */
#define ICW1_INTERVAL4   0x04  /* Call address interval 4 (8) */
#define ICW1_LEVEL       0x08  /* Level triggered (edge) mode */
#define ICW1_INIT        0x10  /* Initialization - required! */

#define ICW4_8086        0x01  /* 8086/88 (MCS-80/85) mode */
#define ICW4_AUTO        0x02  /* Auto (normal) EOI */
#define ICW4_BUF_SLAVE   0x08  /* Buffered mode/slave */
#define ICW4_BUF_MASTER  0x0C  /* Buffered mode/master */
#define ICW4_SFNM        0x10  /* Special fully nested (not) */

// ---------------------------------------------------------
// Битовые маски для IRQ-прерываний
// ---------------------------------------------------------

#define IRQ_TIMER        (1 << 0)
#define IRQ_KEYB         (1 << 1)
#define IRQ_CASCADE      (1 << 2)
#define IRQ_PS2MOUSE     (1 << 12)

// Последовательность инициализаци
static const uint16_t pic_init_array[10*2] = {

    PIC1_COMMAND, ICW1_INIT + ICW1_ICW4,
    PIC2_COMMAND, ICW1_INIT + ICW1_ICW4,
    PIC1_DATA, 0x20,
    PIC2_DATA, 0x28,
    PIC1_DATA, 4,
    PIC2_DATA, 2,

    // 8086/88 (MCS-80/85) режим (master/slave)
    PIC1_DATA, ICW4_8086,
    PIC2_DATA, ICW4_8086,
    
    // Записать маски (полностью блокировать прерывания)
    PIC1_DATA, 0xFF,
    PIC2_DATA, 0xFF
};

// ----------------------------------------------------------
// Структуры дескрипторов IDT/GDT/LDT и др.
// ----------------------------------------------------------

// 64-х битный дескриптор прерывания
struct __attribute__((__packed__)) IDT_Item {

    uint16_t low_addr;
    uint16_t selector;
    uint16_t attr;
    uint16_t hi_addr;
};

// ----------------------------------------------------------
// Прототипы kernel.c
// ----------------------------------------------------------

static inline void IoWrite8(int16_t, int8_t);
static inline void IoWrite16(int16_t, int16_t);
static inline void IoWrite32(int16_t, int32_t);

static inline uint8_t  IoRead8(int16_t);
static inline uint16_t IoRead16(int16_t);
static inline uint32_t IoRead32(int16_t);

void kernel_init_PIC8086(uint16_t);
void kernel_irq_make_descriptor(uint32_t, void*, uint8_t);
