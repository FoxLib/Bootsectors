
        org     $7C00
        macro   brk { xchg bx, bx }

; ----------------------------------------------------------------------
; Paremeters
; ----------------------------------------------------------------------

constBootIP         EQU $7C00
paramDiskID         EQU $7C00   ; BYTE  Disk ID
paramCountHeads     EQU $7C01   ; BYTE  Heads count
paramCountSectors   EQU $7C02   ; BYTE  Sectors count
paramLBA            EQU $7C03   ; DWORD Requested LBA
paramBuffer         EQU $7C07   ; WORD  ES:DI

; ----------------------------------------------------------------------
; Initialize segments
; ----------------------------------------------------------------------

        cli
        cld
        xor     ax, ax
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     sp, $7C00
        mov     [paramDiskID], dl       ; Save BIOS Disk ID

        ; Get Drive Parameters
        ; https://en.wikipedia.org/wiki/INT_13H#INT_13h_AH=08h:_Read_Drive_Parameters
        mov     ah, $08
        xor     di, di
        int     13h
        mov     si, err2
        jc      panic

        ; Save hard disk params
        and     cx, $3F
        mov     [paramCountHeads], dh
        mov     [paramCountSectors], cl

; ----------------------------------------------------------------------
; Search FAT32 Partition
; ----------------------------------------------------------------------

        mov     si, constBootIP + $1BE
find32: cmp     [si + 4], byte 06h      ; 0Bh = FAT32
        je      findOK                  ; Success!
        add     si, $10
        cmp     si, constBootIP + $1FE  ; Next entry
        jnz     find32

; ----------------------------------------------------------------------
; Print common error string at SI
; ----------------------------------------------------------------------

        mov     si, err1
panic:  lodsb
        and     al, al
@@:     je      @b
        mov     ah, 06h
        int     10h
        jmp     panic

err1    db "NoFAT16", 0
err2    db "Unknown", 0

; ----------------------------------------------------------------------
; Load Sector EAX
; ----------------------------------------------------------------------

geom:   ; Get CX:DX geometry

        ; Get sector [1..63]
        xor     edx, edx
        mov     eax, [paramLBA]
        mov     bl,  [paramCountSectors]
        and     ebx, $3F
        div     ebx
        inc     dx
        push    dx

        ; Get head [0..15 or 255]
        mov     bl,  [paramCountHeads]
        inc     bx
        xor     edx, edx
        div     ebx

        ; Compute geometry
        mov     dh, dl  ; Head
        pop     cx      ; Sector
        mov     ch, al  ; [7:0] Cylinder
        shl     ah, 6
        or      cl, ah  ; [9:8] Cylinder
        mov     dl, [paramDiskID]
        ret

        ; Load ONE sector into memory
ldsec:  call    geom
        mov     ax, $0201
        mov     bx, [paramBuffer]
        int     13h
        ret

; ----------------------------------------------------------------------
; Get FAT16 structure
; ----------------------------------------------------------------------

findOK:

        mov     [paramLBA], dword 2048      ; $10_000
        mov     [paramBuffer], word $7E00
brk
        call    ldsec
