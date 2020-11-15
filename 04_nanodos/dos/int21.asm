; 
; Диспетчер прерываний DOS
;
; http://msdosworld.ru/spravochnie_materiali/spravochnik_programmista_po_operatsionnoy_sisteme_ms-dos/64_kodi_oshibok_dos.html


align 2


; ----------------------------------------------------------------------
; Диспетчер API DOS
; ----------------------------------------------------------------------

dos.int20h:

        xor     ax, ax

dos.int21h:

        ; Сохранение последнего вызова SS:SP, AX и других регистров
        mov     [cs: dos.int21h.eax], eax
        mov     [cs: dos.int21h.ebx], ebx
        mov     [cs: dos.int21h.ecx], ecx
        mov     [cs: dos.int21h.edx], edx
        mov     [cs: dos.int21h.esi], esi
        mov     [cs: dos.int21h.edi], edi
        mov     [cs: dos.int21h.ebp], ebp
        mov     [cs: dos.int21h.fs],  fs
        mov     [cs: dos.int21h.ss],  ss
        mov     [cs: dos.int21h.sp],  sp         
        xor     ax, ax
        mov     fs, ax

        mov     bp, sp
        mov     ax, [bp + 4]        
        mov     [cs: dos.int21h.flags], ax

        ; Определить SS:SP в области HMA
        mov     ax, ss
        cmp     ax, 0FFFFh
        je      @f
        
        ; Случай, когда вызов произошел из другого сегмента (не HMA)
        mov     ax, cs
        mov     ss, ax
        xor     sp, sp        
@@:     ; --------------------------------------------------------------

        ; call [dos.int21h.relocation + ah*2]
        ; Вызов обработчика

        mov     al, byte [cs: dos.int21h.eax + 1]
        test    al, 80h
        je      @f
        
        ; AH=01, CF=1
        mov     word [cs: dos.int21h.eax + 1], 01h
        or      byte [cs: dos.int21h.flags], 01h
        jmp     dos.int21h.ServiceDone
        
        ; Перейти к сервисной функцииЮ если она есть
@@:     xor     ah, ah
        add     ax, ax
        mov     bx, dos.int21h.relocation
        add     bx, ax
        mov     ax, [cs: bx]
        and     ax, ax
        je      dos.int21.panic
        call    word [cs: bx]

dos.int21h.ServiceDone:

        ; Восстановить регистры
        ; Либо же там будут значения, которые назначил INT 21h
        ; --------------------------------------------------------------
        mov     ss,  [cs: dos.int21h.ss]
        mov     fs,  [cs: dos.int21h.fs]
        mov     sp,  [cs: dos.int21h.sp]
        mov     ax,  [cs: dos.int21h.flags]
        mov     bp, sp
        mov     [bp + 4], ax
        mov     eax, [cs: dos.int21h.eax]
        mov     ebx, [cs: dos.int21h.ebx]
        mov     ecx, [cs: dos.int21h.ecx]
        mov     edx, [cs: dos.int21h.edx]
        mov     esi, [cs: dos.int21h.esi]
        mov     edi, [cs: dos.int21h.edi]
        mov     ebp, [cs: dos.int21h.ebp]
        iret
        
; ----------------------------------------------------------------------
; Отладочная фатальная ошибка. Используется для "перехвата" и обработки
; сервисных функции DOS. В будущем, возможно, будет удалено.

dos.int21.panic:

        mov     ax, 0003h
        int     10h
        mov     ax, 0B800h
        mov     es, ax
        mov     ax, cs
        mov     ds, ax
        mov     cx, 2000
        xor     di, di
        mov     ax, 2F20h
        rep     stosw
        
        mov     di, (80 + 1)*2
        mov     ax, 4F20h
        mov     cx, 22
        rep     stosw

        ; Пропечатать строки
        mov     di, (80 + 2)
        mov     si, .msg_kpanic        
        call    .printz
        add     di, 160
        mov     si, .msg_reg_eax
        call    .printz        
        add     di, 80
        mov     si, .msg_reg_ebx
        call    .printz
        add     di, 80
        mov     si, .msg_reg_ecx
        call    .printz
        add     di, 80
        mov     si, .msg_reg_edx
        call    .printz        
        mov     di, (3*80 + 20)
        mov     si, .msg_reg_esp
        call    .printz
        add     di, 80
        mov     si, .msg_reg_ebp
        call    .printz
        add     di, 80
        mov     si, .msg_reg_esi
        call    .printz
        add     di, 80
        mov     si, .msg_reg_edi
        call    .printz
    
        ; Вывод значений регистров до запроса
        mov     di, (3*80 + 7)
        mov     eax, [cs: dos.int21h.eax]
        call    .printh32
        add     di, 80
        mov     eax, [cs: dos.int21h.ebx]
        call    .printh32        
        add     di, 80
        mov     eax, [cs: dos.int21h.ecx]
        call    .printh32        
        add     di, 80
        mov     eax, [cs: dos.int21h.edx]
        call    .printh32
        mov     di, (3*80 + 25)
        movzx   eax, [cs: dos.int21h.sp]
        add     ax, 6  ; Поскольку был вызыван INT, скорректировать
        call    .printh32
        add     di, 80
        mov     eax, [cs: dos.int21h.ebp]
        call    .printh32
        add     di, 80
        mov     eax, [cs: dos.int21h.esi]
        call    .printh32
        add     di, 80
        mov     eax, [cs: dos.int21h.edi]
        call    .printh32
        jmp     $

; ----------------------------------------------------------------------

.printz:

        push    di
        add     di, di
@@:     lodsb
        and     al, al
        je      .exit
        stosb
        inc     di
        jmp     @b
.exit:  pop     di
        ret        

; Печать 32-х битной строки
.printh32:

        push    di
        add     di, di
        mov     cx, 8
@@:     rol     eax, 4
        push    eax
        and     al, 0xF
        cmp     al, 10
        jb      $+4
        add     al, 7
        add     al, '0'
        stosb
        pop     eax
        inc     di
        loop    @b
        pop     di
        ret

        
.msg_kpanic     db 'DOS Service 21h Trap', 0
.msg_reg_eax    db 'EAX: ', 0
.msg_reg_ebx    db 'EBX: ', 0
.msg_reg_ecx    db 'ECX: ', 0
.msg_reg_edx    db 'EDX: ', 0
.msg_reg_esp    db 'ESP: ', 0
.msg_reg_ebp    db 'EBP: ', 0
.msg_reg_esi    db 'ESI: ', 0
.msg_reg_edi    db 'EDI: ', 0
        
; ----------------------------------------------------------------------
; Таблица, по которой просматриваются функции DOS, AH = 0 до 127
; ----------------------------------------------------------------------

dos.int21h.relocation:

        ; 00-0F
        dw      dos.int21h.Int20
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0

        ; 10-1F
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0

        ; 20-2F
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      dos.Int21h.SetVector
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        
        ; 30-3F
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      dos.Int21h.GetVector
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      dos.int21h.OpenFile
        dw      dos.int21h.CloseFile
        dw      dos.int21h.ReadFile

        ; 40-4F
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      dos.int21h.ExecFile
        dw      0
        dw      0
        dw      0
        dw      0

        ; 50-5F
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0

        ; 60-6F
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0

        ; 70-7F
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0

; ----------------------------------------------------------------------
; Модули-обработчики
; ----------------------------------------------------------------------

        include "routines/search_dir.asm"
        include "routines/calc_cluster.asm"
        include "routines/get_next_cluster.asm"
        include "routines/set_root_cluster.asm"
        include "routines/fetch_dir_part.asm"
        
        include "int21/00_int20.asm"
        include "int21/35_getvector.asm"
        include "int21/25_setvector.asm"
        include "int21/3d_openfile.asm"
        include "int21/3e_closefile.asm"
        include "int21/3f_readfile.asm"
        include "int21/4b_execfile.asm"
