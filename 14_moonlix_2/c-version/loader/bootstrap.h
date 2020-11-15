// Структура дескриптора
struct gdt_t 
{
    uint16_t addr_low;
    uint16_t limit_low;
    uint8_t  addr_hl;
    uint8_t  access;
    uint8_t  limit_hi_flags;
    uint8_t  addr_hh;
} gdt_t;
