// gcc -c -masm=intel -m32 -fno-asynchronous-unwind-tables bootstrap.c -S

#include <stdint.h>
#define BRK asm("xchg bx, bx");

// Маскирование прерываний
#define BMASK_MASTER 0b11111000 // 1=Keyboard, 0=Timer, 2 - Cascade
#define BMASK_SLAVE  0b11101111 // PS/2 mouse

// Основная процедура (timer)
void timer_interrupt();
void int_c0();

// Описатели дескрипторов
#include "../headers/descriptors.h"
#include "../headers/asm.h"
#include "../headers/io.h"
#include "../headers/ints.h"
#include "../headers/memory.h"

// Отключить APIC
void APIC_disable()
{
    uint32_t eax;

    asm("mov ecx, 0x1B");
    asm("rdmsr");
    asm("mov %0, eax" : "=m"(eax));

    // Сбрасываем 11-й бит в MSR 1Bh
    if (eax & 0x800) {

        eax &= 0xfffff7ff;
        asm("mov eax, %0" : : "m"(eax));
        asm("wrmsr");        
    }
}

// Запрещение прерываний
void IRQ_mask(uint8_t port, uint8_t mask)
{    
    mask = inb(port) & mask;
    outb(port, mask);
}

// Редиректы IRQ на 0x20-0x2F векторы
// @url http://wiki.osdev.org/PIC
void IRQ_redirect()
{   
    /*
     * Из-за того, что у меня дремучий код, я отключаю APIC
     * Система у меня все равно никуда не годная, а только для
     * личного насл<O>ждения тем, что я сижу из Protected Mode.
     */
    APIC_disable();
  
    // Запуск последовательности инициализации (в режиме каскада)
    outb(PIC1_COMMAND, ICW1_INIT + ICW1_ICW4); io_wait();
    outb(PIC2_COMMAND, ICW1_INIT + ICW1_ICW4); io_wait();
    
    outb(PIC1_DATA, 0x20); io_wait(); // ICW2: Master PIC vector offset    
    outb(PIC2_DATA, 0x28); io_wait(); // ICW2: Slave PIC vector offset
   
    outb(PIC1_DATA, 4); io_wait(); // ICW3: послать сигнал на Master PIC, что существует slave PIC at IRQ2 (0000 0100)
    outb(PIC2_DATA, 2); io_wait(); // ICW3: сигнал Slave PIC на идентификацию каскада (0000 0010)
 
    // 8086/88 (MCS-80/85) режим (master/slave)
    outb(PIC1_DATA, ICW4_8086); io_wait();
    outb(PIC2_DATA, ICW4_8086); io_wait();
   
    // Отключить все прерывания
    outb(PIC1_DATA, 0xFF); 
    outb(PIC2_DATA, 0xFF);
  
    // Размаскировать некоторые прерывания
    IRQ_mask(0x21, BMASK_MASTER); 
    IRQ_mask(0xA1, BMASK_SLAVE); 
}

// Создать дескриптор [http://wiki.osdev.org/GDT_Tutorial]
uint64_t create_descriptor(uint32_t base, uint32_t limit, uint16_t flag)
{
    uint64_t descriptor;
 
    // Создать верхние 32 бит сегмента
    descriptor  =  limit       & 0x000F0000;         // set limit bits 19:16
    descriptor |= (flag <<  8) & 0x00F0FF00;         // set type, p, dpl, s, g, d/b, l and avl fields
    descriptor |= (base >> 16) & 0x000000FF;         // set base bits 23:16
    descriptor |=  base        & 0xFF000000;         // set base bits 31:24
 
    // Сдвигаем на 32 бита вправо для доступа к нижним 32 бит
    descriptor <<= 32;
 
    // Создать нижние 32 бит сегмента
    descriptor |= base  << 16;                       // set base bits 15:0
    descriptor |= limit  & 0x0000FFFF;               // set limit bits 15:0

    return descriptor;
}

// Создать дескриптор прерывания (Present=1)
// cfg & 0x01 -- trap
// cfg & 0x60 -- DPL

uint64_t create_gate_interrupt(uint32_t addr, uint16_t selector, uint8_t cfg)
{
    uint64_t descriptor;

    // Верхние 16 бит адреса базы
    descriptor  = addr  & 0xFFFF0000;
    descriptor  = descriptor | (0x8E00 | (cfg << 8)); // 0x8000 Present, 0x0E0 System | gate interrupt
   
    // База и селектор
    descriptor <<= 32;
    descriptor  |= addr           & 0x0000FFFF;
    descriptor  |= (selector<<16) & 0xFFFF0000;

    return descriptor;
}

// Создать дескриптор для GATE TASK, для INT0
uint64_t create_task_gate(uint16_t selector, uint16_t dpl) 
{
    uint64_t d = 0x8500 | (dpl << 13);
    d <<= 32;
    return d | (selector << 16);
}

// Поиск свободного ID в GDT
uint16_t gdt_find_free()
{
    uint16_t id = 1;
    uint32_t h, l;

    while (id < 8192) 
    {
        l = read(0x18000 + id*8);
        h = read(0x18000 + id*8 + 4);

        if (h == 0 && l == 0) {
            return id * 8;
        }

        id++;
    }

    return 0;
}

// Поиск в таблице GDT новых мест для дескриптора
uint16_t put_gdt_descriptor(uint64_t descriptor, uint8_t ring)
{ 
    uint32_t id = 1, L, H;

    // Перебираем все 8192 элемента GDT
    while (id < 8192)
    {
        // Прочитать Дескриптор из таблицы GDT
        L = read(0x18000 + id*8);
        H = read(0x18000 + id*8 + 4);

        // Свободный адрес найден?
        if (L == 0 && H == 0) 
        {
            L = descriptor & 0xffffffff;
            H = descriptor >> 32;

            write(0x18000 + id*8, L);
            write(0x18004 + id*8, H);
            return (8*id) | ring;
        }

        id++;
    }
    
    return 0;
}

// Записать дескриптор в IDT (0x28000 - 0x287FF)
void idt_put_descriptor(uint32_t id, uint64_t desc)
{
    uint32_t L = desc & 0xffffffff, 
             H = desc >> 32;    

    write(0x28000 + id*8, L);
    write(0x28004 + id*8, H);
}

// Инициализируем прерывания
void Init_Interrupts()
{
    int i;
    uint64_t intc;

    // Системные исключения
    uint32_t ExCode[20] = {
        (uint32_t)Exc00_DE,
        (uint32_t)Exc01_DB,
        (uint32_t)Exc02_NMI,
        (uint32_t)Exc03_BP,
        (uint32_t)Exc04_OF,
        (uint32_t)Exc05_BR,
        (uint32_t)Exc06_UD,
        (uint32_t)Exc07_NM,
        (uint32_t)Exc08_DF,
        (uint32_t)Exc09_FPU_seg,
        (uint32_t)Exc0A_TS,
        (uint32_t)Exc0B_NP,
        (uint32_t)Exc0C_SS,
        (uint32_t)Exc0D_GP,
        (uint32_t)Exc0E_PF,
        (uint32_t)Exc0F,
        (uint32_t)Exc10_MF,
        (uint32_t)Exc11_AC,
        (uint32_t)Exc12_MC,
        (uint32_t)Exc13_XF
    };

    // IRQ
    uint32_t IrqCode[16] = {
        (uint32_t)IRQ_0,
        (uint32_t)IRQ_1,
        (uint32_t)IRQ_2,
        (uint32_t)IRQ_3,
        (uint32_t)IRQ_4,
        (uint32_t)IRQ_5,
        (uint32_t)IRQ_6,
        (uint32_t)IRQ_7,
        (uint32_t)IRQ_8,
        (uint32_t)IRQ_9,
        (uint32_t)IRQ_A,
        (uint32_t)IRQ_B,
        (uint32_t)IRQ_C,
        (uint32_t)IRQ_D,
        (uint32_t)IRQ_E,
        (uint32_t)IRQ_F
    };

    // Создать прерывание-заглушку
    intc = create_gate_interrupt((uint32_t)Interrupt_Stub, 0x08, 0); 

    // 1. Инициализация заглушками
    for (i = 0; i < 256; i++) { idt_put_descriptor(i, intc); }

    // 2. Инициализация системных исключений
    for (i = 0; i < 20; i++) {
        
        // CS: 0x8 DPL = 0
        idt_put_descriptor(i, create_gate_interrupt((uint32_t)ExCode[i], 0x08, 0));
    }

    // 3. Инициализация IRQ
    for (i = 0; i < 16; i++) {

        // CS: 0x8 DPL = 0
        idt_put_descriptor(0x20 + i, create_gate_interrupt((uint32_t)IrqCode[i], 0x08, 0));        
    }

    // Регистрация функции ядра [CS = 0x08]
    idt_put_descriptor(0xC0, create_gate_interrupt((uint32_t)int_c0, 0x08, 0));        
}

// Инициализация системного таймера на 100 Гц
// Как работает. Загружаем в msb:lsb число 2E9B (десятичное 11931)
// Делим на 119,3 (константа), получается ~100 Гц

void timer_init()
{
    outb(0x43, 0x34);
    outb(0x40, 0x9B); // 
    outb(0x40, 0x2E); // msb
}

// Создание TSS | http://wiki.osdev.org/TSS
// Результат - номер дескриптора
// -------------------------------------------------------
void tss_create_main(uint16_t gs)
{
    int i; for (i = 0; i < 26; i++) write(TSS_MAIN + i*4, 0);

    /*
     * Установка eflags, регистров общего назначения и сегментов не нужно,
     * поскольку при переключении задачи будет происходить запись в TSS 
     * всех этих значений
     */

    // Стек 0, 1, 2
    write(TSS_MAIN + TSS_SS0,  0x18); write(TSS_MAIN + TSS_ESP0, 0xFFF0);
    write(TSS_MAIN + TSS_SS1,  0x18); write(TSS_MAIN + TSS_ESP1, 0x8000);
    write(TSS_MAIN + TSS_SS2,  0x18); write(TSS_MAIN + TSS_ESP2, 0x7000);  

    // Важно загрузить сегменты CR3
    write(TSS_MAIN + TSS_CR3, CR3_PDBR0);

    // Создать и установить дескриптор в GDT
    uint16_t dtss = put_gdt_descriptor(create_descriptor(TSS_MAIN, 104, SYS_SEGMENT_AVAIL_386_TSS | SEG_PRES(1)), 0);

    // Запись сегмента
    write(TSS_SEG_MAIN, dtss);
}

// Создать TSS таймера
// -------------------------------------------------------
void tss_timer_task()
{   
    // Обязательно очищать! Иначе будет очень много не нужных данных
    int i; for (i = 0; i < 26; i++) write(TSS_TIMER + i*4, 0);

    // Первичная точка запуска
    write(TSS_TIMER + TSS_CS,  0x08);
    write(TSS_TIMER + TSS_EIP, timer_interrupt);

    // Стандартный стек (совпадает со стеком уровня 0)
    // По сегментам см. docs/memory_map.txt
    write(TSS_TIMER + TSS_SS,  0x18);  
    write(TSS_TIMER + TSS_ESP, 0x6000);   

    // Основные сегменты
    write(TSS_TIMER + TSS_DS,  0x10);
    write(TSS_TIMER + TSS_ES,  0x10);
    write(TSS_TIMER + TSS_FS,  0x20);
    write(TSS_TIMER + TSS_GS,  0x28);
    write(TSS_TIMER + TSS_CR3, CR3_PDBR0);

    // Стек 0,1,2
    write(TSS_TIMER + TSS_SS0,  0x18); write(TSS_TIMER + TSS_ESP0, 0x5000);
    write(TSS_TIMER + TSS_SS1,  0x18); write(TSS_TIMER + TSS_ESP1, 0x3000);    
    write(TSS_TIMER + TSS_SS2,  0x18); write(TSS_TIMER + TSS_ESP2, 0x2000);  
 
    // Создать и установить дескриптор в GDT
    uint16_t dtss = put_gdt_descriptor(create_descriptor(TSS_TIMER, 104, SYS_SEGMENT_AVAIL_386_TSS | SEG_PRES(1)), 0);

    // Записать сегмент задачи таймера
    write(TSS_SEG_TIMER, dtss);

    // Создать IRQ(0) на таймер (TASK GATE)
    idt_put_descriptor(0x20, create_task_gate(dtss, 0));        
}

// Определение границ памяти
// -------------------------------------------------------
void memory_search()
{
    uint32_t i, j, k, n;

    // Проверить 4095 блоков (по 1 мб блок)
    for (i = 0x1; i < 0x0FFF; i++) 
    {
        k = i * 0x100000;

        asm("mov esi, %0" : : "m"(k));
        asm("mov [fs:esi + 0xFFFC], dword 0x55aa55aa");
        asm("mov %0, [fs:esi+ 0xFFFC]" : "=r"(n));

        // Если будет не 55aa55aa:
        if (n == 0xffffffff) 
        {
            write(PHYS_MEM, k);
            break;
        }
    }
}

// Инициализировать страничник
// -------------------------------------------------------
void set_paging()
{
    uint32_t i, j, pmax = read(PHYS_MEM), page;

    // Очищаем PDBR
    for (i = 0; i < 4096; i++) write(CR3_PDBR0 + 4*i, 0);           

    // Первый 1 мб ( P=1, R/W = 1, U/S = 0)
    // Первый каталог занят полностью
    write(CR3_PDBR0, 0x203); 

    // Инициализировать первые 4 мб памяти (это системная память)
    // Есть U-бит (0x200), система знает о том, чта страница занята
    for (i = 0; i < 1024; i++) write(4*i, (i << 12) | 0x203);

    // Инициализация всей памяти (последовательный способ)
    for (i = 1; i < (pmax >> 22); i++) 
    {
        page = ((i << 22) - 4096);

        // В последнюю инициализированную страницу предыдущего каталога
        // записывается следующий каталог
        // Нет U-бита, каталог занят >> не полностью <<
        write(CR3_PDBR0 + 4*i, page | 0x3); 

        // Записываются в эту страницу ссылки на все остальные страницы
        // У страниц нет U-бита, что означает, что они не заняты
        for (j = 0; j < 1024; j++) write(page + 4*j, ((i<<22) + j*4096) | 0x03);
    }
 
    // Загрузка в CR3 нового значения и установка
    cr3_load(CR3_PDBR0);
}

// Инициализация системных значений
void init_sys_vars()
{
    debugger_init();   // Инициализация отладчика
}

// Выполнение процедур запуска
// ---------------------------------------------------------------------------------
void bootstrap_main()
{
    // Создаем дескриптор для данных в видеопамяти
    uint16_t dd = put_gdt_descriptor(create_descriptor(0xA0000, 0x0001FFFF, (GDT_DATA_PL0)), 0);

    // Загружаем дескриптор видеопамяти [не менять больше этот сегмент!]
    asm("mov ax, %0" : : "m"(dd));
    asm("mov gs, ax");
    write(GS_SEG, dd); // 0x28

    // Процессор переведен в защищенный режим и установлены сегменты
    coclear(0x07);
    coprintf(0, 0, "CPU now in Protected Mode", 0x0E);    
    conlogotype();
    
    // Перенаправить IRQ на другие вектора    
    IRQ_redirect();  
    coprintf(0, 1, "IRQ configured (PIC)", 0x03);    

    // Инициализация всех векторов    
    Init_Interrupts(); 
    coprintf(0, 2, "Interrups configured", 0x03);    

    // Конфигурация мыши
    ps2_mouse_init(); 
    coprintf(0, 3, "PS/2 Mouse initialized", 0x03);    

    // Таймер
    timer_init();
    coprintf(0, 4, "Timer is 100Hz", 0x03);    

    // Поиск максимально доступной памяти (работает на реальной машине)
    memory_search(); 

    coprintf(0, 5, "Memory size: ", 0x03);
    coprinth(13, 5, read(PHYS_MEM), 0x03, 32);

    // Очистка памяти (HiMem: 3Мб) Работает на RealMachine
    repstosd(0x081000, 0x400,  0);  // 1kb
    repstosd(0x100000, 786432, 0); 

    // Страничная адресация
    set_paging();    
    coprintf(0, 6, "Paging init (4MB)", 0x0A);    

    // Создание основного TSS
    tss_create_main(dd);
    coprintf(0, 7, "Core task created", 0x03);    

    // Создание TSS задачи таймера
    tss_timer_task(dd);
    coprintf(0, 8, "Timer task created", 0x03);    
    coprintf(0, 9, "Multitasking ON", 0x0A);

    // Инициализация память
    coprintf(0, 10, "System memory initialized (3Mb)", 0x03);    

    // Установка видеорежима 80x25
    set_video_mode(3);
    update_cursor(50, 0);
    coprintf(0, 11, "Update video mode fonts (80x25)", 0x0A);    

    // Сброс системных значений
    init_sys_vars();   

    // Инициализация жестких дисков 
    drive_initialize();
}