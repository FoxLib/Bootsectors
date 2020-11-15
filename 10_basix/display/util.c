/*
 * Утилиты для рисования на текстовом дисплее 
 */

// Рисование блока (фонового), начиная с [x,y] позиции
void display_bgblock(int x, int y, int length, char bgcolor) {
        
    int i;
    char* addr = DISPLAY_TEXT_ADDR + (x + y*80) * 2;
    
    for (i = 0; i < length; i++) {
        addr[2*i + 1] = bgcolor;
    }    
}

// Рисование фрейма
void display_frame(int x1, int y1, int x2, int y2) {
    
    int i;
    char* addr = DISPLAY_TEXT_ADDR;
    
    // Уголки
    addr[ 2*(x1 +y1*80) ] = 0xDA;
    addr[ 2*(x2 +y1*80) ] = 0xBF;
    addr[ 2*(x1 +y2*80) ] = 0xC0;
    addr[ 2*(x2 +y2*80) ] = 0xD9;
    
    // Горизонтальные линии
    for (i = x1 + 1; i < x2; i++) {
        addr[ 2*(i + y1*80) ] = 0xC4;
        addr[ 2*(i + y2*80) ] = 0xC4;
    }
    
    // Вертикальные линиии
    for (i = y1 + 1; i < y2; i++) {
        addr[ 2*(x1 + i*80) ] = 0xB3;
        addr[ 2*(x2 + i*80) ] = 0xB3;
    }
}

// Печать строки
void display_text(int x1, int y1, char* string) {
    
    char* addr = DISPLAY_TEXT_ADDR + 2*(x1 + y1*80);
    
    while (*string) {
        
        *addr = *string;
        addr += 2;
        string++;
    }
    
}

// Положение курсора
void display_cursor_at(int x, int y)
{
	uint16_t pos = y * 80 + x;
 
	IoWrite8(0x3D4, 0x0F);
	IoWrite8(0x3D5, (uint8_t) (pos & 0xFF));
    
	IoWrite8(0x3D4, 0x0E);
	IoWrite8(0x3D5, (uint8_t) ((pos >> 8) & 0xFF));
}

// Режим курсора
void display_cursor_mode(uint8_t cursor_start, uint8_t cursor_end)
{
	IoWrite8(0x3D4, 0x0A);
	IoWrite8(0x3D5, (IoRead8(0x3D5) & 0xC0) | cursor_start);
 
	IoWrite8(0x3D4, 0x0B);
	IoWrite8(0x3D5, (IoRead8(0x3E0) & 0xE0) | cursor_end);
}
