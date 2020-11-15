#include "tahoma.h"

// Пропечатка шрифта
// Возвращается <font_size>
int font_tahoma_printc(int x, int y, u8 chr, u8 color) {
       
    // font_tahoma
    
    int i, j;
    
    int cp = 3 * chr;
    int font_x = font_tahoma_positions[ cp ], 
        font_y = font_tahoma_positions[ cp+1 ], 
        font_size = font_tahoma_positions[ cp+2 ];
        
    for (i = font_y; i < font_y + 12; i++) {
        
        for (j = font_x; j < font_x + font_size; j++) {
            
            if (font_tahoma[ i*15 + (j >> 3) ] & (1 << (7 - (j & 7))))
                pixel(x, y, color);
            
            x++;
            
        }
        
        x -= font_size;
        y++;
    }    
    
    return font_size;   
}

// Печать строки (обычной, не BOLD)
// @return последняя позиция
int font_tahoma_prints(int x, int y, char* s, u8 color) {
    
    int x_start = x;
    while (*s) {       

        x += font_tahoma_printc(x, y, *s, color);   
        s++;
    }
    
    return x;
}

// Печать строки BOLD
// @return последняя позиция
int font_tahoma_prints_bold(int x, int y, char* s, u8 color) {
    
    int x_start = x;
    
    while (*s) {       

             font_tahoma_printc(x, y, *s, color); 
             x++;
        x += font_tahoma_printc(x, y, *s, color);
        
        s++;
    }
    
    return x;
}