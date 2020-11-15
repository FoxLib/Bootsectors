/*
 * Создать массивы для работы с графикой
 */

void ui_init() {

    gif_chunks  = 0; // kalloc(512 * 1024);
    gif_surface = 0; // kalloc(512 * 1024);

    display_vga_mode(VGA_640x480);
    display_vga_cls(1);

}

// Печать HEX-строки
void ui_hexprint(uint32_t value, int digs, int x, int y, int color) {

    int i;

    for (i = 0; i < digs; i++) {

        uint8_t c = (value >> (4*(digs - i - 1))) & 0xf;

        c = c > 9 ? c + 7 : c;
        display_vga_pchar(8*(x + i), 16*y, '0' + c, color);
    }

}

// Тестовое
void ui_start() {

    
/*

// ---
    uint32_t u = ui_load_bmp("/walls/forest.bmp");
    ui_put_bmp(u, 0, 0, -1);
// ---

    display_vga_dotted_block(0,480-48,640,479,0);

    uint32_t v1 = ui_load_bmp("/icon/mycomp.bmp");
    uint32_t v2 = ui_load_bmp("/icon/msdos.bmp");

    display_vga_dotted_block(64-3,480-44,64+32+4,480-4,8); // +1

    ui_put_bmp(v1, 8, 480-40, 13);
    ui_put_bmp(v2, 64, 480-40, 13);

    int x1 = 56, y1 = 28, x2 = 384, y2 = 480 - 52;
    display_vga_block(x1,y1,x1,y2,15);
    display_vga_block(x2,y1,x2,y2,7);
    display_vga_block(x1,y1,x2,y1,15);
    display_vga_dotted_block(x1,y1,x2,y2,0);

    display_vga_putf8(8, 2, "PCI листинг", 15);


    // -- вывод pci --
    int id = 4;
    uint32_t slot, bus;

	for (bus = 0; bus < MAX_BUS; bus++) {
		for (slot = 0; slot < MAX_SLOTS; slot++) {

            uint32_t pcid = adapters[ bus ][ slot ];
            if (pcid != -1) {

                ui_hexprint(pcid >> 16,4, 9,id,15);
                ui_hexprint(pcid, 4, 9 + 5,id,15);
                id++;
            }

        }
    }
    // --
*/


/*
    display_vga_dotted_block(0,0,640,225,1);
    display_vga_putf8(1, 1, "Вас приветствует программа установки системы", 11);
    display_vga_putf8(1, 3, "Откиньтесь на спинку кресла и наслаждайтесь бесконечностью установки ОС.", 15);
    display_vga_putf8(1, 4, "Поверьте, вы заслужили отдых от трудов и я, компьютер, о вас позабочусь!", 15);
    display_vga_putf8(1, 5, "Пожалуйста, наслаждайтесь красивой картинкой, пока я вечно делаю установку.", 15);

    display_vga_putf8(1, 7, "GAMING-ферма", 11);
    display_vga_putf8(1, 9, "Теперь у вас появилась реальная возможность мечтать о настоящих 3D-играх,", 15);
    display_vga_putf8(1, 10, "а все потому, что тут даже Doom не работает, так что забудьте про NVidia, ATI", 15);
    display_vga_putf8(1, 11, "и просто наслаждайтесь отсутствием зависимости от игр.", 15);
*/
}
