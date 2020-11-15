#include <stdint.h>

// Передаваемые параметры (появляются только здесь)
uint32_t 
    param_eax, 
    param_ebx,
    param_ecx,
    param_edx,
    param_esp,
    param_ebp,
    param_esi,
    param_edi,
    param_ds,
    param_es,
    param_fs,
    param_gs;


#include "../headers/memory.h"
#include "../headers/windows.h"
#include "../headers/events.h"

void b8_put_char(uint32_t, uint8_t, uint8_t, uint8_t);

// ---------------------------------------------------------------------------------------------------------

#define BRK asm("xchg bx,bx");

// 27   - ESC (0x1B)
// 0x80 - Shift+ESC
// 0xE0 - спец.код.

// Scancodes -> ASCII
//                 00 01   02   03   04   05   06   07   08   09   0a   0b   0c   0d   0e 0f 10   11   12   13   14   15   16   17   18   19   1a   1b   1c  1d 1e   1f   20   21   22   23   24   25    26  27   28    29   2a 2b    2c   2d   2e   2f   30   31   32   33   34   35   36 37   38 39   3a 3b 3c 3d 3e 3f 40 41 42 43 44 45 46 47 48 49 4a   4b 4c 4d 4e   4f 50 51 52 53 54 55 56 57 58 59 5a 5b 5c 5d 5e 5f 60 61 62 63 64 65 66 67 68 69 6a 6b 6c
char codes[]    = {0,  27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8, 9, 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 10, 0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`', 0, '\\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, '*', 0, ' ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '-', 0, 0, 0, '+', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
char codes_sh[] = {0, 255, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', 8, 9, 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', 10, 0, 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"',  '~', 0,  '|', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0, '*', 0, ' ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '-', 0, 0, 0, '+', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

// "Длинный" клавиатурный код
uint32_t keyb_proc = 0;

// KERNEL модули
// ---------------------------------------------------------------------------------------------------------

// Получение символа с буфера клавиатуры (через FIFO)
uint32_t kbd_fifo_char()
{
    uint32_t c, fifo, curs;

    do 
    {
        c = 0;

        fifo = read(KBD_FIFO);
        curs = read(KBD_CURSOR);

        // Читать следующий символ
        if (fifo != curs) 
        {            
            fifo = (fifo + 1) & 0x7ff;
            c = read(fifo + KBD_BUFFER);
            write(KBD_FIFO, fifo);
            
            if (c == 0xE0) {
                break; // Специальный код 
            }
        }
    } 
    while (c & 0x80);
    
    return c;
}

// http://wiki.osdev.org/PS2_Keyboard (Scan Code Sets) 
uint32_t kbd_getkey()
{
    // Читать скан-кодpeek_message
    uint32_t c = kbd_fifo_char(), code = 0;

    // Скан-код присутствует
    if (c) {

        // Специальная команда (не ASCII)
        if (c == 0xE0) {
            keyb_proc = 1;
            return 0;            
        }
        // Специальная команда получена [256..383]
        else if (keyb_proc) {                
            keyb_proc = 0;
            return (256 + c);
        }
        // Код получен
        else if (codes[c]) 
        {
            // В данный момент зажат SHIFT (left/right)
            if (readb(KBD_STATUS + 0x2a) || readb(KBD_STATUS + 0x36)) {
                return codes_sh[c]; 
            }
            else {
                return codes[c]; 
            }            
        }        
    }

    return code;
}


// TXT Console User Interface
// ---------------------------------------------------------------------------------------------------------

// Напечатать из основного сегмента
void txt_prints(uint8_t x, uint8_t y, char* str, uint8_t attr)
{
    int i = 0;

    while (str[i]) 
    {
        b8_put_char(x + i, y, str[i], attr);
        i++;
    }
}


// Нарисовать символы в окне
void txt_printfs(uint8_t x, uint8_t y, uint32_t str, uint8_t attr)
{
    int i = 0, b;

    while (1)
    {
        if (b = readb(str + i)) {
            b8_put_char(x + i, y, b, attr);
        }
        else {
            break;
        }
        
        i++;
    }
}

// Создание системного псевдоокна (выделение 8кб памяти)
uint32_t create_window_task(int task_id, int params)
{
    int t, p;

    p = HM_TASK_REGISTER + task_id*64;
    t = read(p);

    // Ячейка не занята?
    if (!(t & 1)) 
    {         
        // Выделение памяти 8кб            
        fast_malloc(p + 4, 2);
        
        // Записать статус окна
        write(p, 1 | params);
        return task_id;
    }

    return 0;
}

// Алиасы
uint32_t get_eax() { return param_eax; }
uint32_t get_ebx() { return param_ebx; }
uint32_t get_ecx() { return param_ecx; }
uint32_t get_edx() { return param_edx; }
uint32_t get_esi() { return param_esi; }
uint32_t get_edi() { return param_edi; }

void set_eax(uint32_t v) {  param_eax = v; }
void set_ebx(uint32_t v) {  param_ebx = v; }
void set_ecx(uint32_t v) {  param_ecx = v; }
void set_edx(uint32_t v) {  param_edx = v; }
void set_esi(uint32_t v) {  param_esi = v; }
void set_edi(uint32_t v) {  param_edi = v; }

// INT 0xC0 Вызов системных функции из ядра по INT
// ---------------------------------------------------------------------------
uint32_t syscall_INTC0_dispather()
{    
    switch (param_eax)
    {
        case 0: break; // exit process
        case 1: syscall_get_fat_enumeration(); break; // 
    }
}