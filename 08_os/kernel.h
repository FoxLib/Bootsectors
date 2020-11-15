// Определение типов

typedef char                i8;
typedef unsigned char       u8;
typedef short               i16;
typedef unsigned short      u16;
typedef int                 i32;
typedef unsigned int        u32;
typedef long long           i64;
typedef unsigned long long  u64;

typedef float               f32;
typedef double              f64;

// Определить вызов через внешнюю функцию в FASM
extern void outb(int p, u8 b) __attribute__((fastcall));
extern unsigned char inb(int p) __attribute__((fastcall));

// Прерывания
extern void _keyb_isr();
extern void _irq_cascade();
extern void _irq_isr_null();

// Досрочный выход из прерывания
#define sti             __asm__ volatile("sti");
#define cli             __asm__ volatile("cli");

// --------------------------------------------------------------

/*
 * Структура задачи
 */

typedef struct  {

    u8   app_class;         // Класс приложения (ID)
    u8   flags;             // Флаги
    u8*  mmap;              // Указатель на 4096-байтную страницу, где располагается карта памяти (4Мб)
                            // То есть приложение может базово выделить себе при старте только 4Мб

} SysTask;

/*
 * Структура события
 */

typedef struct  {

    u8  event_type;  // Тип события
    u16 app_id;      // Номер приложения или окна

} SysEvent;
