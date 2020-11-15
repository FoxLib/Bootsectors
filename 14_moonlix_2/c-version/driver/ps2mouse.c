// Документация на мышь: http://wiki.osdev.org/Mouse_Input

#include <stdint.h>
#include "../headers/memory.h"
#include "../headers/windows.h"

#define READ_BUSY(m) for (i = 0; i < 65536; i++) { if ((inb(0x64) & m) == 0) { break; } } if (i == 65536) return 0x0100;

/*
 * 1. Чтение ACK из 0x64
 * 2. Чтение символа из 0x60 
 */

uint16_t mkb_read()
{
    int c = 65536, i;

    // kb_wait
    do { if (inb(0x64) & 0x1) break; } while (--c); if (c == 0) return 0x0100;

    // Задержка 32 такта
    for (i = 0; i < 8; i++) asm("nop");

    // Чтение из есть
    return inb(0x60);
}

/*
 * 1. Ожидание готовности записи (бит 5, 0x20) из 0x64
 * 2. Чтение байта из 0x60
 * 3. Ожидание готовности чтения (бит 2, 0x02) из 0x64
 * 4. Запись в 0x60
 * 5. Ожидание готовности (бит 2, 0x02) из 0x64, 0x0ffff чтений
 * 6. Ожидание готовности (бит 1, 0x02) из 0x64, 0x8FFFF чтений
 */
uint16_t mkb_write(uint8_t al)
{
    int i;
    
    READ_BUSY(0x20);  // Ожидание освобождения флага READY (0x20) в 0x64

    inb(0x60);        // Чтение байта из 0x60
    READ_BUSY(0x02);  

    outb(0x60, al);   // Запись байта
    READ_BUSY(0x02);

    // Финальное ожидание
    for (i = 0; i < 65536 * 8; i++) {
        if (inb(0x64) & 0x1) return 0;
    }

    return 1;
}

/*
 * 1. Прием команды готовности с 0x64-го порта
 * 2. Отсылка команды на 0x64-й порт
 * 3. Ожидание готовности после записи
 */

uint16_t mkb_cmd(uint8_t bl)
{
    int i;

    READ_BUSY(0x02);   

    outb(0x64, bl);
    READ_BUSY(0x02);

    return 0;
}

// Инициализация ps/2 мыши
// -----------------------------------------------
void ps2_mouse_init()
{
    int i;
    uint8_t tmp;

    mkb_cmd(0xa8);                 // Enable Auxiliary Device command (0xA8) | This will generate an ACK response from the keyboard
    mkb_read();                    // (which you must wait to receive) read status | Но на bochs никакого ответа нет (поскольку мышь не captured)
    mkb_cmd(0x20);                 // get command byte (You need to send the command byte 0x20)

    // enable interrupt ps/2 mouse
    tmp = (mkb_read() & 0xff) | 3; 
    mkb_cmd(0x60);
    mkb_write(tmp);

    // for mouse    
    mkb_cmd(0xD4);
    mkb_write(0xF4);               // Enable Data Reporting (Здесь ошибка)
    mkb_read();                    // read status return

    // Записать константы разрешения экрана 80x25
    write(SCR_WIDTH,  80*6 - 1); 
    write(SCR_HEIGHT, CONSOLE_HEIGHT*6 - 1);

    // Указатель в середине
    write(MPTR_X, 40*6);
    write(MPTR_Y, (CONSOLE_HEIGHT / 2)*6);

    // Сбросить курсоры и буфер клавиатуры 
    write(KBD_FIFO, 0);
    write(KBD_CURSOR, 0);

    for (i = 0; i < 2048; i++) writeb(KBD_BUFFER + i, 0);    
}

// 
void com_mouse_init()
{
    /*

; --- com1 mouse enable --- 
    mov   bx, 0x3f8 ; combase

    mov   dx, bx
    add   dx, 3
    mov   al, 0x80
    out   dx, al ; out (combase + 3), 0x80

    mov   dx, bx
    add   dx, 1
    mov   al, 0
    out   dx, al ; out (combase + 1), 0x00

    mov   dx, bx
    add   dx, 0
    mov   al, 0x30 * 2   
    out   dx, al ; out (combase + 0), 0x60

    mov   dx, bx
    add   dx, 3
    mov   al, 2        
    out   dx, al ; out (combase + 3), 0x02

    mov   dx, bx
    add   dx, 4
    mov   al, 0x0B
    out   dx, al ; out (combase + 4), 0x0B

    mov   dx, bx
    add   dx, 1
    mov   al, 1
    out   dx, al ; out (combase + 1), 0x01

    ; --- com2 mouse enable --- 
    mov   bx, 0x2f8 ; combase

    mov   dx, bx
    add   dx, 3
    mov   al, 0x80
    out   dx, al

    mov   dx, bx
    add   dx, 1
    mov   al, 0
    out   dx, al

    mov   dx, bx
    add   dx, 0
    mov   al, 0x30 * 2
    out   dx, al

    mov   dx, bx
    add   dx, 3
    mov   al, 2
    out   dx, al

    mov   dx, bx
    add   dx, 4
    mov   al, 0x0B
    out   dx, al

    mov   dx, bx
    add   dx, 1
    mov   al, 1
    out   dx, al

    ret    */
}

// Обработчик клавиатуры
// --------------------------------------------------------------------------------------------------------------------
void keyboard_handler()
{
    uint8_t code = inb(0x60); // Скан-код
    uint8_t scan = code & 0x7f;

//    На реальной машине это все равно не работает (т.к. 0x61 там динамик)
//    uint8_t cmd  = inb(0x61); // Команда
//    outb(0x61, cmd | 0x80);  // Код обработан
//    outb(0x61, code & 0x7F); // Какой именно скан-код обработан

    // Записать новый символ в буфер
    uint32_t kptr = (read(KBD_CURSOR) + 1) & 0x7ff;
    uint32_t fptr =  read(KBD_FIFO);

    // Ошибка буфера: превышение лимита
    if (fptr == kptr - 2) {
        kptr--;
    }
    else {
        writeb(KBD_BUFFER + kptr, code);
    }
    
    write(KBD_CURSOR, kptr); // Сместить курсор
    writeb(KBD_STATUS + scan, code & 0x80 ? 0x00 : 0xff); // Статусы клавиш

    // Отправить EOI Master
    outb(0x20, 0x20);        
}

// Обработчик мыши
// --------------------------------------------------------------------------------------------------------------------
// http://wiki.osdev.org/Mouse_Input#PS2_Mouse_Subtypes
void mouse_handler()
{
    uint8_t s, i;

    int32_t x, y, w, h; // signed    

    // 0 [status], 1 [xdiff], 2 [ydiff]
    uint8_t packet[3]; 

    // читать 3 раза
    for (i = 0; i < 3; i++)
    {
        // Читать порт до тех пор, пока не получатся данные
        do { s = mkb_read(); } while (s & 0xff00);

        // Записать временные данные
        packet[i] = s & 0xff;
    }

    // Обработка
    x = read(MPTR_X); 
    y = read(MPTR_Y);
    w = read(SCR_WIDTH);
    h = read(SCR_HEIGHT);

    // Переместить мышь
    x += (packet[0] & 0x10) ? 0xffffff00 | packet[1] : packet[1];
    y -= (packet[0] & 0x20) ? 0xffffff00 | packet[2] : packet[2];

    // Для не нарушения границ
    if (x < 0) x = 0;
    if (x > w) x = w;

    if (y < 0) y = 0;
    if (y > h) y = h;

    write(MPTR_X, x);         // X
    write(MPTR_Y, y);         // Y
    write(MPTR_S, packet[0]); // Status
    write(MPTR_T, 1);         // Toched

    // EOI Slave
    outb(0x20, 0x20);
    outb(0xA0, 0x20);    
}
