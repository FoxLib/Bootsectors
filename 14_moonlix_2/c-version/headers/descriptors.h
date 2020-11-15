// Описатели дескрипторов
// ----------------------

// Устройство дескриптора
//
// 63           56  55  54  53  52  51         48   47 46 45  44 43  41  40  39       16  15           0
// +--------------+---+---+---+---+---------------+---+-----+---+------+---+-------------+--------------+
// | Адрес 24..31 | G | D | L | U | Предел 16..19 | P | DPL | S | TYPE | A | Адрес 0..23 | Предел 0..15 |
// +--------------+---+---+---+---+---------------+---+-----+---+------+---+-------------+--------------+
//               7                              6                         5             2              0

#define SEG_DESCTYPE(x)  ((x) << 0x04) // Descriptor type (0 for system, 1 for code/data)
#define SEG_PRES(x)      ((x) << 0x07) // Present
#define SEG_SAVL(x)      ((x) << 0x0C) // Available for system use
#define SEG_LONG(x)      ((x) << 0x0D) // Long mode 
#define SEG_SIZE(x)      ((x) << 0x0E) // Size (0 for 16-bit, 1 for 32)
#define SEG_GRAN(x)      ((x) << 0x0F) // Granularity (0 for 1B - 1MB, 1 for 4KB - 4GB)
#define SEG_PRIV(x)     (((x) &  0x03) << 0x05)   // Set privilege level (0 - 3)                         

#define GDT_CODE_PL0 SEG_DESCTYPE(1) | SEG_PRES(1) | SEG_SAVL(0) | \
                     SEG_LONG(0)     | SEG_SIZE(1) | SEG_GRAN(1) | \
                     SEG_PRIV(0)     | SEG_CODE_EXRD
 
// Данные, 0 RING
#define GDT_DATA_PL0 SEG_DESCTYPE(1) | SEG_PRES(1) | SEG_SAVL(0) | \
                     SEG_LONG(0)     | SEG_SIZE(0) | SEG_GRAN(0) | \
                     SEG_PRIV(0)     | SEG_DATA_RDWR
 
#define GDT_DATA_PL3 SEG_DESCTYPE(1) | SEG_PRES(1) | SEG_SAVL(0) | \
                     SEG_LONG(0)     | SEG_SIZE(0) | SEG_GRAN(0) | \
                     SEG_PRIV(3)     | SEG_DATA_RDWR
 

// Типы сегментов
// -----------------------------------------------------------------------------
#define GATE_TYPE_NONE                       0x0
#define SYS_SEGMENT_AVAIL_286_TSS            0x1
#define SYS_SEGMENT_LDT                      0x2
#define SYS_SEGMENT_BUSY_286_TSS             0x3
#define SYS_286_CALL_GATE                    0x4
#define TASK_GATE                            0x5
#define SYS_286_INTERRUPT_GATE               0x6
#define SYS_286_TRAP_GATE                    0x7
;                                    /* 0x8 reserved */
#define SYS_SEGMENT_AVAIL_386_TSS            0x9
;                                    /* 0xa reserved */
#define SYS_SEGMENT_BUSY_386_TSS             0xb
#define SYS_386_CALL_GATE                    0xc
;                                    /* 0xd reserved */
#define SYS_386_INTERRUPT_GATE               0xe
#define SYS_386_TRAP_GATE                    0xf

// -----------------------------------------------------------------------------
#define SEG_DATA_RD        0x00 // Read-Only
#define SEG_DATA_RDA       0x01 // Read-Only, accessed
#define SEG_DATA_RDWR      0x02 // Read/Write
#define SEG_DATA_RDWRA     0x03 // Read/Write, accessed
#define SEG_DATA_RDEXPD    0x04 // Read-Only, expand-down
#define SEG_DATA_RDEXPDA   0x05 // Read-Only, expand-down, accessed
#define SEG_DATA_RDWREXPD  0x06 // Read/Write, expand-down
#define SEG_DATA_RDWREXPDA 0x07 // Read/Write, expand-down, accessed
#define SEG_CODE_EX        0x08 // Execute-Only
#define SEG_CODE_EXA       0x09 // Execute-Only, accessed
#define SEG_CODE_EXRD      0x0A // Execute/Read
#define SEG_CODE_EXRDA     0x0B // Execute/Read, accessed
#define SEG_CODE_EXC       0x0C // Execute-Only, conforming
#define SEG_CODE_EXCA      0x0D // Execute-Only, conforming, accessed
#define SEG_CODE_EXRDC     0x0E // Execute/Read, conforming
#define SEG_CODE_EXRDCA    0x0F // Execute/Read, conforming, accessed

/*
Структура шлюза прерывания
=======================

   63                  48  47  46 45  44      40  39  37 36     32
 +-----------------------+---+------+-----------+-------+---------+
 | Смещение, биты 16..31 | P | DPL  | 0 1 1 1 0 | 0 0 0 |         |
 +-----------------------+---+------+-----------+-------+---------+
 
   31                  16 15                                     0
 +-----------------------+----------------------------------------+
 | Селектор сегмента     | Смещение, биты 0..15                   |
 +-----------------------+----------------------------------------+

GATE_INTERRUPT address32, selector
{
    dw (address32 and 0xFFFF)
    dw selector
    db 0
    db 10001110b ; Present, DPL=0, DefaultSize=32 bit
    dw ((address32 and 0xFFFF0000) shr 16)
}


Структура шлюза ловушки
=======================

   63                  48  47  46 45  44      40  39  37 36     32
 +-----------------------+---+------+-----------+-------+---------+
 | Смещение, биты 16..31 | P | DPL  | 0 1 1 1 1 | 0 0 0 |         |
 +-----------------------+---+------+-----------+-------+---------+
 
   31                  16 15                                     0
 +-----------------------+----------------------------------------+
 | Селектор сегмента     | Смещение, биты 0..15                   |
 +-----------------------+----------------------------------------+

GATE_TRAP address32, selector
{
    dw (address32 AND 65535)
    dw selector
    db 0
    db 10001111b ; Present, DPL=0, DefaultSize=32 bit
    dw ((address32 and 0xFFFF0000) shr 16)
}



Структура шлюза задачи
=======================

   63                  48  47  46 45  44      40  39  37 36     32
 +-----------------------+---+------+-----------+-------+---------+
 |                       | P | DPL  | 0 0 1 0 1 |                 |
 +-----------------------+---+------+-----------+-------+---------+
 
   31                  16 15                                     0
 +-----------------------+----------------------------------------+
 | Селектор TSS          |                                        |
 +-----------------------+----------------------------------------+7

GATE_TASK tss_selector
{
    dw 0
    dw tss_selector
    db 0
    db 10000101b ; Present, DPL=0
    dw 0
}
*/

#define TSS_EAX 0x28
#define TSS_EBX 0x34
#define TSS_ECX 0x2C
#define TSS_EDX 0x30
#define TSS_ESP 0x38
#define TSS_EBP 0x3C
#define TSS_ESI 0x40
#define TSS_EDI 0x44

// Сегменты
#define TSS_ES   0x48
#define TSS_CS   0x4C
#define TSS_SS   0x50
#define TSS_DS   0x54
#define TSS_FS   0x58
#define TSS_GS   0x5C

// EIP
#define TSS_EIP    0x20
#define TSS_EFLAGS 0x24

// Системные 
#define TSS_LDTR   0x60
#define TSS_CR3    0x1C
#define TSS_LINK   0x00

// Стек
#define TSS_ESP0   0x04
#define TSS_SS0    0x08

#define TSS_ESP1   0x0C
#define TSS_SS1    0x10

#define TSS_ESP2   0x14
#define TSS_SS2    0x18

// http://wiki.osdev.org/TSS
/*

-----+-- 31..16 --+-- 15..0 --+
0x00 | ---        | LINK      | Ссылка на предыдущую задачу
0x04 | ESP0                   | Стек (SS0:ESP0) для уровня 0
0x08 | ---        | SS0       |
0x0C | ESP1                   |
0x10 | ---        | SS1       |
0x14 | ESP2                   |
0x18 | ---        | SS2       |
     +------------+-----------+
0x1C | CR3                    | Указатель на механизм страничной адресации
0x20 | EIP                    |
0x24 | EFLAGS                 |
0x28 | EAX                    |
0x2C | ECX                    |
0x30 | EDX                    |
0x34 | EBX                    |
0x38 | ESP                    |
0x3C | EBP                    |
0x40 | ESI                    |
0x44 | EDI                    |
     +------------+-----------+
0x48 | ---        | ES        |
0x4C | ---        | CS        |
0x50 | ---        | SS        |
0x54 | ---        | DS        |
0x58 | ---        | FS        |
0x5C | ---        | GS        |
0x60 | ---        | LDTR      |
0x64 |IOPB offset | ---       |
     +------------+-----------+

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Описатель очереди (32 байта)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
00 word TSS        -- если < 30, то поле имеет статус, если = 0, то свободное
02 word hwnd       -- для какого окна (может быть 0, если для процесса)
04 word ACTION     -- номер действия
06 word <reserved>
08 dword DATA      -- данные или указатель
0C dword timestamp -- время события (если долго не закрывается, освобождение)
...



ACTIONS:

0 Ничего не делать
1 Обновление окна
2 Получение символа
3 Завершить
4 Свернуть
5 Развернуть

*/