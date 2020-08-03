#include "vga.h"
#include "gui.h"
#include "stdio.h"

void gui_init() {
}

// Отрисовать окно
void gui_draw_window(char* name, int x, int y, int w, int h) {

    int x2 = x + w, y2 = y + h;
    lineb(x, y, x2, y2, 0);

    // --
    for (int i = 0; i < 26; i++) {
        block(x, y+i, x2, y+i, C(GUITopGradient[i]));
    }

    block(x, y+26, x2, y2, C(0xd5d5d5));

    bold(1);
    font(FONT_TREBUCHETMS_14);
    locate(x + 7, y + 8); colorfr(CL_BLACK); print(name);
    locate(x + 6, y + 7); colorfr(CL_WHITE); print(name);
}
