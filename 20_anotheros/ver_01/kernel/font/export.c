// gcc export.c -o export && ./export

#include "font_tahoma.h"
#include <stdio.h>
#include <stdlib.h>

void main() {
    
    FILE* fo = fopen("tahoma.bin", "wb+");
    
    int i;
    
    // Шрифт
    for (i = 0; i < 2040; i++) {
        fwrite((char*)font_tahoma + i, 1, 1, fo);
    }
    
    // Позиции x,y,size
    for (i = 0; i < 768; i++) {
        fwrite((char*)font_tahoma_positions + i, 1, 1, fo);
    }

    fclose(fo);    
}
