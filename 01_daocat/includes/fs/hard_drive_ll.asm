; -------------------------------------
; ЧТЕНИЕ ДАННЫХ С ATA
; EAX - блок по 512 байт
; ES:EDI - куда пишем
; -------------------------------------

ata_read:

    pushad
    push  eax

    mov   edx, hdbase
    inc   edx

    ; Запись команд инициализации (0x1f1 = 0, 0x1f2 = 1)
    mov   al, 0
    out   dx, al

    inc   edx
    mov   al, 1
    out   dx, al

    ; Биты 0..7
    inc   edx
    pop   ax
    out   dx, al

    ; Биты 8..15
    inc   edx
    shr   ax, 8
    out   dx, al

    ; Биты 15..23
    inc   edx
    pop   ax
    out   dx,al

    ; Биты 24..27
    ; Бит  28 - 0-master, 1-slave
    ; Бит  29..31 = 1

    inc   edx
    shr   ax, 8
    and   al, 0x0F
    add   al, hdid
    add   al, 0xE0
    out   dx, al

    ; Исполнение команды чтения с диска
    inc   edx
    mov   al, 20h
    out   dx, al

    ; Ожидаем ответа не busy
.hdwait:

    in    al, dx
    test  al, 128
    jnz   .hdwait

    ; Пишем в память из канала данных 512 байт
    mov   ecx, 256
    mov   edx, hdbase
    cld
    rep   insw

    popad
    ret

; -----------------------------------------------------------------------------------

hdbase   equ  0x1f0      ; 0x1f0 for primary device
                         ; 0x170 for secondary device
                         ;
hdid     equ  0x00       ; 0x00 for master hd
                         ; 0x10 for slave hd
