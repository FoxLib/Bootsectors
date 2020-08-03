#include "vga.h"
#include "gui.h"
#include "stdio.h"

void gui_init() {
}

void gui_draw_wctrl_icon(int x, int y, int icon_id) {

    int sx = (icon_id * 21) % 84;
    int sy = (icon_id * 21) / 84; sy *= 21;

    for (int i = 0; i < 21; i++)
    for (int j = 0; j < 21; j++) {

        if (i + j <= 1) continue;

        // Верхяя правая прозрачность
        if (i == 0 && (j == 20 || j == 19)) continue;
        if (i == 1 && (j == 20)) continue;

        // Нижний левый и правый
        if (i == 19 && (j == 20 || j == 0)) continue;
        if (i == 20 && (j == 20 || j == 19 || j == 0 || j == 1)) continue;

        pset(x + j, y + i, img_win_controls[sy + i][sx + j]);
    }
}

// Отрисовать окно
void gui_draw_window(char* name, int x, int y, int w, int h) {

    int x2 = x + w, y2 = y + h;

    // Верхняя граница окна
    for (int i = 0; i < 30; i++) {

        int m = 0;

        // Скругленная форма
        if (i == 0) m = 5;
        else if (i == 1) m = 3;
        else if (i == 2) m = 2;
        else if (i == 3 || i == 4) m = 1;

        block(x+m, y+i, x2-m, y+i, C(GUITopGradient[i]));

        // Ободок
        uint16_t clb = C(GUITopGradient[0]);
        pset(x +m, y+i, clb);
        pset(x2-m, y+i, clb);

        // Исправленная точчка
        if (m == 1) {
            pset(x +4, y+1, clb);
            pset(x2-4, y+1, clb);
        }
    }

    bold(1);
    font(FONT_TREBUCHETMS_14);
    locate(x + 7, y + 10); colorfr(CL_BLACK); print(name);
    locate(x + 6, y +  9); colorfr(CL_WHITE); print(name);

    // Управление (типичные кнопки)
    gui_draw_wctrl_icon(x2 - 24, y + 6, ICON_CLOSE);
    gui_draw_wctrl_icon(x2 - 47, y + 6, ICON_OPEN);
    gui_draw_wctrl_icon(x2 - 70, y + 6, ICON_HIDE);

    // Тело окна
    block(x,  y + 30, x2, y2, C(0xd5d5d5));
    line (x,  y + 30, x,  y2, 0);
    line (x,  y2,     x2, y2, 0);
    line (x2, y + 30, x2, y2, 0);

}
