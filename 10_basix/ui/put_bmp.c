#include "put_bmp.h"

/*
 * Загрузка изображения BMP в память
 * return указатель на полученные разобранные данные
 * 
 * СТРУКТУРА:
 * (dword) width
 * (dword) height
 * ....    data
 */
 
uint32_t ui_load_bmp(const char* filename) {
    
    int i, j;
    unsigned char buffer[4096];
    
    // Открытие файла
    int fd = fopen(filename);
    
    if (fd) {
        
        // Прочесть заголовок + DWORD следующего заголовка
        fread(buffer, 0x12, fd);
    
        uint16_t magic = *((uint16_t*)buffer);
        uint16_t sizeh = *((uint16_t*)(buffer + 0x0E));
        uint32_t pix   = *((uint32_t*)(buffer + 0x0A));

        // Это 32-х битный BMP?
        if (magic == 0x4D42 && sizeh != 12) {

            // Прочитать весь заголовок до пиксельных данных
            fread(buffer, pix - 0x12, fd);

            // Информация об изображении
            uint16_t width  = *((uint16_t*)(buffer));
            uint16_t height = *((uint16_t*)(buffer + 4));
            uint16_t bits   = *((uint16_t*)(buffer + 10)); // 10 = 0Eh - 4h

            // Указатель на палитру цветов
            uint8_t* colors = (uint8_t*)(buffer + sizeh - 4);

            // Построение таблицы конвертации файла
            if (bits == 4 || bits == 8) {

                for (i = 0; i < (bits == 4 ? 16 : 256); i++) {
                
                    uint8_t  closest = 0;
                    uint32_t closest_diff = -1;
                    uint32_t diff;

                    for (j = 0; j < 16; j++) {
                                  
                         diff = color_distance(
                            colors[i*4 + 2],
                            colors[i*4 + 1],
                            colors[i*4 + 0],
                            vga_palette_16[j*3 + 0],
                            vga_palette_16[j*3 + 1],
                            vga_palette_16[j*3 + 2]
                        );
                        
                        if (closest_diff > diff) {
                            closest_diff = diff;
                            closest = j;
                        }                                        
                    }
                    
                    bmp_palette_convert[i] = closest;
                }
            }
            
            // Сколько байт требуется скачать из файла
            int rsize;
            
            // Количество выделяемой памяти (всегда 4 битное)
            int msize = (width * height) >> 1;
            
            // Выделение новой области памяти (через malloc)
            if (bits == 4) 
                rsize = msize;
            else if (bits == 8) {
                rsize = 2 * msize;
                msize++;
            }
                        
            // 4 (width) + 4 (height)
            uint32_t bmp = malloc(8 + msize);
            uint32_t tmp = bmp + 8;
            
            // Копирование INFO
            mm_writed(bmp, width);
            mm_writed(bmp + 4, height);
            
            // Скачивание файла по частям и прогон конвертации
            if (bmp) {

                int odd = 0;
                uint32_t btmp = 0;
                
                while (rsize > 0) {
                    
                    uint16_t num = fread(buffer, 4096, fd);

                    for (i = 0; i < num; i++) {
                        
                        uint8_t pixel = buffer[i];

                        // Конвертирование двух нибблов в верные цвета
                        if (bits == 4) {

                            pixel = (bmp_palette_convert[ (pixel & 0x0f) ]) |                                     
                                    (bmp_palette_convert[ (pixel & 0xf0) >> 4 ] << 4);
                                      
                            mm_writeb(tmp, pixel);
                            tmp++;

                        // BYTE -> 2 x HALFBYTE
                        } else if (bits == 8) {

                            // В виде потока, писать полубайты
                            btmp = btmp | (bmp_palette_convert[ pixel ]) << ((1 - odd) * 4);
                            mm_writeb(tmp, btmp);
                            
                            odd++;
                            
                            if (odd == 2) {
                                odd = 0;
                                btmp = 0;
                                tmp++;
                            }
                        }
                    }

                    rsize -= num;                    
                }

                fclose(fd);
                return bmp;    
            }
        }
        
        fclose(fd);        
    }
    
    return 0;
}

// Рисование изображения, начиная с (x,y), но только в выбранном регионе (x1,y1)-(x2,y2)
void ui_put_bmp_region(uint32_t picture, int x, int y, int x1, int y1, int x2, int y2, int opacity) {
    
    int i, j, k;

    if (picture == 0) {
        return;
    }

    // Где находятся пиксельные данные
    uint16_t width  = mm_readd(picture);
    uint16_t height = mm_readd(picture + 4);
    uint32_t pix    = picture + 8;
    
    if (x > x2) {
        return;
    }
    
    if (y > y2) {
        return;
    }

    if ((x + width <= x1) || (y + height <= y1)) {
        return;
    }

    // Коррекция региона
    int x_start  = x < x1 ? x1 - x : 0;
    int y_start  = y < y1 ? y1 - y : 0;
    int x_width  = x + width > x2 ? x2 - x : width;
    int y_height = y + height > y2 ? y2 - y : height;
    
    for (i = y_start; i < y_height; i++) {
        for (j = x_start; j < x_width; j++) {

            uint32_t y_asc = height - i - 1;
            uint32_t pixel = j + y_asc * width;
            uint32_t shift = pixel >> 1;
            uint8_t  color = mm_readb(pix + shift);
            
            color = pixel % 2 ? color & 0xf : color >> 4;
            
            if (opacity == color) {
                continue;
            }

            display_vga_pixel(x + j, y + i, color);    
        }
    }
}

/*
 * Рисование BMP на экране
 * Должна быть ссылка на валидную структуру
 */
 
void ui_put_bmp(uint32_t picture, int x, int y, uint32_t opacity) {

    // Рисование региона, ограниченного размером экрана
    ui_put_bmp_region(picture, x, y, 0, 0, 639, 479, opacity);    
}
