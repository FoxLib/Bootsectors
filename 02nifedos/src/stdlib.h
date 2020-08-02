
uint32_t malloc_cursor;
uint32_t malloc_count;
uint32_t mem_max_size;

struct MallocItem {
    uint8_t  attr;
    uint32_t address;
    uint32_t size;
};

// Выделенные области
struct MallocItem malloc_items[1024];

void  stdlib_init();
byte* malloc(int n);
void  free(byte* a);
