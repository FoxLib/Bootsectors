; Программа загружена по адресу 1000h
BASEADDR        EQU 1000h
XMS_HANDLERS    EQU 0x110000
XMS_START       EQU 0x190000

XMS.BlocksNum   dw 0            ; Количество выделенных блоков
XMS.TopMemory   dd XMS_START    ; Стартовая позиция свободной памяти

; ----------------------------------------------------------------------
; void** xms_alloc(uint32 size_t)
; @return EAX Указатель на дескриптор
;         EDI Указатель на память
;
; Выделить блок памяти - всегда начиная с последней позиции
; Выделяет ECX байт памяти в области XMS
; Отдается указатель на таблицу дескрипторов вида:
;
; +0 DWORD <Addr>
; +4 DWORD <Size>
; ...

XMS.Alloc:

        mov     eax, [XMS.TopMemory]
        push    eax
        add     [XMS.TopMemory], ecx

        movzx   edi, [XMS.BlocksNum]
        lea     edi, [8*edi + XMS_HANDLERS]
        call    XMS.Write32
        mov     eax, ecx
        call    XMS.Write32

        inc     [XMS.BlocksNum]
        lea     eax, [edi - 8]
        pop     edi
        ret

; ----------------------------------------------------------------------
; Перераспределить память

XMS.Realloc:

        ret

; ----------------------------------------------------------------------
; Освободить память

XMS.Free:

        ret

; ----------------------------------------------------------------------
; Убрать мусор и укомплектовать память

XMS.Compact:

        ret

; ----------------------------------------------------------------------
; Вход в защищенный режим по адресу CS:DI

XMS.PMEnter:

        pushf
        cli
        mov     ax, cs
        shl     ax, 4
        add     di, ax
        mov     word [.locator], di
        mov     eax, cr0
        or      al, 1
        mov     cr0, eax
        jmp     far [.locator]
        
.locator dd 00100000h

; ----------------------------------------------------------------------
; Покинуть защищенный режим. Переход только через // JMP XMS.PMLeave //

XMS.PMLeave:

        mov     eax, cr0
        and     al, 0FEh
        mov     cr0, eax
        jmp     (BASEADDR shr 4) : .rmode
.rmode: xor     ax, ax
        mov     gs, ax
        popf
        ret
        
; ----------------------------------------------------------------------
; EAX = [ESI]

XMS.Read32:

        pushf
        push    ebx
        cli
        mov     eax, cr0
        or      al, 1
        mov     cr0, eax
        jmp     0010h : .pmode + 1000h
.rmode: xor     ax, ax
        mov     gs, ax
        mov     eax, ebx
        pop     ebx
        popf
        ret
.pmode: mov     ax, 8
        mov     gs, ax
        mov     ebx, [gs: esi]
        add     esi, 4
        mov     eax, cr0
        and     al, 0FEh
        mov     cr0, eax
        jmp     (BASEADDR shr 4) : .rmode

; ----------------------------------------------------------------------
; [edi] = eax

XMS.Write32:

        pushf
        push    eax ebx
        cli
        mov     ebx, cr0
        or      bl, 1
        mov     cr0, ebx
        jmp     0010h : .pmode + 1000h
.rmode: xor     ax, ax
        mov     gs, ax
        pop     ebx eax
        popf
        ret
.pmode: mov     bx, 8
        mov     gs, bx
        mov     [gs: edi], eax
        add     edi, 4
        mov     eax, cr0
        and     al, 0FEh
        mov     cr0, eax
        jmp     (BASEADDR shr 4) : .rmode

; ----------------------------------------------------------------------
; Копировать из [esi] -> [edi], ecx байт

XMS.Copy:

        pushf
        push    ebx cx
        cli
        mov     ebx, cr0
        or      bl, 1
        mov     cr0, ebx
        jmp     0010h : .pmode + 1000h
.rmode: xor     ax, ax
        mov     gs, ax
        pop     cx ebx
        popf
        ret
.pmode: mov     bx, 8
        mov     gs, bx
@@:     mov     al, [gs: esi]
        mov     [gs: edi], al
        inc     esi
        inc     edi
        dec     ecx
        jne     @b
        mov     eax, cr0
        and     al, 0FEh
        mov     cr0, eax
        jmp     (BASEADDR shr 4) : .rmode
        
; ----------------------------------------------------------------------
; Аналог REP STOSB

XMS.RepStosb:

        push    esi eax bx
        mov     bx, ax
        mov     esi, esi
        mov     di, XMS.RepStosb.PM
        call    XMS.PMEnter
        mov     edi, esi
        pop     bx eax esi
        ret
        
XMS.RepStosb.PM:

        mov     di, 8
        mov     gs, di
@@:     mov     [gs: esi], bl
        inc     esi
        dec     ecx
        jne     @b
        jmp     XMS.PMLeave

; ----------------------------------------------------------------------
; Аналог LODSB

XMS.Lodsb:

        push    di bx eax 
        mov     bx, ax
        mov     di, XMS.Lodsb.PM
        call    XMS.PMEnter
        pop     eax
        mov     al, bl
        pop     bx di
        ret
        
XMS.Lodsb.PM:

        mov     di, 8
        mov     gs, di
@@:     mov     bl, [gs: esi]
        inc     esi
        jmp     XMS.PMLeave

; ----------------------------------------------------------------------
; Аналог STOSB

XMS.Stosb:

        push    bx eax 
        push    esi
        mov     bx, ax
        mov     esi, edi
        mov     di, XMS.Stosb.PM
        call    XMS.PMEnter
        mov     edi, esi
        pop     esi
        pop     eax bx 
        ret
        
XMS.Stosb.PM:

        mov     di, 8
        mov     gs, di
@@:     mov     [gs: esi], bl
        inc     esi
        jmp     XMS.PMLeave

; ----------------------------------------------------------------------
; Загрузить файл в XMS 
; EDI - Физический адрес, куда выгрузить
; BX  - FileID Handler
; BP  - количество байт на загрузку

XMS.LoadFile:

        sub     [FreeBlock], 512
  
.readfile:

        mov     ah, 3Fh
        mov     cx, 512
        mov     dx, [FreeBlock]
        int     21h
        jb      .exit  
        and     ax, ax
        je      .exit
        
        ; Скопировать новую порцию
        movzx   esi, dx
        add     esi, BASEADDR
        movzx   ecx, ax
        call    XMS.Copy
        
        ; При превышении размера загружаемого файла, выход
        sub     bp, 512
        js      .exit
        je      .exit
        jmp     .readfile
.exit:  add     [FreeBlock], 512
        ret
