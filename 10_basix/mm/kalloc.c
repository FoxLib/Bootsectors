/*
 * Выделение новой памяти на пространстве ядра
 * F0000000h - Fxxxxxxxh
 * 
 * Память выделяется блоками по 4кб, не монолитными, а последовательно,
 * по мере увеличения, добавляются новые блоки в конец.
 */
 
uint32_t kalloc(uint32_t size) {
    
    uint32_t* pdbr = (uint32_t*)PDBR_ADDRESS;    
    uint32_t cursor;
    uint32_t alloc_addr = mm_sysdata_up;

    for (cursor = mm_sysdata_up; cursor < mm_sysdata_up + size; cursor += 4096) {
        
        uint32_t dir_id = (cursor >> 22);
        uint32_t page_id = (cursor >> 12) & 0x3FF;
        uint32_t mm_cursor = dir_id - 960;
        
        // Страницы пока что не существует - создать ее
        if (mm_allocator[ mm_cursor ] == 0) {
            mm_allocator[ mm_cursor ] = palloc();
        }
        
        // Указатель именно на страницу
        pdbr[ dir_id ] = (mm_allocator[ mm_cursor ]) | 3;
        
        // А теперь указываем в странице на нужный нам кусок памяти
        uint32_t* pagemap = (uint32_t*)mm_allocator[ mm_cursor ];
        
        // Необходимая область памяти
        if (!(pagemap[ page_id ] & PT_PRESENT)) {                    
            pagemap[ page_id ] = palloc() | 3;
        }
    }

    // Отметка вершины
    mm_sysdata_up += size;
    
    return alloc_addr;
    
}


// Выделение новой области памяти ядра, с записью информации о размере
uint32_t malloc(uint32_t size) {
    
    // --- сделать проверку на пустые области
        
    uint32_t alloc = kalloc(size + 4);
    if (alloc) {
        
        mm_writed(alloc, size);
        return alloc + 4;
    }
    
    return 0;

}

