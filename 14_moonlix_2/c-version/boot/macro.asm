; "Волшебная" инструкция, останавливающая bochs
macro BRK {
    xchg bx, bx
}

macro BPBFAT12 {

    db 'MOONLIX '
    dw 512   ; Байт на сектор
    db 1     ; Секторов на кластер

    dw 0x1   ; Зарезервированных секторов (бутсектор = 1)
    db 2     ; Количество FAT
    dw 0xE0  ; Количество записей в корневой директории
    dw 2880  ; Количество секторов
    db 0xF8  ; Тип носителя (0xF0 - FDD) / F8 - HDD
    dw 9     ; Секторов на FAT

    dw 18    ; Секторов на Head
    dw 2     ; Heads на один цилиндр
    dd 0     ; Скрытые сектора
    dd 0     ; Всего логических секторов

    db 0     ; Физический номер драйва (BIOS INT 0x13)
    db 0     ; ReservedDRN (?)
    db 0x29  ; Расширенная сигнатура загрузчика | ExtendedBootSignature
    dd 0     ; VolumeIDSerialNumber (timestamp)

    db 'MOONLIX    ' ; Метка тома для секции | PartitionVolumeLabel
    db 'FAT12   '    ; Тип файловой системы
}

macro BPBFAT32 {

    db 'SYSLINUX'
    dw 512   ; Байт на сектор
    db 4     ; Секторов на кластер

    dw 0x20  ; Зарезервированных секторов (бутсектор = 1)
    db 2     ; Количество FAT
    dw 0x0   ; Количество записей в корневой директории
    dw 0     ; Количество секторов
    db 0xF8  ; Тип носителя (0xF0 - FDD) / F8 - HDD
    dw 0     ; Секторов на FAT

    dw 0x3F  ; Секторов на Head
    dw 0xFF  ; Heads на один цилиндр
    dd 0x1F80 ; Скрытые сектора
    dd 0xEEC080 ; Всего логических секторов

    db 0xEA     ; Физический номер драйва (BIOS INT 0x13)
    db 0x76     ; ReservedDRN (?)
    db 0x0      ; Расширенная сигнатура загрузчика | ExtendedBootSignature
    dd 0        ; VolumeIDSerialNumber (timestamp)

    db 0, 0x2, 0, 0, 0, 1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x80, 0x1, 0x29, 0x62, 0x23, 0xf4, 0xf
    db 'NO NAME    FAT32   ' ; Метка тома для секции | PartitionVolumeLabel ; Тип файловой системы
}

; В конце бут-сектора должна быть эта последовательность
macro BOOTSIGNATURE {

    times 7c00h + (512 - 2 - 2*3) - $ db 0

    dw 0; 0x02fe
    dw 0; 0x3eb2
    dw 0; 0x3718

    dw 0xAA55
}

; Отладочный код
macro DEBUGGING_BOOT {

    mov si, 0x7FFF    
    call dump_memory ; hex

    xor ax, ax
    int 0x16

    cmp al, '1' ; +1 сектор
    jne  @f

    mov dword [DAP + 8], 0
    inc byte [0x7FFF]
    jmp repeat_x

@@:
    
    inc dword [DAP + 8]
    jmp repeat_x

; --
dump_memory:

    ; Blue screen
    mov ax, 0xb800
    mov es, ax
    mov di, 0
    mov ax, 0x1700
    mov cx, 80*25
    rep stosw

    mov di, 0
    mov ah, 0x17
    mov ch, 25
.CH:
    mov cl, 16    
.CL:
    mov al, [si]
    and al, 0xf0
    shr al, 4
    cmp al, 10
    jc .x
    add al, 7
.x: add al, 0x30
    stosw

    mov al, [si]
    and al, 0xf    
    cmp al, 10
    jc .y
    add al, 7
.y: add al, 0x30
    stosw

    mov al, 0
    stosw

    inc si        
    dec cl
    jne .CL

    add di, 64
    dec ch
    jne .CH
    ret


}       