#define brk asm volatile ("brk");  // Отладка
#define tail asm volatile ("nop"); // В gcc есть баг с вызовами функции

// Функции для работы ядра
// ------------------------------
#include "kernel.h"              
#include "mem/mem.h"
#include "app/app.h" 

#include "sys/io.c"             // Функции для работы с (IoWrite/IoRead)
#include "sys/irq.c"            // Создание и модификация системных прерываний
#include "mem/mem.c"            // Память
#include "dev/keyb.c"

// Графика
#include "vga/vga.c"
#include "ui/ui.c"

// Встроенные приложения в ядро
// ------------------------------
#include "app/console.c"
#include "app/start.c"

/*
 * Ядро, основная оболочка, после всех инициализации в ассемблере
 * 
 * ПЛАН
 * ------------------
 * - Консоль
 * - Виртуальный диск
 * - Текстовый редактор
 * - Дизассемблер
 * - Менеджер файлов
 * - Интерпретатор BASIC
 * - Мультизадачность
 * - Поддержка мыши
 * - Поддержка клавиатуры
 * - 32 битная ОС и возможность 4гб адресации
 * - Поддержка файловой системы FAT
 * 
 * КОМПИЛЯЦИЯ
 * ------------------
 * gcc -S -O3 -m32 -masm=intel -nostdlib -nostdinc -fno-stack-protector -fno-asynchronous-unwind-tables -c kernel.c
 *
 * -fno-asynchronous-unwind-tables (не генерировать .cfi)
 * -fno-stack-protector (не защищать стек)
 * -masm=intel (intel-синтаксис)
 * -m32 (32-битное)
 * -S (генерировать .S-файл, ассемблерный)
 *
 * КАК НАХОДИТЬ ФУНКЦИИ
 * Все функции выражены так, например "sys_irq_redirect" находится в sys/irq.c
 */


void entry_main()
{
    /*
     * Регистрация прерываний
     */

    // Запрещение всех прырываний, кроме некоторых
    sys_irq_redirect(0xffff ^ IRQ_KEYB ^ IRQ_CASCADE); 
    sys_irq_make();
    sys_irq_create(0x20 + 1, (u32*)_keyb_isr);        // os.asm [_keyb_isr -> dev_keyb_isr()]
    sys_irq_create(0x20 + 2, (u32*)_irq_cascade);

    // Создание PAGING-модели
    mem_init(); 

    // Инициализация VGA
    vga_set_hicolor();  

    // Запуск консольного приложения
    app_console();

    // Фактически, остановка процессора
    while (1); 
}
