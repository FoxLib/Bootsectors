;
; УСТАНОВКА СИСТЕМНОГО ТАЙМЕРА НА 100 Гц
;

core.SetTimer100:

        mov   al, 0x34              ; 100Hz
        out   0x43, al
        mov   al, 0x9b              ; lsb    1193180 / 1193
        out   0x40, al
        mov   al, 0x2e              ; msb
        out   0x40, al
        ret
