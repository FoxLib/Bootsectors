#include <stdint.h>

#include "../headers/memory.h"
#include "../driver/h/ata.h"
#include "../headers/messages.h"

// Предвательное объявление 
void fast_malloc(uint32_t, uint32_t);

#define BRK asm("xchg bx,bx");

uint32_t uistatus = 0,  // Запускается только 1 раз (инициализация)
         xtemp = 0;

uint32_t taskbar_status = 0;         

// Поиск и загрузка файла ядра в память
void run_kernel()
{
    // Поиск файла на диске
    // Выделение памяти
    // Загрузка файла в память
    // Создание дескрипторов (LDT/TSS и др.)
    // Добавление дескриптора в работу
}

// Обновление основного окна
void window_main_panel_update()
{
    int x;    

    for (x = 0; x < 80; x++) {
        b8_put_char(x, 24, ' ', 0x70);
    }
    b8_put_char(79, 24, 0x0F, 0x70);
}         

// Отладочное окно
void window_debug_update()
{
    hide_mouse();

    // Дебаг и окно
    b8_put_block(0, 0, 80, 1, ' ', 0x70);
    b8_put_block(0, 1, 80, 23, ' ', 0x30);
    draw_window_frame(0,1,80,23,0x3F);

    txt_prints(0, 0, "Internal Disassembler", 0x70);       
    uint32_t esi = 0x8000;

    int i, ptr = 0x8000, cl;

    for (i = 0; i < 21; i++)
    {        
        cl = ptr == esi ? 0x1F : 0x30;

        if (ptr == esi)
        {
            b8_put_block(1, 2 + i, 50, 1, ' ', 0x17);
        }

        print_hex32(1, 2 + i, esi, cl);

        esi = get_disassemble(esi, DIS_STRING_RESULT);
        txt_printfs(10, 2 + i, DIS_STRING_RESULT, cl);
    }

    show_mouse();
}

// Информация о дисках
void window_disk_info()
{
    hide_mouse();

    draw_window_all("View disk information", 0x17);

    int i;
    for (i = 0; i < 8; i++) {
        print_hex32(1,  2 + i, get_disk_info(i, 0), 0x17);                
    }

    show_mouse();
}

// Дамп памяти
void window_show_dump(uint32_t x)
{
    hide_mouse();
    draw_window_all("View memory dump", 0x17);

    int i, j;

    // Строка сверху
    for (j = 0; j < 0x10; j++) print_hex8(10 + j*3, 1, j, 0x1E);    
    txt_prints(58, 1, "0123456789ABCDEF", 0x1F);       

    for (i = 0; i < 22; i++) {
        print_hex32(1, 2 + i, x + i*0x10, 0x1F);

        for (j = 0; j < 0x10; j++) {
            print_hex8(10 + j*3, 2 + i, readb(x + i*0x10 + j), 0x17); 
            b8_put_char(58 + j, 2 + i, readb(x + i*0x10 + j), 0x17); 
        }
    }

    show_mouse();
}

// Отладочное микроприложение "Показ всех файловых систем"
void window_fat16_test()
{
    hide_mouse(); draw_window_all("View FAT16/32", 0x17);

    // сканирование поддерживаемых файловых систем
    uint32_t fsinfo = get_fs_table();

    txt_prints(1, 2, "FSTYPE DRIVE LBA", 0x1E);       

    int i, f, ftype, flba, c = read(0x125000);
    for (i = 0; i < c; i++) {

        f = read(0x125004 + i*8);

        ftype = f & 0xffff;
        flba  = read(0x125008 + i*8);

        // Детектор ФС
        if (ftype == 6)        { txt_prints(1, 3 + i, "FAT16", 0x70); }
        else if (ftype == 0xb) { txt_prints(1, 3 + i, "FAT32", 0x70); }

        print_hex16(8, 3 + i, f >> 16, 0x17);
        print_hex32(14, 3 + i, flba, 0x17);
    }

    show_mouse();
}

// Обработка кнопки "Пуск"
// -----------------
void task_start_popup(uint32_t m, uint32_t x, uint32_t y)
{
    if (m == 1)
    {
        // Кнопка "Пуск"
        if (x == 79 && y == 24 && taskbar_status == 0)
        {
            save_background();
            show_popupbox();            
            taskbar_status = 1;
        }
        else 
        {
            if (taskbar_status) 
            {                
                // Восстановить в любом случае область
                hide_mouse(); restore_background(); show_mouse(); taskbar_status = 0;

                // Запуск приложений
                if (y > 10 && x >= 60) {
                    
                    if (y == 11) window_disk_info();
                    else if (y == 12) window_show_dump(0x112000);
                    else if (y == 13) window_debug_update(); 
                    else if (y == 14) window_fat16_test(); 
                }
            }
        }
    }
}

// -----------------------------------------------------------------------------------------------------------------

/* 
 * ASCII таблица http://www.thealmightyguru.com/Pointless/Images/ASCII.gif
 *
 * Встроенная в ядро задача "Системный монитор"
 * Работает из задачи 0. Можно отключать его работу.
 */

void task_sysmon_ui()
{
    uint32_t message_id, x, y, s;

    // Позиция мыши (x,y) и статус (s)
    x = read(MPTR_X) / 6;
    y = read(MPTR_Y) / 6;

    // Инициализация окон при первом запуске
    // -------------------------------------
    if (uistatus == 0) 
    {        
        uistatus = 1;         
        
        show_mouse(); // показать мышь
        window_main_panel_update(); // панель задач

        // TESTZONE
        BRK;
    }

    update_mouse(); // sysmon.c

    // -----------------------   
    uint32_t c     = kbd_getkey();
    uint32_t mouse = mouse_get_button();
    // -----------------------

    task_start_popup(mouse, x, y);    
}

/*
 * Основная задача ядра (system loop)
 */

void system_loop()
{
    // Отладочная область
   
    // Обработка задач
    for (;;)
    { 
        task_sysmon_ui();
    }
}
