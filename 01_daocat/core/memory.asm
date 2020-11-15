    use32

    ; Подключение модулей
    include "modules/alloc.asm" 

; Первый мегабайт RAM должен быть тождественно отображен, т.к. он является системным
; В каталоге страниц

; -----------
; Установка страничного преобразования 1-го мегайта
; Остальные 4мб страниц будут располагаться уже в верхней
; памяти и выделяться динамически в зависимости от размера памяти
; ----------

memory_paged_init:

    mov ax, SEGMENT_PDBR
    mov es, ax

    mov ax, SGN_DATA
    mov ds, ax

    ; Вычисление указателя на первую незанятую страницу в 1мб памяти
    ; Последняя незанятая страница будет 0x5F (0x60-й идет уже 0x60000 GDT)    
    mov edx, ((0x10000 + END_OF_CODE + END_OF_DATA) shr 12) + 1

    ; Очистка PDBR, первого каталога страниц 
    xor edi, edi
    xor eax, eax
    mov ecx, (1024 * 3)
    rep stosd

    ; Первая страница идет сразу же за каталогом
    ; Страница недоступна со всех уровней привилегии
    ; Флаги P=1, R/W = 1, U/S = 0
    mov eax, (PDBR_ADDRESS32 + 0x1000) OR 0x03

    ; Указываем первый каталог страниц (он охватывает пространство памяти от 0 до 4мб)
    ; 1024 элементов по 4кб = 4мб. Используется только 256 для 1MB адресов
    mov [es:0], eax

    ; Теперь пишем первый каталог страниц (на него была ссылка выше по коду)
    mov edi, 0x1000

    ; Счетчик страниц
    xor cx, cx
 
    ; P=1, R/W = 1, U/S = 0
    mov eax, 0x00000003

    ; Установка 256 элементов трансляции 
    ; страниц для первого мегабайта. Для незанятой области установка 0
    
@mpi_loop:

    stosd
    add eax, 0x1000    
    inc cx
    cmp cx, 0x0100
    jne @mpi_loop

    ; Установка PDBR
    mov eax, PDBR_ADDRESS32
    mov cr3, eax

    ; ---
    ; Теперь размечаем страницы под видеопамять (0 RPL)
    ; ---

    mov ax, SEGMENT_PDBR
    mov es, ax

    ; Вычисление указателя для LFB
    mov eax, [VESA_LFB]   
    and eax, 0xFFC00000
    shr eax, (10 + 12)  ; Берутся только верхние 10 битов

    ; LFB_PAGE - Физический адрес номера страницы таблицы указателя страниц видеопамяти
    ; 0x03 = PRESENT | READ/WRITE    
    mov ebx, (LFB_VIDEO_PGNUM shl 12) OR (0x03) 

    ; Разметка страниц под LFB
    mov ecx, [VESA_LFB_SIZE]

@mpi_loop_pdbr:

    ; Пишем указатель в PDBR на таблицу адресов видеопамяти
    mov dword [es:4*eax], ebx 
    inc eax       ; Следующий 4-х мегабайтный сегмент в PDBR
    add ebx, 4096 ; Следующая таблица страниц
    sub ecx, 0x400000 ; +4 mb

    je  @mpi_fin_pdbr  ; Если было кратно 4 мб, выход
    jns @mpi_loop_pdbr ; И если было меньше 4 мб, то тоже выход из цикла

@mpi_fin_pdbr:

    ; Теперь перечисляем страницы LFB
    mov ecx, [VESA_LFB_SIZE] 
    mov eax, [VESA_LFB]  

    ; Заполняются активные страницы видеопамяти
    mov dx, SEGMENT_WHOLE
    mov ds, dx

    ; Базовый адрес страницы
    and eax, 0xFFFFF000
    or  al,  0x03 ; present + r/w

@mpi_vloop:

    mov ebx, eax

    ; 4 страницы (еще один бит задействован для видеопамяти)
    ; Максимальная адресация памяти - 16 Мб

    and ebx, 0x00FFF000 
    shr ebx, 12
    mov [ds: (LFB_VIDEO_PGNUM shl 12) + 4*ebx], eax

    add eax, 0x1000 ; +4kb
    sub ecx, 0x1000 ; -4kb
    jns @mpi_vloop
    
@mpi_set_pg:

    ; Устанавливаем 31-й бит (PG)
    mov eax, cr0
    bts eax, 31      
    mov cr0, eax
    jmp $+2
    ret