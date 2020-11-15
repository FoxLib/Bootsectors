
// Печать символа
void vg_print(int x, int y, byte chr, int color, int back) {

    uint  ad = x + 80*y;
    word* ba = (word*) (0xb8000);

    // Вычислить символ + цвета
    word  cl = chr | ((color | (back << 4)) << 8);

    ba[ ad ] = cl;        // Символ и цвет в видеопамять по адресу B8000
    vg.canvas[ ad ] = cl; // Запись в буфер / 16 bit
}

// Установка текстового курсора
void vg_cursor(int x, int y) {

    word pos = y * 80 + x;

	IoWrite8(0x3D4, 0x0F);
	IoWrite8(0x3D5, (byte) (pos & 0xFF));

	IoWrite8(0x3D4, 0x0E);
	IoWrite8(0x3D5, (byte) ((pos >> 8) & 0xFF));

    vg.cx = x;
    vg.cy = y;
}

// Скроллинг экрана вниз
void vg_scroll() {

    int i;
    word* ba = (word*) (0xb8000);

    // Сдвиг видеохолста
    for (i = 0; i < 2000 - 80; i++) {
        vg.canvas[i] = vg.canvas[i + 80];
    }
    // Очистка нижней строки
    for (i = 2000 - 80; i < 2000; i++) {
        vg.canvas[i] = (vg.fr | (vg.bg<<4));
    }
    // Перезапись всего экрана
    for (i = 0; i < 2000; i++) {
        ba[i] = vg.canvas[i];
    }

    vg.cursor(0, 24);
}

// Видеорежим не поддерживается (пока что)
void vg_not_supported() {

    // ошибка поддержки графики
}

// Поддержка текстового режима пока
void init_vg() {

    vg.mode = VG_MODE_TEXT;
    vg.w = 640;
    vg.h = 480;

    vg.cx = 0; vg.cy = 0; // Слева сверху
    vg.fr = 7; vg.bg = 0; // Белый цвет, черный фон

    // Назначение обработчиков
    vg.canvas   = (word*) kalloc(640*480*2); // 16bit
    vg.pset     = & vg_not_supported;
    vg.block    = & vg_not_supported;
    vg.print    = & vg_print;
    vg.cursor   = & vg_cursor;
    vg.scroll   = & vg_scroll;

    // Как выглядит курсор
    byte cursor_start = 14;
    byte cursor_end = 15;

    IoWrite8(0x3D4, 0x0A);
	IoWrite8(0x3D5, (IoRead8(0x3D5) & 0xC0) | cursor_start);

	IoWrite8(0x3D4, 0x0B);
	IoWrite8(0x3D5, (IoRead8(0x3E0) & 0xE0) | cursor_end);

    vg_cursor(0, 0);
}
