
// Макросы для управления процессором
// ---------------------------------------------------------------------

#define brk __asm__ __volatile__("xchg %bx, %bx");
#define sti __asm__ __volatile__("sti");
#define cli __asm__ __volatile__("cli");

// Типы данных
// ---------------------------------------------------------------------
// См. http://ru.cppreference.com/w/cpp/language/types

#define byte     unsigned char          //  8 bit
#define word     unsigned short         // 16 bit
#define uint     unsigned int           // 32 bit
#define dword    unsigned int           // 32 bit
#define ulong    unsigned long long     // 64 bit
#define qword    unsigned long long     // 64 bit
#define NULL     (void*)0               // Алиас

// Описание полей дескриптора
#define D_PRESENT       0x80
#define T_TSS_AVAIL     0x09

// Резерв для системной памяти
#define SYSTEM_MEMORY_MB        8

#define PTE_PRESENT     1       // Страница в памяти присутствует
#define PTE_RW          2       // Страница доступна на запись
#define PTE_USER        4       // =0 Супервизор =1 Со всех уровней
#define PTE_PWT         8       // Сквозная запись
#define PTE_PCD         0x10    // Cache Disabled
#define PTE_ACCESS      0x20
#define PTE_DIRTY       0x40
#define PTE_PAT         0x80    // Индекс атрибута таблицы страниц
#define PTE_GLOBAL      0x100   // Глобальная страница

// Для системы
#define PTE_USER1       0x200
#define PTE_USER2       0x400
#define PTE_USER3       0x800

// Структуры
// ---------------------------------------------------------------------

// Указатель на GDT
struct __attribute__((__packed__)) GDT_ptr {

    word  limit;
    dword base;
};

// Элемент GDT http://neurofox.net/sasm/14_descriptor
struct __attribute__((__packed__)) GDT_item {

    word limit;
    word addrlo;     // 15:0  Адрес
    byte addrhl;     // 23:16 Адрес
    byte access;     //       Биты доступа и типов
    byte limithi;    // 19:16 Предел + GDXU-атрибуты
    byte addrhh;     // 31:24 Адрес
};

// 32-х битный дескриптор прерывания
struct __attribute__((__packed__)) IDT_Item {

    word low_addr;
    word selector;
    word attr;
    word hi_addr;
};

// https://wiki.osdev.org/Task_State_Segment
struct __attribute__((__packed__)) TSS_item {

    /* 00 */ dword link;
    /* 04 */ dword esp0;
    /* 08 */ dword ss0;
    /* 0C */ dword esp1;
    /* 10 */ dword ss1;
    /* 14 */ dword esp2;
    /* 18 */ dword ss2;
    /* 1C */ dword cr3;
    /* 20 */ dword eip;
    /* 24 */ dword eflags;

    /* 28 */ dword eax;
    /* 2C */ dword ecx;
    /* 30 */ dword edx;
    /* 34 */ dword ebx;
    /* 38 */ dword esp;
    /* 3C */ dword ebp;
    /* 40 */ dword esi;
    /* 44 */ dword edi;

    /* 48 */ dword es;
    /* 4C */ dword cs;
    /* 50 */ dword ss;
    /* 54 */ dword ds;
    /* 58 */ dword fs;
    /* 5C */ dword gs;
    /* 60 */ dword ldtr;
    /* 64 */ dword iobp;
};

// Прототипы
// ---------------------------------------------------------------------
void  detect_max_memory_size();
void* kalloc(uint);
void  kernel_init();

// Переменные
// ---------------------------------------------------------------------

struct GDT_item*    GDT;        // Расположение Global Descriptor Table
struct TSS_item*    TSS_Main;   // Главная задача

uint    mm_real_max;   // Объем физической памяти
uint    mm_syst_max;   // Указатель для kalloc()
dword*  PDBR;          // Page Directory Base Root / RING0

