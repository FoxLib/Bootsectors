// ------------------------------------------------------------------

#define IRQ_TIMER        (1 << 0)
#define IRQ_KEYB         (1 << 1)
#define IRQ_CASCADE      (1 << 2)

// ------------------------------------------------------------------

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

/*
; IVT Offset | INT #     | Description
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
; 0x0xxx     | 0x20-0xFF | User definable
; -----------------------------------------------------------
*/

/*
 * Процедура необходимой задержки для корректной работы прерываний
 */

static inline void IoWait()
{
    __asm__ volatile("jcxz $+2");
    __asm__ volatile("jcxz $+2");
}

/*
 * Процедура, которая переводит IRQ с их стандартных позиции из REALmode в PROTmode
 */

void sys_irq_redirect(int bitmask)
{
    // Отключение локального APIC
    asm("push edx" "\n" "mov ecx, 0x1B" "\n" "rdmsr" "\n" "and eax, 0xfffff7ff" "\n" "wrmsr" "\n" "pop edx");

    // Запуск последовательности инициализации (в режиме каскада)
    IoWrite8(PIC1_COMMAND, ICW1_INIT + ICW1_ICW4); IoWait();
    IoWrite8(PIC2_COMMAND, ICW1_INIT + ICW1_ICW4); IoWait();

    IoWrite8(PIC1_DATA, 0x20); IoWait(); // ICW2: Master PIC vector offset 0x20 .. 0x27    
    IoWrite8(PIC2_DATA, 0x28); IoWait(); // ICW2: Slave PIC vector offset 0x28 .. 0x2F

    IoWrite8(PIC1_DATA, 4); IoWait(); // ICW3: послать сигнал на Master PIC, что существует slave PIC at IRQ2 (0000 0100)    
    IoWrite8(PIC2_DATA, 2); IoWait(); // ICW3: сигнал Slave PIC на идентификацию каскада (0000 0010)

    // 8086/88 (MCS-80/85) режим (master/slave)
    IoWrite8(PIC1_DATA, ICW4_8086); IoWait();
    IoWrite8(PIC2_DATA, ICW4_8086); IoWait();

    // Записать маски (полностью блокировать прерывания)
    IoWrite8(PIC1_DATA, 0xff); IoWait();
    IoWrite8(PIC2_DATA, 0xff); IoWait();

    // Размаскировать некоторые прерывания
    IoWrite8(PIC1_DATA, IoRead8(PIC1_DATA) & (bitmask & 0xff));
    IoWrite8(PIC2_DATA, IoRead8(PIC2_DATA) & ((bitmask >> 8) & 0xff)); 
}

/*
 * Создать шлюз прерывания
 */

void sys_irq_create(u16 n, u32* link)
{
    u8* irqb = (u8*)0x0;

    n *= 8;
    
    // Адрес [15..0]
    irqb[n++] = (u32)link;
    irqb[n++] = (u32)link >> 8;
    
    // Селектор (8-код)
    irqb[n++] = 0x08; irqb[n++] = 0x00; 

    // Present, 0x0E0 System | gate interrupt
    irqb[n++] = 0x00; irqb[n++] = 0x8E; 
    
    // Адрес [31..16]
    irqb[n++] = (u32)link >> 16;
    irqb[n++] = (u32)link >> 24;
}

/*
 * Создание всех прерываний
 */

void sys_irq_make()
{
    int n; 

    for (n = 0; n < 256; n++) {
        sys_irq_create(n, (u32*)_irq_isr_null);
    }
}
