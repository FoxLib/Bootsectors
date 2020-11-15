#include <stdint.h>
#include "../headers/memory.h"
#define BRK asm("xchg bx,bx");

unsigned char* vhex = "0123456789ABCDEF";

uint32_t wp, wx, wy, mbtn = 0;

// Нет данных о коде возврата
void gateException(uint32_t x)
{
    coclear(0x17);
    coprintf(1, 1, "Exception caused", 0x17);
}

// Нет данных о коде возврата
void gateException_Code(uint32_t x, uint32_t code)
{
    coclear(0x17);
    coprintf(1, 1, "Exception 00 caused. Code: ", 0x17);
    coprinth(11, 1, x, 0x1F, 8);
    coprinth(28, 1, code, 0x1C, 32);

    /*
    int i;

    for (i = 0; i < 16; i++)
    {
        asm("mov eax, [esp + 4*%0 + 64]" : : "r"(i) );
        asm("mov %0, eax" : "=m"(x));
        coprinth(1, 3 + i, x, 0x17, 32);
    }
    */
    

    asm("jmp $"); // отладка
}

// Получение точки нажатия кнопки мыши
uint32_t mouse_get_button()
{
    uint32_t s = read(MPTR_S);

    // Левая кнопка мыши
    if ((mbtn & 0x1) == 0 && (s & 0x1)) {
        mbtn |= 1;
        return 1;
    }

    // Правая кнопка мыши
    if ((mbtn & 0x2) == 0 && (s & 0x2)) {
        mbtn |= 2;
        return 2;
    }

    // Средняя кнопка мыши
    if ((mbtn & 0x4) == 0 && (s & 0x4)) {
        mbtn |= 4;
        return 3;
    }

    // negEdge сигнал
    if (!(s & 0x1)) mbtn &= 0xfffffffe;
    if (!(s & 0x2)) mbtn &= 0xfffffffd;
    if (!(s & 0x4)) mbtn &= 0xfffffffb;
    
    return 0;
}

// Console
uint32_t mouse_get_x() { return read(MPTR_X) / 6; }
uint32_t mouse_get_y() { return read(MPTR_Y) / 6; }

// -------------

void hide_mouse()
{    
    cwattr(wx / 6, wy / 6, wp); 
}

void show_mouse()
{
    uint32_t x, y;

    x  = read(MPTR_X);
    y  = read(MPTR_Y);    

    wp = rdattr(x / 6, y / 6);
    cwattr(x / 6, y / 6, wp ^ 0x7f);

    wx = x; wy = y;
}

// Обновить курсор мыши
void update_mouse()
{    
    // Есть изменения
    if (read(MPTR_T))
    {
        write(MPTR_T, 0);
        hide_mouse();
        show_mouse();        
    }       
}

void show_dbg_timer(uint32_t x, uint32_t y)
{
    uint32_t ts = read(TIMER32_P);
    
    cwchar(x + 0, y, (ts / 100000) % 10 + '0', 0x07);
    cwchar(x + 1, y, (ts / 10000) % 10 + '0', 0x07);
    cwchar(x + 2, y, (ts / 1000) % 10 + '0', 0x07);
    cwchar(x + 3, y, (ts / 100) % 10 + '0', 0x07);   
}

void print_hex8(uint32_t x, uint32_t y, uint32_t h, uint32_t attr)
{
    int i;
    
    for (i = 0; i < 2; i++) {
        b8_put_char(x + i, y, vhex[(h >> 4) & 0x0f], attr);
        h <<= 4;
    }    
}

void print_hex16(uint32_t x, uint32_t y, uint32_t h, uint32_t attr)
{
    int i;
    
    for (i = 0; i < 4; i++) {
        b8_put_char(x + i, y, vhex[(h >> 12) & 0x0f], attr);
        h <<= 4;
    }    
}

void print_hex32(uint32_t x, uint32_t y, uint32_t h, uint32_t attr)
{
    int i;
    
    for (i = 0; i < 8; i++) {
        b8_put_char(x + i, y, vhex[h >> 28], attr);
        h <<= 4;
    }    
}

void print_decimal(uint32_t x, uint32_t y, uint32_t decimal_number, uint32_t attr)
{
    char u[11];
    int i = 0, k = 0, j = 0;
    uint32_t t;

    t = decimal_number;

    while (1)
    {
        u[k] = t % 10;
        if (u[k] == 0 && k > 0) break;

        k++; t /= 10;
    } 

    for (i = k-1; i >= 0; i--) {
        b8_put_char(x + j, y, u[i] + '0', attr);
        j++;
    }
}

// Список файловых систем
uint32_t get_fs_table()
{
    asm("mov eax, 1"); // get fs list
    asm("mov edi, 0x125000"); // tmp-buffer
    asm("int 0xc0"); // syscall
    asm("mov eax, 0x125000"); // return
}

// Вызов INT 0xC0 (Ядро)
uint32_t call_int_c0() { asm("int 0xc0");  }

// Рисование фрейма
void draw_window_frame(uint32_t x, uint32_t y, uint32_t w, uint32_t h, uint32_t attr)
{
    h--;

    b8_put_block(x, y, w, 1, 205, attr);
    b8_put_block(x, y + h, w, 1, 205, attr);
    b8_put_block(x, y, 1, h, 186, attr);
    b8_put_block(x + w - 1, y, 1, h, 186, attr);

    b8_put_char(x, y, 201, attr);
    b8_put_char(x + w - 1, y, 187, attr);
    b8_put_char(x, y + h, 200, attr);
    b8_put_char(x + w - 1, y + h, 188, attr);
}

// Нарисовать стандартное окно 
void draw_window_all(char* title, uint32_t attr)
{
    b8_put_block(0, 0, 80, 1, ' ', 0x70);
    txt_prints(0, 0, title, 0x70);   
    b8_put_block(0, 1, 80, 23, ' ', attr);
}

// -------------------------------------

void save_background()
{

}

void restore_background()
{
    b8_put_block(0, 0, 80, 24, ' ', 0x07);
}

void show_popupbox()
{
    b8_put_block(60, 10, 20, 14, ' ', 0x70);
    draw_window_frame(60,10,20,14,0x70);

    txt_prints(62, 11, "Disk info", 0x71); 
    txt_prints(62, 12, "Dump 0x112000", 0x71); 
    txt_prints(62, 13, "Debug 0x8000", 0x71); 
    txt_prints(62, 14, "FAT16 test", 0x71); 
}