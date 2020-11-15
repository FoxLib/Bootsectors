// Адрес кучи (XMA)
#define HEAP 0x00100000

// Биты параметров страниц
#define PG_PRESENT     1
#define PG_US          2

/*
 * Области памяти
 */

u8* mem_top     = (u8*)HEAP;       // Верхняя область памяти (для sysmalloc)
u8* mem_sys     = 0;
u8* data_pdbr   = 0;               // Страница глобального каталога 
u32 mem_size    = 0;               // Объем памяти в байтах (по гранулам 4Мб)

/*
 * Клавиатура 
 */
 
u8* mem_keyb_pressed = 0;
u8* mem_keyb_buffer  = 0;

// ---
u16 sys_task_last = 0;             // Последний элемент (количество задач)
SysTask* data_sys_task = 0;        // Массив с элементами (открытыми окнами)

