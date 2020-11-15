; Выделение памяти на уровне ассемблера
; ptr(1), count(2)
fast_malloc:

    push ebp
    mov  ebp, esp

    push ds     
    mov  ax, fs
    mov  ds, ax
    mov  edi, [ebp + par1]

.do:

    mov esi, 0x81004

.catalog_loop:

    ; Доступность каталога
    test [esi], word 0x200
    jne .next_catalog
    test [esi], byte 0x1
    je  .next_catalog

    ; Расчет указателя на каталог страниц
    mov  eax, [esi]
    and  eax, 0xfffff000

    ; Перебор страниц (от 0 до 1022-й) 1023-я системная
    xor  ecx, ecx

.page_loop:

    ; Адрес страницы в каталоге
    mov  ebx, [eax + 4*ecx]
    inc  ecx    

    ; Страница занята
    test bx, 0x0200 
    jne .next_page

    ; Добавить новую страницу в список страниц
    and ebx, 0xfffff000
    mov [edi], ebx
    add edi,  4
    or [eax + 4*ecx - 4], word 0x200

    ; Занять страницу
    dec dword [ebp + par2]
    je .fin

.next_page:

    ; Повторять пока не будет предел
    cmp ecx, 1023
    jne .page_loop

    ; Отметить каталог как занятый
    or [esi], word 0x200

.next_catalog:

    add esi, 4
    cmp esi, 0x82000
    jb .catalog_loop

    ; Не хватило свободной памяти
    mov eax, [ebp + par2]
    jmp .exit

.fin: 

    cmp ecx, 1023
    jne @f

    ; Мы заняли последнюю страницу в каталоге
    or [esi], word 0x200
@@:
    ; Памяти хватило
    xor eax, eax

.exit:
    pop ds
    leave
    ret