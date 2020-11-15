#include "vga.h"

// Чтение регистров с текущего видеорежима
void display_vga_read_regs(unsigned char *regs) {
    
	unsigned i;

    /* read MISCELLANEOUS reg */
	*regs = IoRead8(VGA_MISC_READ);
	regs++;

    /* read SEQUENCER regs */
	for(i = 0; i < VGA_NUM_SEQ_REGS; i++)
	{
		IoWrite8(VGA_SEQ_INDEX, i);
		*regs = IoRead8(VGA_SEQ_DATA);
		regs++;
	}

    /* read CRTC regs */
	for(i = 0; i < VGA_NUM_CRTC_REGS; i++)
	{
		IoWrite8(VGA_CRTC_INDEX, i);
		*regs = IoRead8(VGA_CRTC_DATA);
		regs++;
	}

    /* read GRAPHICS CONTROLLER regs */
	for(i = 0; i < VGA_NUM_GC_REGS; i++)
	{
		IoWrite8(VGA_GC_INDEX, i);
		*regs = IoRead8(VGA_GC_DATA);
		regs++;
	}

    /* read ATTRIBUTE CONTROLLER regs */
	for (i = 0; i < VGA_NUM_AC_REGS; i++)
	{
		(void)IoRead8(VGA_INSTAT_READ);
		IoWrite8(VGA_AC_INDEX, i);
		*regs = IoRead8(VGA_AC_READ);
		regs++;
	}

    /* lock 16-color palette and unblank display */
	(void)IoRead8(VGA_INSTAT_READ);
	IoWrite8(VGA_AC_INDEX, 0x20);
}

// Запись регистров в VGA-контроллер
void display_vga_write_regs(unsigned char *regs) {

    unsigned i;

    /* MISCELLANEOUS регистр */
	IoWrite8(VGA_MISC_WRITE, *regs);
	regs++;

    /* SEQUENCER регистры */
	for (i = 0; i < VGA_NUM_SEQ_REGS; i++)
	{
		IoWrite8(VGA_SEQ_INDEX, i);
		IoWrite8(VGA_SEQ_DATA, *regs);
		regs++;
	}

    /* Разблокировать CRTC регистры */
	IoWrite8(VGA_CRTC_INDEX, 0x03);
	IoWrite8(VGA_CRTC_DATA, IoRead8(VGA_CRTC_DATA) | 0x80);

	IoWrite8(VGA_CRTC_INDEX, 0x11);
	IoWrite8(VGA_CRTC_DATA, IoRead8(VGA_CRTC_DATA) & ~0x80);

    /* Оставить разблокированными */
	regs[ 0x03 ] |= 0x80;
	regs[ 0x11 ] &= ~0x80;

    /* CRTC регистры */
	for (i = 0; i < VGA_NUM_CRTC_REGS; i++) {

		IoWrite8(VGA_CRTC_INDEX, i);
		IoWrite8(VGA_CRTC_DATA, *regs);
		regs++;
	}

    /* GRAPHICS CONTROLLER регистры */
	for (i = 0; i < VGA_NUM_GC_REGS; i++) {

		IoWrite8(VGA_GC_INDEX, i);
		IoWrite8(VGA_GC_DATA, *regs);
		regs++;
	}

    /* ATTRIBUTE CONTROLLER регистры */
	for (i = 0; i < VGA_NUM_AC_REGS; i++) {
		(void)IoRead8(VGA_INSTAT_READ);
		IoWrite8(VGA_AC_INDEX, i);
		IoWrite8(VGA_AC_WRITE, *regs);
		regs++;
	}

    /* Запкрепить 16-цветовую палитру и разблокировать дисплей */
	(void)IoRead8(VGA_INSTAT_READ);
	IoWrite8(VGA_AC_INDEX, 0x20);
}

// Писать пиксель
void display_vga_pixel(unsigned x, unsigned y, unsigned char c) {
    
    char* vaddr = (char*)0xA0000;
    
    if (x < 640 && y < 480) {

        uint16_t symbol = (x >> 3) + y*80;
        uint16_t mask = 0x8000 >> (x & 7);

        // Установка маски, регистр 8 (вертикальная запись в слои)
        IoWrite16(VGA_GC_INDEX, 0x08 | mask);

        // Читать перед записью, иначе не сработает
        volatile uint8_t t = vaddr[ symbol ];
        vaddr[ symbol ] = c;    
    }
}

// Установка определенного видеорежима
void display_vga_mode(int mode) {

    int i;    
    switch (mode) {

        case VGA_640x480:

            // -- todo палитру
            display_vga_write_regs( (unsigned char*)disp_vga_640x480x16 );
            
            // Режим 2 (регистр выбор режима 5) 
            // -- режим записи 1 слой цвета - 1 бит
            for (i = 0; i < 16; i++) {
                IoWrite8(VGA_DAC_WRITE_INDEX, i);
                IoWrite8(VGA_DAC_DATA, vga_palette_16[i*3 + 0] >> 2);
                IoWrite8(VGA_DAC_DATA, vga_palette_16[i*3 + 1] >> 2);
                IoWrite8(VGA_DAC_DATA, vga_palette_16[i*3 + 2] >> 2);
            }
            
            IoWrite16(VGA_GC_INDEX, 0x0205);
            break;

        case VGA_320x200:

            // -- todo палитру
            display_vga_write_regs( (unsigned char*)disp_vga_320x200x256 );
            break;
    }

    disp_vga_lastmode = mode;
}

// Быстрая очистка экрана
void display_vga_cls(int color) {

    int i;
    char* vaddr = (char*)0xA0000;

    switch (disp_vga_lastmode) {


        case VGA_640x480:
        
            IoWrite16(VGA_GC_INDEX, 0xFF08);
            for (i = 0; i < 80*480; i++) {
                volatile uint8_t t = vaddr[ i ];
                vaddr[ i ] = color;
            }

            break;
    }

}

// Печать символа на экране
void display_vga_pchar(int x, int y, unsigned char c, char color) {

    int i, j, f = c * 16;

    for (i = 0; i < 16; i++) {
        for (j = 0; j < 8; j++) {
            if (disp_vga_8x16_font[ f + i] & (1 << (7 - j)))
                display_vga_pixel(x + j, y + i, color);
        }
    }
}

// Печать строки UTF-8
void display_vga_putf8(int x, int y, char* string, char color) {

    while(*string) {

        unsigned char chr = *string;

        // Преобразовать UTF-8 в RUS
        if (chr == 0xD0) {

            string++;
            chr = (*string) - 0x10;

        }
        else if (chr == 0xD1) {

            string++;
            chr = (*string);

            if (chr < 0xB0)
                chr = chr + 0x60;
            else
                chr = chr + 0x10;
        }

        // Псевдографика недоступна
        display_vga_pchar(8*x, 16*y, chr, color);

        x += 1;
        string++;
    }

}

// Расчет дистанции (r1 - r2)^2 + (g1 - g2)^2 + (b1 - b2)^2 
uint32_t color_distance(uint8_t r1, uint8_t g1, uint8_t b1, uint8_t r2, uint8_t g2, uint8_t b2) {
    
    return (r1 - r2) * (r1 - r2) + 
           (g1 - g2) * (g1 - g2) + 
           (b1 - b2) * (b1 - b2); 
}

// 50% полупрозрачный блок сплошного цвета
void display_vga_dotted_block(int x1, int y1, int x2, int y2, uint8_t color) {
    
    int i, j;    
    for (i = y1; i <= y2; i++) {    
        for (j = x1 + i%2; j <= x2; j += 2) {
            display_vga_pixel(j, i, color);
        }        
    }    
}


// Блок сплошного цвета
void display_vga_block(int x1, int y1, int x2, int y2, uint8_t color) {
    
    int i, j;    
    for (i = y1; i <= y2; i++) {    
        for (j = x1; j <= x2; j++) {
            display_vga_pixel(j, i, color);
        }        
    }    
}
