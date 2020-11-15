
        macro   brk { xchg bx, bx }
        org     7c00h

        jmp     near start

; ----------------------------------------------------------------------
; BPB: Bios Parameter Block
; ----------------------------------------------------------------------
        db      "FLOPPY12"      ; 7С03 Signature
        dw      200h            ; 7С0B Bytes in sector
        db      1               ; 7С0D Sectors by cluster
        dw      1               ; 7С0E Count reserver sectors
        db      2               ; 7С10 Count of FAT
        dw      00E0h           ; 7С11 Count of Root Entries (224)
        dw      0B40h           ; 7С13 Total count of sectors
        db      0F0h            ; 7С15 Media
        dw      9               ; 7С16 Sectors in FAT
        dw      12h             ; 7С18 Sectors on track
        dw      2               ; 7С1A Count of heads
        dd      0               ; 7С1C Hidden Sectors (large)
        dd      0               ; 7С20 Total Sectors
        db      0               ; 7С24 Number of Phys.
        db      1               ; 7С25 Flags
        db      29h             ; 7С26 Ext Sig
        dd      07E00000h       ; 7С27 Serial Numbers (ES:BX)
        db      'CORE    BIN'   ; 7С2B Label / Exec File
        db      'FAT12    '     ; 7С36 Type of FS
; ----------------------------------------------------------------------

start:  sti
        cld
        xor     ax, ax
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     sp, 7c00h        
        mov     [$0000], dl         ; Записать, откуда был загружен
        mov     ax, 19
dir:    les     bx, [7c27h]
        call    ReadSector
        mov     di, bx
        mov     bp, 16
item:   mov     si, 7c2bh           ; ds:si - тут строка для сравнения
        mov     cx, 12              ; 11 + 1
        push    di
        repz    cmpsb               ; сравнить строку
        pop     di
        jcxz    file_found
        add     di, 32
        dec     bp
        jne     item
        inc     ax
        sub     word [7c11h], 16
        jne     dir
        int     18h

; ----------------------------------------------------------------------
; Загрузка файла из файловой системы FAT12
; ----------------------------------------------------------------------

file_found:

        mov     ax, [es: di + 1Ah]
        mov     [7c22h], word 800h  ; адрес, куда пишется программа
next:   push    ax
        add     ax, 31
        les     bx, [7c20h]
        call    ReadSector
        add     [7c22h], word 20h
        pop     ax
        mov     bx, 3
        mul     bx
        push    ax
        shr     ax, 1 + 9
        inc     ax                  ; +1 bpb
        mov     si, ax
        les     bx, [7c27h]         ; es:bx=07e0:0000
        call    ReadSector
        pop     ax
        mov     bp, ax
        mov     di, ax
        shr     di, 1
        and     di, 0x1FF
        mov     ax, [es: di]        ; 07e0
        cmp     di, 0x1FF
        jne     @f
        push    ax
        xchg    ax, si
        inc     ax
        call    ReadSector
        pop     ax
        mov     ah, [es: bx]
@@:     test    bp, 1
        jz      @f
        shr     ax, 4
@@:     and     ax, 0x0FFF          ; 12
        cmp     ax, 0x0FF0
        jb      next
        jmp     8000h

; ----------------------------------------------------------------------
; Чтение сектора
; AX - номер сектора, ES:BX указатель на данные
; ----------------------------------------------------------------------

ReadSector:

        push    ax
        mov     cx, 12h
        cwd
        div     cx              ; ax = ax / 18, dx = ax % 18
        xchg    ax, cx          ; cx = ax
        mov     dh, cl
        and     dh, 1
        shr     cx, 1
        xchg    ch, cl
        shr     cl, 6
        inc     dx
        or      cl, dl
        mov     dl, 0
        mov     ax, 0201h
        int     13h             ; es:bx, cx/dx
        pop     ax
        ret

; ----------------------------------------------------------------------
; ESTIMATED FILL ZERO
; ----------------------------------------------------------------------

        times   7c00h + (512 - 2) - $ db 0x00
        dw      0xAA55
