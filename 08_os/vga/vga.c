#include "vga.h"

/*
 * Установка видеорежима HI (640x480x4)
 */

void vga_videomode(u8* regs) {

    u32 i, id = 0;

    // Этап 0. MISC регистр
    IoWrite8(VGA_MISC_WRITE, regs[ id++ ]);

    // Запись регистров SEQUENCER
    for (i = 0; i < VGA_NUM_SEQ_REGS; i++) {

        IoWrite8(VGA_SEQ_INDEX, i);
        IoWrite8(VGA_SEQ_DATA,  regs[ id++ ]);

    }

    /*
     * Честно говоря, я не знаю, зачем эта секция.
     * Я ее просто скопировал из источника и немного поправил для своей ОС
     */

    // Разблокируем CRTC регистры
    IoWrite8(VGA_CRTC_INDEX, 0x03);
    IoWrite8(VGA_CRTC_DATA,  IoRead8(VGA_CRTC_DATA) | 0x80);

    IoWrite8(VGA_CRTC_INDEX, 0x11);
    IoWrite8(VGA_CRTC_DATA,  IoRead8(VGA_CRTC_DATA) & 0x7F);

    // Оставить разблокированными (в данных)
    regs[ id + 0x03 ] |= (u8)0x80;
    regs[ id + 0x11 ] &= (u8)0x7F;    

    // Этап 1. Запись CRTC
    for (i = 0; i < VGA_NUM_CRTC_REGS; i++) {

        IoWrite8(VGA_CRTC_INDEX, i);
        IoWrite8(VGA_CRTC_DATA,  regs[ id++ ]);

    }

    // Этап 2. Запись GRAPHICS CONTROLLER
    for (i = 0; i < VGA_NUM_GC_REGS; i++) {

        IoWrite8(VGA_GC_INDEX, i);
        IoWrite8(VGA_GC_DATA,  regs[ id++ ]);

    }

    // Этап 3. Запись ATTRIBUTE CONTROLLER
    for (i = 0; i < VGA_NUM_AC_REGS; i++) {

        IoWrite8(VGA_AC_INDEX, i);
        IoWrite8(VGA_AC_WRITE, regs[ id++ ]);

    }

    IoRead8(VGA_INSTAT_READ);
    IoWrite8(VGA_AC_INDEX, 0x20);
}

/*
 * Установка битовой карты по умолчанию (белый цвет)
 */

void vga_bitclr() {
	
    IoWrite16(VGA_GC_INDEX, 0x0205);
    IoWrite16(VGA_GC_INDEX, 0xFF08);
}

/*
 * Полная очистка экрана
 */

void vga_cls() {
    
    u16 i; 
    for (i = 0; i < 38400; i++) {
        VGAMEM[i] = (u8)0x00;
    }
}

/* 
 * Простановка цвета пикселя 0..255
 */
void vga_dac_set(u8 n, u32 c) {

    IoWrite8(VGA_DAC_WRITE_INDEX, n);
    IoWrite8(VGA_DAC_DATA, (c >> 2) & 0x3f);
    IoWrite8(VGA_DAC_DATA, (c >> 10) & 0x3f);
    IoWrite8(VGA_DAC_DATA, (c >> 18) & 0x3f);
}

/*
 * Установка и настройка видеорежима 640x480
 */
void vga_set_hicolor() {
    
    vga_videomode(vgamode_640x480);     // Установка видеорежима
    vga_bitclr();                       // Сброс режима маскирования
    vga_dac_set(15, 0xffffff);

}

/*
 * Принудительная запись с "защелкой" для срабатывания маски 
 */
inline void vga_wr(u32 addr, u8 c) {

    volatile u8 t = VGAMEM[addr];
    VGAMEM[addr] = c;
}

/*
 * Нарисовать закрашенный прямоугольник
 * (x1,y1,x2,y2,цвет), цвет=0..15
 *
 * Основано на одном из режимов (8-й режим) рисования VGA, когда
 * мы пишем в память цвет, но цвет пишется только в ту маску пикселей, которую мы задали 
 */

void vga_fillrect(u16 x1, u16 y1, u16 x2, u16 y2, u8 c) {

    u16 i, j;

    // Выбор регистра Режим (5) и одновременная установка режима 2 (маски)
    IoWrite16(VGA_GC_INDEX, 0x0205); 
                                     
    // Нахождение маски для первой линия (слева)
    u16 m1 = (1 << (8 - (x1 & 7))) - 1;
    u16 m2 = ((0x7f80) >> (x2 & 7)) & 0xff;
    u16 xa = (x1 >> 3);
    u16 xb = (x2 >> 3);

    // (1) Рисование "длинного" по горизонтали прямоугольника
    if (xb > xa) {

        // А. Рисовать левую половину
        IoWrite16(VGA_GC_INDEX, 0x0008 | (m1 << 8)); 
        for (i = y1; i <= y2; i++) {
            vga_wr(80*i + xa, c); 
        }

        // B. Сплошная линия (по 8 бит)
        IoWrite16(VGA_GC_INDEX, 0xFF08); 
        for (i = xa + 1; i < xb; i++) {
            for (j = y1; j <= y2; j++) {
                vga_wr(80*j + i, c);
            }
        }
       
        // C. Рисовать правую половину
        IoWrite16(VGA_GC_INDEX, 0x0008 | (m2 << 8)); 
        for (i = y1; i <= y2; i++) {
            vga_wr(80*i + xb, c);
        }

    // (2) В случае, если границы находятся на одном 8-битном столбце
    } else { 

        IoWrite16(VGA_GC_INDEX, 0x0008 | ((m1 & m2) << 8)); 
        for (i = y1; i <= y2; i++) {
            vga_wr(80*i + xa, c);
        }
    }
}

/*
 * Нарисовать пиксель
 */

void vga_pixel(u16 x, u16 y, u8 c) 
{
    IoWrite16(VGA_GC_INDEX, 0x0008 | (0x8000 >> (x & 7))); 
    vga_wr(y*80 + (x >> 3), c);
}

/*
 * Рисование линии на экране
 */
void vga_line(u16 x1, u16 y1, u16 x2, u16 y2, u8 c) {

    int deltax = (x2 > x1) ? x2 - x1 : x1 - x2;
    int deltay = (y2 > y1) ? y2 - y1 : y1 - y2;
    int signx  = x1 < x2 ? 1 : -1;
    int signy  = y1 < y2 ? 1 : -1;

    int error = deltax - deltay;
    int error2;

    vga_pixel(x2, y2, c);

    while (x1 != x2 || y1 != y2)
    {
        vga_pixel(x1, y1, c);
        error2 = error * 2;

        if (error2 > -deltay) {
            error -= deltay;
            x1 += signx;
        }

        if (error2 < deltax) {
            error += deltax;
            y1 += signy;
        }
    }
}

/*
 * Рисовать прямоугольник
 */

void vga_rect(u16 x1, u16 y1, u16 x2, u16 y2, u8 c) {

    vga_line(x1, y1, x2, y1, c);
    vga_line(x2, y1, x2, y2, c);
    vga_line(x2, y2, x1, y2, c);
    vga_line(x1, y2, x1, y1, c);
}

/*
 * Рисование символа
 */
void vga_put_char(u16 x, u16 y, unsigned char chr, u8 c) {

    int i, j;
    u8 font;

    for (i = 0; i < 16; i++) {

        font = bios_font[chr*16 + i];
        for (j = 0; j < 8; j++) {
            if (font & (1 << j)) {
                vga_pixel(x + j, y + i, c);
            }            
        }
    }

}

/*
 * Вывести строку
 */

void vga_put_zstring(u16 x, u16 y, char* str, u8 c) {

    while (*str) {

        vga_put_char(x, y, *str, c);
        x += 8;
        str++;

    }

}