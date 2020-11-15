/*
 * 1mb     Ядро
 * 2-32mb  Область системных данных
 * 32..n   Физическая свободная память
 * n...3gb Виртуальная память
 */
 
#define NULL            (void*)0 // Алиас

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

#define SYSMEM          8       // Минимальное количество памяти для ядра (мб)

uint32_t*   PDBR;           // Page Directory Base Root
uint32_t*   CPage;          // Особая страница для создания других страниц
uint32_t*   PTE;            // Страницы каталогов page tables

uint32_t    mem_max;        // Память для системы
uint32_t    mem_real_max;   // Реальное кол-в памяти 
uint32_t    mem_lower;      // Нижняя граница свободного пространства

void* kalloc(size_t);
