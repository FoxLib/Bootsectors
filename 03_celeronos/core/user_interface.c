// Нарисовать стандартное Windows-окно
void ui_draw_window(u16 x1, u16 y1, u16 w, u16 h, char* title) {
    
    int x2 = x1 + w, y2 = y1 + h;
        
    fillrect(x1, y1, x2, y2, 7);        // Подложка
    rect(x1, y1, x2, y2, 0);            // Ободок
    
    x1+=2; y1+=2;
    x2-=1; y2-=1;
    
    line(x1, y1, x2, y1, 15);
    line(x2, y1, x2, y2, 8);
    line(x1, y2, x2, y2, 8);
    line(x1, y1, x1, y2, 15);
    
    x1+=3; y1+=3;
    x2-=3;
    
    fillrect(x1, y1, x2, y1 + 19, 3); // Заголовок
    font_tahoma_prints_bold(x1 + 4, y1 + 4, title, 15);
}