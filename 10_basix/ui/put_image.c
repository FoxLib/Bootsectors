#include "put_gif.c"
#include "put_bmp.c"

/*
 * Рисование изображения на экране
 */
 
void ui_put_image(uint32_t addr, int x, int y) {
    
    uint32_t magic = mm_readd(addr);
    
    // GIF8(7/9)a
    if (magic == 0x38464947) {        
        ui_put_gif(addr, x, y);        
    }
    // BMP
    else if ((magic & 0xffff) == 0x4D42) {
        ui_put_bmp(addr, x, y, -1);        
    }
    
}
