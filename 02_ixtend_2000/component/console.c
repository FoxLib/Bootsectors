void console_constructor() {
}

// Полностью перерисовать консоль
void console_redraw() {

    int j;
    fb_box(0, 0, 1023, 767, COLOR_BLACK);
    fb_box(0, 20, 1023, 39, COLOR_GRAY);
    fb_box(0, 20, 1023, 39, COLOR_GRAY);
    fb_line(0, 40, 1023, 40, COLOR_DARKGRAY);
    fb_box(0, 748, 1023, 767, COLOR_GRAY);
    fb_line(0, 748, 1023, 748, COLOR_WHITE);
    
    // Заголовок
    for (j = 0; j < 1023; j++) {
        fb_line(j, 0, j, 19, rgb16(0, 128, 255 - j * 128 / 1024));
    }
    
    //brk;    
    print_fixedsys(8, 3, "TERMINAL /", COLOR_WHITE);
    print_fixedsys(8, 22, "App  About", COLOR_BLACK);
    
    print_fixedsys(8, 44, "\x02 _", COLOR_WHITE);        
}

