MEMORY_SIZE    dq 0 ; Объем реальной памяти
VIRTUAL_MEMORY dq 0 ; Объем виртуальной памяти

; ------------------------------------------------------------------------------------------------
; Разметка страниц в зависимости от используемого размера памяти 
; Количество страниц всегда будет занимать 1/512 от реального объема памяти
; Например, 4 Гб будут описывать 8 Мб страниц
; Так как 1 каталог может содержать в себе только 512 страниц в 64-х битном режиме
;
; Разметка PRESENT страниц производится до области доступной памяти, и в области LFB (3 мб)
; Остальные страницы не являются доступными сразу
; ------------------------------------------------------------------------------------------------

page64_create:

    ; Очищаем страницы
    mov    edi, PAGE_PLM4
    mov    ecx, 6000h shr 2
    xor    eax, eax
    rep    stosd                         

    ; Установка первых указателей (инициализация главного региона памяти)
    mov    dword [PAGE_PLM4], PAGE_PDP + 111b ; PML4 указатель на первую PDP table 

    ; PDP указатель на первую PD (page directory), вторую, третью и четвертую таблицы страниц
    mov    dword [PAGE_PDP + 0000h],  PAGE_PD + 111b + 0
    mov    dword [PAGE_PDP + 0008h],  PAGE_PD + 111b + 1000h
    mov    dword [PAGE_PDP + 0010h],  PAGE_PD + 111b + 2000h
    mov    dword [PAGE_PDP + 0018h],  PAGE_PD + 111b + 3000h

    ; Создаем каталог страниц (4 Гб)
    mov    edi, PAGE_PD
    mov    eax, PAGE_PT + 111b
    mov    ecx, 2048 ; 2048 x 8 элементов займет 4 x 4096

.pt_entries:

    stosd
    add    edi, 4
    add    eax, 1000h
    loop .pt_entries

    ; Адрес первой таблицы страниц PT
    mov    edi, PAGE_PT
    mov    ecx, 0x100000   ; 1048576 страниц пл 4096 = 4 Гб (занимает 8 Мб)
    mov    eax, 0 + 111b   ; 111b -- права U/S=1,RW=1,PRESENT=1    
    mov    edx, dword [vesa_real] ; Область памяти, занятая VESA
    lea    esi, [edx + 0x300000] ; Максимальное значение VESA

.page_entries:

    or     eax, 1
    mov    ebx, eax
    and    ebx, 0xFFFFF000

    ; Ниже области доступной памяти ставить бит P=1
    cmp    ebx, dword [MEMORY_SIZE]
    jb     .low_mem

    ; Если выше области доступной памяти, но ниже LFB - то ZERO
    cmp    ebx, edx
    jb     .np

    ; Если ниже области конца LFB - то отмечает присутствие
    cmp    ebx, esi
    jb     .low_mem

.np:
    ; очистить бит 1 (present)
    and    eax, 0xFFFFFFFE 

.low_mem:
 
    stosd
    push   eax 
    xor    eax, eax         ; 64 разрядная страница (обязательно очищать)
    stosd
    pop    eax
    add    eax, 1000h       ; (page)
    loop   .page_entries

    ; загружаем 4-х уровневый каталог страниц 
    mov    eax, PAGE_PLM4
    mov    cr3, eax         

    ret

; --------------------------------------------------------------------------------------
; Определить размер памяти
; --------------------------------------------------------------------------------------

get_memory_size:

    mov edi, 0x00900000
    
.loop:

    mov [edi], dword 0xAA55AA55
    cmp [edi], dword 0xAA55AA55
    jne .memory_size

    add edi, 0x00100000
    jmp .loop

.memory_size:

    mov dword [MEMORY_SIZE],    edi ; Объем физической памяти (до 4 Гб)
    mov dword [VIRTUAL_MEMORY], edi ; Объем виртуальной памяти реально выше, чем физической
    
    ret        