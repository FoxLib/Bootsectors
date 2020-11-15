; DEBUG-SAMPLE: dd if=/dev/zero of=d.img bs=512 count=3915776

        include "lib.asm"

; --------------------------------------------
; Установщик (REAL-MODE)
; --------------------------------------------

installer:

        ; call installer_test_disk ; проверка на диск, откуда запускается - если это флешка, то запустить далее

        call installer_disk_detection        
        
        ivk3 paint_box,  0x0000, 0x174F, 0x1720
        ivk3 paint_box,  0x1800, 0x184F, 0x3020        
        ivk2 paint_text, 0x1801, strmain.menu
        ivk2 paint_text, 0x0101, strmain.welcome1
        ivk2 paint_text, 0x0201, strmain.welcome0
        ivk2 paint_text, 0x0301, strmain.welcome1
        ivk2 paint_text, 0x0501, strmain.welcome2
        ivk2 paint_text, 0x0601, strmain.welcome3

        ivk2 paint_frame, 0x080C, 0x1042       
        ivk2 paint_text,  0x080E, strmain.frame1
        ivk2 paint_text,  0x0A0E, strmain.frame2        

        ; Рисование доступных дисков
        mov  si, DISKS
        mov  bx, 0x0D10

        ; Нарисовать "выход"
        ivk2 paint_text, bx, strmain.frame3
        add bx, 5

.drawdisk:

        lodsb
        and  al, al
        je .toredraw
        
        ; Нарисовать область диска
        add al, 'C' - 0x80
        mov [strmain.frame3 + 1], al
        ivk2 paint_text, bx, strmain.frame3
        add bx, 5

        ; Доступные меню
        inc [.menu_select + 2]
        jmp .drawdisk

.toredraw:

        ; Если дисков нет
        cmp [.menu_select + 2], byte 0
        je .exit

        mov ax, 0x0D10

.menu_redraw:

        ; Рисование подложки
        ivk3 paint_substrate, 0x080C, 0x1142, 0x70

        ; Базируется на AX
        movzx ax, [.menu_select]
        imul ax, 5
        add ax, 0x0D10

        mov bx, ax
        add bx, 0x0002       

.show_menu:

        ; Высветить меню
        ivk3 paint_substrate, ax, bx, 0x0047

        ; Ожидание нажатия клавиш
        mov si, installer.menu_select
        call key_interaction
        cmp al, 13
        je .commit
        jmp .menu_redraw

.commit:

        ; Рисовать рамку
        ivk2 paint_text, 0x0F10, strmain.frame4

        ; Записать номер диска, куда будет установка
        movzx eax, [.menu_select]  
        and ax, ax
        je .exit

        dec ax
        mov al, [DISKS + eax]
        mov [.disk_to], al

        ; Кол-во секторов
        mov eax, [RDBUF + 10h]
        mov [.sectors], eax

        ; Получить кол-во общих секторов
        mov dl, [disk_bios]
        mov di, DISKS
        mov ah, 48h
        mov si, RDBUF
        int 0x13

        ; Порция секторов за 1 раз (32 сектора, 16кб)
        mov [DAP + 2], word 32 

.write_disk:
        
        ; -- читать сектора
        mov ah, 0x42
        mov si, DAP
        mov dl, [disk_bios]
        int 0x13

        ; Если это первый сектор - установить пометку 
        ; (чтобы потом не запускать с диска)        
        cmp dword [DAP + 8], 0
        jne @f
        mov dword [0x81BA], 'DISK'
@@:
        ; -- писать сектор 
        mov ah, 0x43
        mov si, DAP
        mov dl, [.disk_to]
        int 0x13

        ; К следующему сектору
        add  [DAP + 8], dword 32
        test [DAP + 8], byte 0xFF
        jne @f

        ; counter
        mov eax, [DAP + 8]
        mov ebx, [.sectors]
        shr ebx, 5                 ; mul 32 (..32)
        xor edx, edx
        div ebx
        add al, 0x11

        ; ... show progress
        mov  ah, 0x0F
        ivk3 paint_substrate, 0x0F11, ax, 0x60

        ; ---
        mov  eax, [RDBUF + 10h]

        ; пропечатать остаточное количество
        mov  cl, 8
        mov  di, strmain.frame5
.c4:
        rol  eax, 4
        push eax
        and  al, 0xF
        cmp  al, 10
        jc .c3
        add  al, 7
.c3:    add  al, '0'
        stosb
        pop eax
        dec cl
        jne .c4


        ivk2 paint_text, 0x0F34, strmain.frame5

@@:
        sub  [RDBUF + 10h], dword 32
        jns .write_disk

.exit:
brk
        ret

        ; 1) начальная позиция, 2) старт, 3) конец
        .menu_select db 0, 0, 0
        .disk_to db 0
        .sectors dd 0

; Определить доступные диски
; --------------------------------------------
installer_disk_detection:

        ; Определить доступные диски
        mov cx, 8
        mov dl, 0x80
        mov di, DISKS

.c1:    pusha
        mov ah, 48h
        mov si, RDBUF
        int 0x13
        popa        
        jc @f

        ; Собственный диск не брать в расчет
        cmp dl, [disk_bios]
        je @f

        ; Пометить как доступный диск
        mov al, dl
        stosb

@@:     inc dl
        loop .c1
        ret

; Disk Address Packet
; --------------------------------------------

DAP:    dw 0x0010  ; 0 размер DAP = 16
        dw 0x0001  ; 2 читать 1 сектор
        dw 0x0000  ; 4 смещение (0)
        dw 0x0800  ; 6 сегмент (800h * 10h = 8000:0000)
        dq 0       ; 8 номер сектора от 0 до N-1

RDBUF:  dw 0x1E    ; 00h Размер буфера
        dw 0       ; 02h Флаги
        dd 0       ; 04h Кол-во цилиндров
        dd 0       ; 08h Кол-во головок
        dd 0       ; 0Ch Секторов на дорожку
        dq 0       ; 10h Количество секторов
        dw 0       ; 18h Байт на сектор
        dd 0       ; 1Ah Enhanced Disk Drive (EDD) configuration parameters

DISKS:  db 16 dup 0 ; Доступные диски