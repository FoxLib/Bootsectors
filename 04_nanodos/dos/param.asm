
; BIOS-инициализированная область
dos.param.drive_letter:

    db 0
    
; Номер текущей заданной файловой системы (0=C,1=D,...) По умолчанию C:
dos.param.current_fs:

    dw 0

dos.param.dir               dd 0        ; Главный текущий катало DOS
dos.param.current_dir       dd 0        ; Номер кластера (FAT32) текущей директории (если 1, значит FAT12/16)
dos.param.current_fsblock   dw 0        ; Текущий fs_block 
dos.param.top_segment       dw dos.param.segment_start ; Сегмент, куда можно загружать новые программы
dos.param.psp_parent        dw 0FFFFh   ; Родительский сегмент PSP
dos.param.env_seg           dw 0        ; Сегмент переменных сред

; Перечисление устройств жестких дисков / cdrom из BIOS
; 80h - обычно первое запускное устройство
dos.param.drives:

    db 0, 0, 0, 0
    db 0, 0, 0, 0

; Количество обнаруженных файловых систем
dos.param.num_fs_detected dw 0
    
; Последний открытый File Handler (максимальная вершина)
dos.param.file_id dw 0

; ----------------------------------------------------------------------
; НЕИНИЦИАЛИЗИРОВАННАЯ СЕКЦИЯ    
; ----------------------------------------------------------------------

; Буфер для Decimal-чисел
util.itoa.buffer: 

    ;  0 1 2 3 4 5 6 7 8 9 A
    db ?,?,?,?,?,?,?,?,?,?,?
    
; Нормализованное имя файла
dos.filename:

    db ?,?,?,?,?,?,?,?,?,?,?

; Своего рода TSS
dos.int21h.eax      dd ?
dos.int21h.ebx      dd ?
dos.int21h.ecx      dd ?
dos.int21h.edx      dd ?
dos.int21h.esi      dd ?
dos.int21h.edi      dd ?
dos.int21h.ebp      dd ?
dos.int21h.ss       dw ?
dos.int21h.fs       dw ?
dos.int21h.sp       dw ?
dos.int21h.flags    dw ?

; Точка последнего вызова
dos.exec.sp         dw ?
dos.exec.ss         dw ?
