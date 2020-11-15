/**
 * Функции ввода-вывода и работы с устройствами
 */

/* IVT Offset | INT #    | Description
; -----------+-----------+-----------------------------------
; 0x0000     | 0x00      | Divide by 0
; 0x0004     | 0x01      | Trace
; 0x0008     | 0x02      | NMI Interrupt
; 0x000C     | 0x03      | Breakpoint (INT3)
; 0x0010     | 0x04      | Overflow (INTO)
; 0x0014     | 0x05      | Bounds range exceeded (BOUND)
; 0x0018     | 0x06      | Invalid opcode (UD2)
; 0x001C     | 0x07      | Device not available (WAIT/FWAIT)
; -----------------------------------------------------------
; 0x0020     | 0x08      | Double fault
; 0x0024     | 0x09      | Coprocessor segment overrun
; 0x0028     | 0x0A      | Invalid TSS
; 0x002C     | 0x0B      | Segment not present
; 0x0030     | 0x0C      | Stack-segment fault
; 0x0034     | 0x0D      | General protection fault
; 0x0038     | 0x0E      | Page fault
; 0x003C     | 0x0F      | ---
; 0x0040     | 0x10      | x87 FPU error
; 0x0044     | 0x11      | Alignment check
; 0x0048     | 0x12      | Machine check
; 0x004C     | 0x13      | SIMD Floating-Point Exception
; 0x00xx     | 0x14-0x1F | ---
; 0x0xxx     | 0x20-0xFF | User defined
; -----------------------------------------------------------
*/

// Адреса PIC 8086/88
// ---------------------------------------------------------------------

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

// Устройство PS/2
#define KB_WAIT          65536

// Маски
#define IRQ_TIMER        (1 << 0)
#define IRQ_KEYB         (1 << 1)
#define IRQ_CASCADE      (1 << 2)
#define IRQ_FDC          (1 << 6)
#define IRQ_PS2MOUSE     (1 << 12)

// Процедура необходимой задержки для корректной работы прерываний
#define IoWait asm volatile("jecxz 1f" "\n\t" "1:jecxz 2f" "\n\t" "2:");

// Писать в (port) данные data
// ---------------------------------------------------------------------

static inline void IoWrite8(word port, byte data) {
    asm volatile("outb %b0, %w1" : : "a" (data), "Nd" (port));
}

static inline void IoWrite16(word port, word data) {
    asm volatile("outw %w0, %w1" : : "a" (data), "Nd" (port));
}

static inline void IoWrite32(word port, dword data) {
    asm volatile("outl %0, %w1" : : "a" (data), "Nd" (port));
}

// Читать данные из порта (port)
// ---------------------------------------------------------------------
static inline byte IoRead8(word port) {

    byte data;
    asm volatile("inb %1, %0" : "=a" (data) :"Nd" (port));
    return data;
}

static inline word IoRead16(word port) {

    word data;
    asm volatile("inw %1, %0" : "=a" (data) : "Nd" (port));
    return data;
}

static inline dword IoRead32(word port) {

    dword data;
    asm volatile("inl %1, %0" : "=a" (data) : "Nd" (port));
    return data;
}

/* Отключение локального APIC */
static inline void apic_disable() {

    asm volatile("movl  $0x1b, %%ecx" ::: "ecx");
    asm volatile("rdmsr");
    asm volatile("andl  $0xfffff7ff, %%eax" ::: "eax");
    asm volatile("wrmsr");
}

/* Получение байта из памяти */
volatile byte peek(uint address) { byte* t = (byte*)8; return t[ address - 8 ]; }
