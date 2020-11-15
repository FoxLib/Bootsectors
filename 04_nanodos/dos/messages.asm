dos.messages.welcome:

    db ":: NanoDOS 0.01 (32 bit) :: The Hobby Software :: 2017 Nov 29 ::", 10, 13, 0

; Для вывода информации о дисках
dos.io.msg_drv:     db '   Drive C: [$'
dos.io.msg_mb:      db ' MB',10,13,0
dos.io.msg_fat12:   db 'FAT12] $'
dos.io.msg_fat16:   db 'FAT16] $'
dos.io.msg_fat32:   db 'FAT32] $'

