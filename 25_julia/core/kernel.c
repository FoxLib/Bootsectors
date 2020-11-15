#include "kernel.h"

// ---------------------------------------------------------------------
// Писать данные в порт
// ---------------------------------------------------------------------

// Запись в порт 8 бит
static inline void IoWrite8(int16_t port, int8_t data) {
    __asm__ volatile("outb %b0, %w1" : : "a" (data), "Nd" (port));
}

// Запись в порт 16 бит
static inline void IoWrite16(int16_t port, int16_t data) {
    __asm__ volatile("outw %w0, %w1" : : "a" (data), "Nd" (port));
}

// Запись в порт 32 бит
static inline void IoWrite32(int16_t port, int32_t data) {
    __asm__ volatile("outl %0, %w1" : : "a" (data), "Nd" (port));
}

// ---------------------------------------------------------------------
// Читать данные из порта (port)
// ---------------------------------------------------------------------

// Читать 8 бит
static inline uint8_t IoRead8(int16_t port) {

    uint8_t data;
    __asm__ volatile("inb %1, %0" : "=a" (data) :"Nd" (port));
    return data;
}   

// Читать 16 бит
static inline uint16_t IoRead16(int16_t port) {
    
    uint16_t data;
    __asm__ volatile("inw %1, %0" : "=a" (data) : "Nd" (port));
    return data;
}

// Читать 32 бита
static inline uint32_t IoRead32(int16_t port) {

    uint32_t data;
    __asm__ volatile("inl %1, %0" : "=a" (data) : "Nd" (port));
    return data;
}

/**
 * Инициализация Program Interrupt Controller 8086
 * -----------------------------------------------------------------
 * Данная функция делает возможным использование устаревшего PIC 
 * взамен использования современных возможностей APIC для того, 
 * чтобы мне было легче понять и работать с этим
 * 
 * IVT       | INT #    | Описание
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
; ----------------------------------------------------------- */
void kernel_init_PIC8086(uint16_t bitmask) {

    int i; 

    // Процедура отключения локального APIC
    asm volatile ("pushl    %ecx");
    asm volatile ("pushl    %eax");
    asm volatile ("movl     $0x1b, %ecx");
    asm volatile ("rdmsr");
    asm volatile ("andl     $0xfffff7ff, %eax");
    asm volatile ("wrmsr");
    asm volatile ("popl     %eax");
    asm volatile ("popl     %ecx");

    // Запись инициализирующих значений
    for (i = 0; i < 2*10; i += 2) {
        IoWrite8(pic_init_array[i], pic_init_array[i+1]);
    }

    // Размаскировать некоторые прерывания
    IoWrite8(PIC1_DATA, IoRead8(PIC1_DATA) & (~bitmask & 0xff));
    IoWrite8(PIC2_DATA, IoRead8(PIC2_DATA) & ((~bitmask >> 8) & 0xff));

    // Расставить прерывания NULL, пустые прерывания
    for (i = 0; i < 256; i++) kernel_irq_make_descriptor(i, 0, 0x8E);
}

/**
 * Создание вектора (дескриптора) прерывания
 */
void kernel_irq_make_descriptor(uint32_t id, void* ptr, uint8_t attrb) {

    // Указатель преобразуется в целочисленный адрес
    uint32_t addr = (uint64_t) ptr;

    /* Тупой хак, но иначе компилятор меня не понимает */
    // Дескрипторы IDT начинаются с 0 и занимают 256 x 16 = 4096 байт
    struct IDT_Item * vector_item = (struct IDT_Item*) 8; /* Отступ вниз */id--;

    // Адрес
    vector_item[id].low_addr = addr & 0xffff;
    vector_item[id].hi_addr  = (addr >> 16) & 0xffff;

    // Параметры
    vector_item[id].selector = 0x0010;        // Селектор кода
    vector_item[id].attr     = (attrb << 8);  // Атрибуты, 8E00h
}