#include "vga.h"

// Расчет дистанции (r1 - r2)^2 + (g1 - g2)^2 + (b1 - b2)^2
uint32_t color_distance(uint8_t r1, uint8_t g1, uint8_t b1, uint8_t r2, uint8_t g2, uint8_t b2) {

    return (r1 - r2) * (r1 - r2) +
           (g1 - g2) * (g1 - g2) +
           (b1 - b2) * (b1 - b2);
}

// Чтение регистров с текущего видеорежима
void vga_read_regs(unsigned char *regs) {

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
void vga_write_regs(unsigned char *regs) {

    unsigned i;

    /* MISCELLANEOUS регистр */
	IoWrite8(VGA_MISC_WRITE, *regs);
	regs++;

    /* SEQUENCER регистры */
	for (i = 0; i < VGA_NUM_SEQ_REGS; i++) {
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
void vga_pixel(unsigned x, unsigned y, unsigned char c) {

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

// Инициализация после INT 10h
void init_vga() {

    int i;
    
    // Выделить память для VGA
    canvas = kalloc(640*480);

    // Режим 2 (регистр выбор режима 5)
    // -- режим записи 1 слой цвета - 1 бит
    for (i = 0; i < 16; i++) {
        
        IoWrite8(VGA_DAC_WRITE_INDEX, i);
        IoWrite8(VGA_DAC_DATA, vga_palette_16[i*3 + 0] >> 2);
        IoWrite8(VGA_DAC_DATA, vga_palette_16[i*3 + 1] >> 2);
        IoWrite8(VGA_DAC_DATA, vga_palette_16[i*3 + 2] >> 2);
    }

    IoWrite16(VGA_GC_INDEX, 0x0205);
}

// Установка определенного видеорежима
void vga_mode(int mode) {

    int i;
    switch (mode) {

        case VGA_640x480:

            // -- todo палитру
            vga_write_regs( (unsigned char*)disp_vga_640x480x16 );

            break;

        case VGA_320x200:

            // -- todo палитру
            vga_write_regs( (unsigned char*)disp_vga_320x200x256 );
            break;
    }

    disp_vga_lastmode = mode;
}

// Быстрая очистка экрана
void vga_cls(int color) {

    int i;
    char* vaddr = (char*)0xA0000;

    IoWrite16(VGA_GC_INDEX, 0xFF08);
    for (i = 0; i < 80*480; i++) {
        volatile uint8_t t = vaddr[ i ];
        vaddr[ i ] = color;
    }
}

// 50% полупрозрачный блок сплошного цвета
void vga_dotted_block(int x1, int y1, int x2, int y2, uint8_t color) {

    int i, j;
    for (i = y1; i <= y2; i++) {
        for (j = x1 + i%2; j <= x2; j += 2) {
            vga_pixel(j, i, color);
        }
    }
}

// Блок сплошного цвета @todo оптимизировать его
void vga_block(int x1, int y1, int x2, int y2, uint8_t color) {

    int i, j, x;

    int x1i = x1 >> 3;
    int x2i = x2 >> 3;

    unsigned int xl = (  0xFF00 >> (x1 & 7)) & 0xFF00;
    unsigned int xr = (0x7F8000 >> (x2 & 7)) & 0xFF00;

    // Общая быстрая маска
    IoWrite16(VGA_GC_INDEX, 0xFF08);

    if (x1i + 1 < x2i) {

        for (i = y1; i <= y2; i++) {

            char* vm = (char*)(0xA0000 + 80*i);
            for (j = x1i + 1; j < x2i; j++) {
                volatile char t = vm[j]; vm[j] = color;
            }
        }
    }

    // Одновременная
    if (x1i == x2i) {

        IoWrite16(VGA_GC_INDEX, (xl & xr) | 0x08);
        for (i = y1; i <= y2; i++) { char* vm = (char*)(0xA0000 + 80*i); volatile char t = vm[x1i]; vm[x1i] = color; }
    }

    // Левая и правая часть
    else {

        // Слева
        IoWrite16(VGA_GC_INDEX, xl | 0x08);
        for (i = y1; i <= y2; i++) { char* vm = (char*)(0xA0000 + 80*i); volatile char t = vm[x1i]; vm[x1i] = color; }

        // Справа
        IoWrite16(VGA_GC_INDEX, xr | 0x08);
        for (i = y1; i <= y2; i++) { char* vm = (char*)(0xA0000 + 80*i); volatile char t = vm[x2i]; vm[x2i] = color; }
    }

}

/*
 * Утилиты для рисования на текстовом дисплее
 */

// Рисование блока (фонового), начиная с [x,y] позиции
void text_bgblock(int x, int y, int length, char bgcolor) {

    int i;
    char* addr = DISPLAY_TEXT_ADDR + (x + y*80) * 2;

    for (i = 0; i < length; i++) {
        addr[2*i + 1] = bgcolor;
    }
}

// Рисование фрейма
void text_frame(int x1, int y1, int x2, int y2) {

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
void text_print(int x1, int y1, char* string) {

    char* addr = DISPLAY_TEXT_ADDR + 2*(x1 + y1*80);

    while (*string) {

        *addr = *string;
        addr += 2;
        string++;
    }

}

// Положение курсора
void text_set_cursor(int x, int y) {

	uint16_t pos = y * 80 + x;

	IoWrite8(0x3D4, 0x0F);
	IoWrite8(0x3D5, (uint8_t) (pos & 0xFF));
	IoWrite8(0x3D4, 0x0E);
	IoWrite8(0x3D5, (uint8_t) ((pos >> 8) & 0xFF));
}

// Режим курсора
void text_cursor_mode(uint8_t cursor_start, uint8_t cursor_end) {

	IoWrite8(0x3D4, 0x0A);
	IoWrite8(0x3D5, (IoRead8(0x3D5) & 0xC0) | cursor_start);

	IoWrite8(0x3D4, 0x0B);
	IoWrite8(0x3D5, (IoRead8(0x3E0) & 0xE0) | cursor_end);
}
