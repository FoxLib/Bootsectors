// Нарисовать пиксель на экране
void vg_pixel(int x, int y, uint c) {

    char* vaddr = (char*)0xA0000;

    if (x < 640 && y < 480) {

        uint16_t symbol = (x >> 3) + y*80;
        uint16_t mask = 0x8000 >> (x & 7);

        IoWrite16(VGA_GC_INDEX, 0x08 | mask); // Установка маски, регистр 8 (вертикальная запись в слои)
        volatile uint8_t t = vaddr[ symbol ]; // Читать перед записью, иначе не сработает

        vaddr[ symbol ] = c;
    }
}

// Нарисовать блок
void vg_block(int x1, int y1, int x2, int y2, uint color) {

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

// Подготовка и выделение памяти
void init_vg() {

    int i;
    
    vg.w = 640;
    vg.h = 480;

    // Выделить необходимое количество памяти
    vg.canvas = (uint16_t*)kalloc(2*640*480);

    // Режим 2 (регистр выбор режима 5) режим записи 1 слой цвета - 1 бит
    for (i = 0; i < 16; i++) {

        IoWrite8(VGA_DAC_WRITE_INDEX, i);
        IoWrite8(VGA_DAC_DATA, vgaPalette16[i*3 + 0] >> 2);
        IoWrite8(VGA_DAC_DATA, vgaPalette16[i*3 + 1] >> 2);
        IoWrite8(VGA_DAC_DATA, vgaPalette16[i*3 + 2] >> 2);
    }

    IoWrite16(VGA_GC_INDEX, 0x0205);

    // Установить ссылку на функции
    vg.pset  = & vg_pixel;
    vg.block = & vg_block;
}
