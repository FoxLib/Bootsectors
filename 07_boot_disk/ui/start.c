/*
 * Выдача меню
 */
 
static const char* menu [3] = {
    "README",
    "ZX Spectrum Experience",
    "Homebrew BASIC"
};

// Выдача и обработка стартового простого интерфейса
void ui_start() {
    
    int i;
    
    display_cursor_at(16,5);
    display_cursor_mode(0,15);
    
    display_bgblock(0, 0, 2000, 0x70); // Очистить экран (цвет)
    display_frame(0xf, 0x5, 0x41, 0x14); // Нарисовать фрейм

    // Заголовок
    display_text(0x10, 0x05, " DISKETTE DREAM 2000/11 ");
    display_bgblock(0x10, 0x05, 24, 0x47);
        
    for (i = 0; i < 3; i++) {    
        display_text(0x11, 0x07 + i, (char*)menu[i]);
    }
    
    display_bgblock(0x10, 0x07, 49, 0x07);
}
