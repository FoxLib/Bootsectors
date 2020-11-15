#define PT_PRESENT          0x001
#define PT_US               0x004
#define PT_RW               0x002
#define PT_FULL             0x800

#define PDBR_ADDRESS        0x1000
#define CATALOG_FIRST4MB    0x2000
#define TEMPAGE_ADDRESS     0x4000

// Максимальный объем памяти
uint32_t mm_top;

// Вершина выделенной области для данных
uint32_t mm_sysdata_up;

// 4кб/4мб страница с указателями на память для системных нужд (4 мб x 64 = 256)
uint32_t mm_allocator[64];
