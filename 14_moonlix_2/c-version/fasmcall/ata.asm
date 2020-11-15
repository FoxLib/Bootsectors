; Данные и параметры      | Порт контроля
; ----------------------------------------
; 0x1F0 Primary Bus 0     | 0x3F6
; 0x170 Secondary Bus 0   | 0x376
; 0x1E8 Primary Bus 1     | 0x3E6
; 0x168 Secondary Bus 1   | 0x366

; number(1), base(2) - базовый адрес для вывода данных
; http://www.cs.vsb.cz/grygarek/tuox/sources2/hdd/111-1c.pdf

outsw_512:

    push ebp
    mov  ebp, esp
    mov  dx, [ebp + par2]

    push es
    mov  ax, fs
    mov  es, ax

    ; Указатель на параметры дисков
    mov  eax, [ebp + par1]
    shl  eax, 9
    lea  edi, [0x111000 + eax]

    ; Записывается информация о диске
    mov  cx, 256
    rep  insw

    pop  es
    leave
    ret

; Запись в буфер
; io_base_addr(1), block_512(2)
outsw_data:

    push ebp
    mov  ebp, esp
    mov  dx, [ebp + par1]

    push es
    mov  ax, fs
    mov  es, ax

    ; Указатель на параметры дисков
    mov  eax, [ebp + par2]
    shl  eax, 9
    lea  edi, [0x112000 + eax]

    ; Записывается информация о диске
    mov  cx, 256
    rep  insw

    pop  es
    leave
    ret