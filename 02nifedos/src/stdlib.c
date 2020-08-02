#include "stddef.h"
#include "stdlib.h"

void stdlib_init() {

    malloc_cursor = 0x00400000; // 4mb
    malloc_count  = 0;

    // Поиск объема памяти
    uint32_t vm_min = 0x00400000;
    uint32_t vm_max = 0xE0000000;

    for (int i = 0; i < 32; i++) {

        uint32_t vm_mid = (vm_min + vm_max) >> 1;
        volatile uint8_t* b = (uint8_t*) vm_mid;

        uint8_t t1 = b[0]; b[0] ^= 0x55;
        uint8_t t2 = b[0]; b[0] ^= 0x55;

        if (t1 == t2) {
            vm_max = vm_mid; // Перелет
        } else {
            vm_min = vm_mid; // Недолет
        }
    }

    mem_max_size = vm_min;
}

// Выделение блока памяти (тупо пока что так)
uint32_t malloc(int n) {

    uint32_t np = malloc_cursor;

    // Занесение в словарь
    malloc_items[malloc_count].address = malloc_cursor;
    malloc_items[malloc_count].size    = n;
    malloc_items[malloc_count].attr    = 1; // Active

    malloc_cursor += n;
    malloc_count++;

    return np;
}

void free(byte* a) {
}
