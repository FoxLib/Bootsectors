void ui_handler(uint32_t* stack) {
    
    // Тут находится значения от запрошенного EDX
    uint32_t edx = *(stack + 3);
    
    // Анализ запроса
    switch (edx) {
        
        // ...
        case 0: display_vga_pixel(1,2,3); break;
        
    }

}
