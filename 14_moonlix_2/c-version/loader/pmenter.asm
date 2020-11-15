; --------------------------------------------------------
; Создание дескриптора в реальном режиме
; EAX - Limit
; EBX - Address
; CX  - Config
; ES:DI - GDT
; --------------------------------------------------------

create_descriptor_real_mode:

    stosw ; limit
    
    xchg  eax, ebx
    stosw ; address 0..15
    
    shr   eax, 16
    stosb ; addr 16..23

    xchg  eax, ebx
    mov   al, cl
    stosb ; config low

    shr   eax, 16
    or    al, ch
    stosb ; config + limit

    xchg  eax, ebx
    shr   ax, 8
    stosb ; addr 24..31

    ret

; --------------------------------------------------------
; Установка системных дескрипторов. Реальный режим.
; Дескрипторная таблица находится по линейному адресу 0x10000
; Инициализация сегмента кода, данных и стека (cs/ds/ss)
; ****
; Остальные дескрипторы уже из защищенного режима
; --------------------------------------------------------

set_descriptors:    

    cli
    cld

    mov ax, 0x1800
    mov es, ax

    ; Очистить GDT
    xor ax, ax
    mov cx, 0x8000
    rep stosw
   
    mov di, 8

    ; СЕГМЕНТ КОДА [CS = 0x0008]
    ; 0x80000 - 0x8FFFF (64 кб)
    ; --------------------------
    mov eax, 0x0FFFF
    mov ebx, Protected_Core
    mov cx,  0x90 + 0x8 + 0x4000 ; PRESENT (0x80) + DPL_0 (0) + BIT_SYSTEM (0x10) + CODE_EXEC_ONLY  (0x8) + BIT_DEFAULT_SIZE_32 (0x4000)
    call create_descriptor_real_mode

    ; СЕГМЕНТ ДАННЫХ ЯДРА НА ЧТЕНИЕ/ЗАПИСЬ [DS = 0x0010]
    ; Начинается там же, где и код ядра (лимит 1 Мб)
    ; --------------------------
    mov eax, 0xFFFFF
    mov ebx, Protected_Core
    mov cx,  0x90 + 0x2 + 0x4000 ; PRESENT (0x80) + DPL_0 (0) + BIT_SYSTEM (0x10) + DATA_READ_WRITE (0x2) + BIT_DEFAULT_SIZE_32 (0x4000)
    call create_descriptor_real_mode

    ; СЕГМЕНТ СТЕКА [SS = 0x0018] 
    ; 0x90000 .. 0x9FFFF (64 кб)
    ; ---
    mov eax, 0x0FFFF
    mov ebx, 0x90000
    mov cx,  0x90 + 0x2 + 0x4000 ; PRESENT (0x80) + DPL_0 (0) + BIT_SYSTEM (0x10) + DATA_READ_WRITE  (0x2) + BIT_DEFAULT_SIZE_32 (0x4000)
    call create_descriptor_real_mode

    ; СЕГМЕНТ ДАННЫХ [FS = 0x0020]
    ; Вся доступная память 4Гб
    ; ---
    mov eax, 0xFFFFF
    xor ebx, ebx
    mov cx,  0x90 + 0x2 + 0x8000 + 0x4000 ; PRESENT (0x80) + DPL_0 (0) + BIT_SYSTEM (0x10) + DATA_READ_WRITE  (0x2) + GRANUL + BIT_DEFAULT_SIZE_32 (0x4000)
    call create_descriptor_real_mode    

    ; ------------------------------------------------------
    
    ; Загрузка GDT
    mov word  [0x7C00], 0xFFFF 
    mov dword [0x7C02], 0x18000
    lgdt [0x7C00]

    ; Загрузка IDT
    mov word  [0x7C06], 0x7FF
    mov dword [0x7C08], 0x28000
    lidt [0x7C06]

    ret