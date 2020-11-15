// Ссылки на прерывания
void interrupt_null();
void interrupt_keyb();
void service_interrupt_40h();
void exception_page_fault();
void exception_GP_fault();

#include "exceptions/page_fault.c"

// 64-х битный дескриптор прерывания
struct IDT_Item {
    
    uint16_t low_addr;
    uint16_t selector;
    uint16_t attr;
    uint16_t hi_addr;
    
};

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

// http://wiki.osdev.org/Interrupt_Descriptor_Table#IDT_in_IA-32e_Mode_.2864-bit_IDT.29
// attrb = 8Eh Interrupt
// attrb = 8Fh Trap

void kernel_isr_make(uint32_t id, void* ptr, uint8_t attrb) {

    // Преобразуем указатель в адрес
    uint32_t addr = (uint64_t)ptr;
    
    // Дескрипторы IDT начинаются с 0 и занимают 256 x 16 = 4096 байт
    struct IDT_Item * I = (struct IDT_Item*) 0;
    
    // Адрес
    I[id].low_addr = addr & 0xffff;
    I[id].hi_addr  = (addr >> 16) & 0xffff;

    // Параметры
    I[id].selector = 0x0010;        // Селектор кода
    I[id].attr     = (attrb << 8);  // Атрибуты, 8E00h
}


// Инициализация Interrupt Service Routines
void kernel_isr_init() {
    
    int i;
    
    for (i = 0; i < 256; i++) {
        kernel_isr_make(i, & interrupt_null, 0x8E);
    }
    
    // Назначить вектора прерываний
    kernel_isr_make(0x21, & interrupt_keyb, 0x8E);
    
    // Сервисные прерывания :: недоступно для Ring3 пока что
    kernel_isr_make(0x40, & service_interrupt_40h, 0x8E);
    
    // Обработчики Exception
    kernel_isr_make(0x0E, & exception_page_fault, 0x8E);
    kernel_isr_make(0x0D, & exception_GP_fault, 0x8E);
    
}
