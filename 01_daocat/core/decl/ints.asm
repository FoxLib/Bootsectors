; Векторы системных исключений [0..1F]
; 
; | N  | Имя | Описание                                         | Тип   | Error Code | Источник исключения
; +====+========================================================+=======+============+=======================================
; | 00 | #DE | Ошибка деления                                   | Fault |     -      | Команды DIV и IDIV
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 01 | #DB | Отладка                                          | FTrap |     -      | Любая команда или команда INT 1
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 02 |  -  | Прерывание NMI                                   | Int.  |     -      | Немаскируемое внешнее прерывание
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 03 | #BP | Breakpoint                                       | Trap  |     -      | Команда INT 3
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 04 | #OF | Переполнение                                     | Trap  |     -      | Команда INTO
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 05 | #BR | Превышение предела                               | Fault |     -      | Команда BOUND
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 06 | #UD | Недопустимая команда (Invalid Opcode)            | Fault |     -      | Недопустимая команда или команда UD2
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 07 | #NM | Устройство не доступно (No Math Coprocessor)     | Fault |     -      | Команды плавающей точки или команда WAIT/FWAIT
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 08 | #DF | Двойная ошибка                                   | Abort |  Да (нуль) | Любая команда
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 09 |  -  | Превышение сегмента сопроцессора, резервировано  | Fault |     -      | Команды плавающей точки
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 0A | #TS | Недопустимый TSS                                 | Fault |     Да     | Переключение задач или доступ к TSS
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 0B | #NP | Сегмент не присутствует                          | Fault |   Fault    | Загрузка сегментных регистров или доступ к сегментам
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 0C | #SS | Ошибка сегмента стека                            | Fault |     Да     | Операции над стеком и загрузка в SS
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 0D | #GP | Общая защита                                     | Fault |     Да     | Любой доступ к памяти и прочие проверки защиты
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 0E | #PF | Страничное нарушение                             | Fault |     Да     | Доступ к памяти
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 0F |  -  | Зарезервировано Intel-ом. Не использовать        |       |     -      | 
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 10 | #MF | Ошибка плавающей точки в x87 FPU                 | Fault |     -      | Команда x87 FPU или команда WAIT/FWAIT
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 11 | #AC | Проверка выравнивания                            | Fault |     Да     | (Нуль) Обращение к пямяти
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 12 | #MC | Проверка оборудования                            | Abort |     -      | Наличие кодов и их содержимое зависит от модели
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 13 | #XF | Исключение плавающей точки в SIMD                | Fault |     -      | Команды SSE и SSE2
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 14..1F   | Зарезервировано INTEL                            |       |            | 
; +====+========================================================+=======+============+=======================================
; | 20..2F   | DAOCAT: IRQ16                                    | Int.  |            | Устройство (тип шлюза - Interrupt/Ловушка)
; +----+--------------------------------------------------------+-------+------------+---------------------------------------
; | 30..FF   | Прерывания определяются пользователем            | Int.  |            | Внешнее прерывание или команда INT n
; +----+--------------------------------------------------------+-------+------------+---------------------------------------

; IRQ [20..2F] Перенастроено PIC

; MASTER IRQ (20h)
;
; | Бит | IRQ | Устройство
; +-----+-----+--------------------------------------------------
; |  0  |  0  | Таймер
; +-----+-----+--------------------------------------------------
; |  1  |  1  | Клавиатура
; +-----+-----+--------------------------------------------------
; |  2  |  2  | Каскад (подключен ко второму контроллеру)
; +-----+-----+--------------------------------------------------
; |  3  |  3  | COM 2/4
; +-----+-----+--------------------------------------------------
; |  4  |  4  | COM 1/3
; +-----+-----+--------------------------------------------------
; |  5  |  5  | LPT2 or SOUNDCART
; +-----+-----+--------------------------------------------------
; |  6  |  6  | Контроллер дисковода 
; +-----+-----+--------------------------------------------------
; |  7  |  7  | LPT1
; +-----+-----+--------------------------------------------------
;
; SLAVE
; | Бит | IRQ | Устройство
; +-----+-----+--------------------------------------------------
; |  0  |  8  | Часы реального времени RTC (Real Time Clock)
; +-----+-----+--------------------------------------------------
; |  1  |  9  | Редирект с IRQ2
; +-----+-----+--------------------------------------------------
; |  2  |  A  | Резерв
; +-----+-----+--------------------------------------------------
; |  3  |  B  | Резерв
; +-----+-----+--------------------------------------------------
; |  4  |  C  | РS/2 Mouse
; +-----+-----+--------------------------------------------------
; |  5  |  D  | Исключение сопроцессора
; +-----+-----+--------------------------------------------------
; |  6  |  E  | Primary ATA
; +-----+-----+--------------------------------------------------
; |  7  |  F  | Secondary ATA
; +-----+-----+--------------------------------------------------

; Аппаратные настройки
; --------------------

APIC_presence    db  1

; Строки ошибок
ierr_DE db   '#00 Divide Error', 0
ierr_DB db   '#01 Trap', 0
ierr_NMI db  '#02 NMI', 0
ierr_BP db   '#03 Breakpoint INT 3', 0
ierr_OF db   '#04 Overflow INTO', 0
ierr_BR db   '#05 Bound Overflow', 0
ierr_UD db   '#06 Invalid Opcode', 0
ierr_NM db   '#07 No Math Coprocessor', 0
ierr_DF db   '#08 Double Fault', 0
ierr_LIMC db '#09 Coprocessor Overflow (reseverved)', 0
ierr_TSS db  '#0A Invalid TSS', 0
ierr_NP db   '#0B Segment Not Present', 0
ierr_SS db   '#0C Stack Segment Fault', 0
ierr_GP db   '#0D General Protection', 0
ierr_PF db   '#0E Page Fault', 0
ierr_RESV1 db '#0F (reseverved)', 0
ierr_MF db   '#10 Math Fault', 0
ierr_AC db   '#11 Align Control', 0
ierr_MC db   '#12 Machine Device Control', 0
ierr_XF db   '#13 SIMD FPU Exception', 0

; Список прерываний
; --------------------

interrupt_list:

    ; Cистемные прерывания (должны быть TSS)
    GATE_INTERRUPT int_00, SEGMENT_CORE_CODE ; Int 00 
    GATE_TRAP      int_01, SEGMENT_CORE_CODE ; Int 01
    GATE_INTERRUPT int_02, SEGMENT_CORE_CODE ; Int 02
    GATE_TRAP      int_03, SEGMENT_CORE_CODE ; Int 03
    GATE_TRAP      int_04, SEGMENT_CORE_CODE ; Int 04
    GATE_INTERRUPT int_05, SEGMENT_CORE_CODE ; Int 05
    GATE_INTERRUPT int_06, SEGMENT_CORE_CODE ; Int 06
    GATE_INTERRUPT int_07, SEGMENT_CORE_CODE ; Int 07
    GATE_INTERRUPT int_08, SEGMENT_CORE_CODE ; Int 08
    GATE_INTERRUPT int_09, SEGMENT_CORE_CODE ; Int 09
    GATE_INTERRUPT int_0A, SEGMENT_CORE_CODE ; Int 0A
    GATE_INTERRUPT int_0B, SEGMENT_CORE_CODE ; Int 0B
    GATE_INTERRUPT int_0C, SEGMENT_CORE_CODE ; Int 0C
    GATE_INTERRUPT int_0D, SEGMENT_CORE_CODE ; Int 0D
    GATE_INTERRUPT int_0E, SEGMENT_CORE_CODE ; Int 0E
    GATE_INTERRUPT int_0F, SEGMENT_CORE_CODE ; Int 0F
    GATE_INTERRUPT int_10, SEGMENT_CORE_CODE ; Int 10
    GATE_INTERRUPT int_11, SEGMENT_CORE_CODE ; Int 11
    GATE_INTERRUPT int_12, SEGMENT_CORE_CODE ; Int 12
    GATE_INTERRUPT int_13, SEGMENT_CORE_CODE ; Int 13

    ; Зарезервировано Intel
    GATE_INTERRUPT stub_interrupt, SEGMENT_CORE_CODE ; Int 14
    GATE_INTERRUPT stub_interrupt, SEGMENT_CORE_CODE ; Int 15
    GATE_INTERRUPT stub_interrupt, SEGMENT_CORE_CODE ; Int 16
    GATE_INTERRUPT stub_interrupt, SEGMENT_CORE_CODE ; Int 17
    GATE_INTERRUPT stub_interrupt, SEGMENT_CORE_CODE ; Int 18
    GATE_INTERRUPT stub_interrupt, SEGMENT_CORE_CODE ; Int 19
    GATE_INTERRUPT stub_interrupt, SEGMENT_CORE_CODE ; Int 1A
    GATE_INTERRUPT stub_interrupt, SEGMENT_CORE_CODE ; Int 1B
    GATE_INTERRUPT stub_interrupt, SEGMENT_CORE_CODE ; Int 1C
    GATE_INTERRUPT stub_interrupt, SEGMENT_CORE_CODE ; Int 1D
    GATE_INTERRUPT stub_interrupt, SEGMENT_CORE_CODE ; Int 1E
    GATE_INTERRUPT stub_interrupt, SEGMENT_CORE_CODE ; Int 1F

    ; IRQ Master [TSS]
    GATE_TASK      SEGMENT_TIMER ; Int 20. 0
    GATE_INTERRUPT IRQ_01,          SEGMENT_CORE_CODE ; Int 21. 1
    GATE_INTERRUPT stub_irq_master, SEGMENT_CORE_CODE ; Int 22. 2
    GATE_INTERRUPT IRQ_03,          SEGMENT_CORE_CODE ; Int 23. 3
    GATE_INTERRUPT IRQ_04,          SEGMENT_CORE_CODE ; Int 24. 4
    GATE_INTERRUPT stub_irq_master, SEGMENT_CORE_CODE ; Int 25. 5
    GATE_INTERRUPT stub_irq_master, SEGMENT_CORE_CODE ; Int 26. 6
    GATE_INTERRUPT stub_irq_master, SEGMENT_CORE_CODE ; Int 27. 7

    ; IRQ Slave [TSS]
    GATE_INTERRUPT stub_irq_slave, SEGMENT_CORE_CODE ; Int 28. 8
    GATE_INTERRUPT stub_irq_slave, SEGMENT_CORE_CODE ; Int 29. 9
    GATE_INTERRUPT stub_irq_slave, SEGMENT_CORE_CODE ; Int 2A. A
    GATE_INTERRUPT stub_irq_slave, SEGMENT_CORE_CODE ; Int 2B. B
    GATE_INTERRUPT IRQ_0C,         SEGMENT_CORE_CODE ; Int 2C. C
    GATE_INTERRUPT stub_irq_slave, SEGMENT_CORE_CODE ; Int 2D. D
    GATE_INTERRUPT stub_irq_slave, SEGMENT_CORE_CODE ; Int 2E. E
    GATE_INTERRUPT stub_irq_slave, SEGMENT_CORE_CODE ; Int 2F. F   

    ; SysCall
    GATE_INTERRUPT stub_syscall, SEGMENT_CORE_CODE ; Int 30
    GATE_INTERRUPT stub_syscall, SEGMENT_CORE_CODE ; Int 31
    GATE_INTERRUPT stub_syscall, SEGMENT_CORE_CODE ; Int 32
    GATE_INTERRUPT stub_syscall, SEGMENT_CORE_CODE ; Int 33
    GATE_INTERRUPT stub_syscall, SEGMENT_CORE_CODE ; Int 34
    GATE_INTERRUPT stub_syscall, SEGMENT_CORE_CODE ; Int 35
    GATE_INTERRUPT stub_syscall, SEGMENT_CORE_CODE ; Int 36
    GATE_INTERRUPT stub_syscall, SEGMENT_CORE_CODE ; Int 37
    GATE_INTERRUPT stub_syscall, SEGMENT_CORE_CODE ; Int 38
    GATE_INTERRUPT stub_syscall, SEGMENT_CORE_CODE ; Int 39
    GATE_INTERRUPT stub_syscall, SEGMENT_CORE_CODE ; Int 3A
    GATE_INTERRUPT stub_syscall, SEGMENT_CORE_CODE ; Int 3B
    GATE_INTERRUPT stub_syscall, SEGMENT_CORE_CODE ; Int 3C
    GATE_INTERRUPT stub_syscall, SEGMENT_CORE_CODE ; Int 3D
    GATE_INTERRUPT stub_syscall, SEGMENT_CORE_CODE ; Int 3E
    GATE_INTERRUPT stub_syscall, SEGMENT_CORE_CODE ; Int 3F

; Заглушки на прерывания
usr_interrupt:

    GATE_INTERRUPT user_interrupt, SEGMENT_CORE_CODE ; Int 40
