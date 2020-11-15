; Версия 0.01

    Используется PIT. Не работает в Virtual Box из-за IRQ 0. Необходим IO APIC.
    Тестировано в Bochs.


; -- СТРУКТУРА ПРОЕКТА ---

    boot/    Коды загрузочных секторов
    docs/    Документация по проекту

    apps/

        disassemble/      Встроенный в ядро дизассемблер

    driver/

        ata.c             Драйвер ATA
        fdd.c             Драйвер FDD (DMA)
        usb.c             USB
        ps2mouse.c        Драйвер мыши и клавиатуры
        vga.c             Драйвер VGA - переключение режимов, рисование

    generaltask/

        main.c            Основная программа ядра
        sysmon.c          Вспомогательные функции для main.c

    headers/ Заголовочные файлы

        asm.h             Встраиваемые asm-конструкции
        descriptors.h     Структура дескрипторов и TSS
        ints.h            Прототипы обработчиков системных прерываний
        io.h              Порты ввода-вывода
        memory.h          Указатели в физическую память для системных переменных

    ints/ Прерываний

        locator.asm       "Обертки" в fasm для вызова прерываний

    loader/ Загрузочные коды ядра

        boorstrap.c        Функции создания дескрипторов, TSS, таблицы прерывании, инициализация
        console.c          Работа с видеопамятью 0xB8000 (4kb) 
        iomem.asm          Ассемблерные обертки для работы с портами и памятью
        kernel.c           Ядро ОС (системный цикл)
        pmenter.asm        Код для РЕАЛЬНОГО режима, для создания дескрипторов и входа в ProtMode
        ps2mouse.c         Драйвер PS/2 мыши - инициализация, обработка прерывания 0xC (12)
        sysmon.c           Пользовательский интерфейс sysmon

     macro/ Макросы
     make/ Набор инструментов для компиляции ядра (только для LINUX)

         bootmake          Создать бут-сектор, либо записать в начальные области FDD код ядра
         fas               Транслятор s-кода в .asm-код
         make              Инструмент сборки ядра
         makefiles         Список файлов для сбора


; -- запуск bochs ---
bochs -f boot.bxrc -q

; -- как собрать ядро ---
Данные о сборке находятся в директории make/

; -- запись с flash в образ --
sudo dd if=/dev/sdf1 of=usbdrive.img count=2880 bs=512

; -- hex-editor --
okteta [offset=5A] xchg bx,bx

; --
Последовательность сборки asm-файлов и kernel. Пример

    cd loader
    gcc -c -masm=intel -m32 -fno-asynchronous-unwind-tables bootstrap.c -S
    cd make
    ./fas ../loader/bootstrap.s
    ./bootmake copyk
