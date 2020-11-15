
; ----------------------------------------------------------------------
; Установить указатель на директорию Root с текущего заданного диска
; По параметру [cs:dos.param.drive_letter] установить:
; 1. dos.param.current_fs
; 2. dos.param.current_dir
; ----------------------------------------------------------------------

dos.routines.SetRootCluster:
        
        pusha
        mov     [cs: dos.param.current_fs], word 0
        mov     dx, [cs: dos.param.drive_letter]
        and     dx, 0FFh

        mov     bx, dos.param.fs_block
        mov     cx, [cs: dos.param.num_fs_detected]

        ; DeviceID = BIOS Device DL
@@:     mov     ax, [fs: bx + fs.dw.device_id]
        cmp     ax, dx
        je      @f
        
        add     bx, 32
        inc     word [cs: dos.param.current_fs]        
        loop    @b

        ; Установить текущую директорию
        ; Если FAT12/16 - корневой кластер current_dir=1
        ; --> сигнал брать данные из RootEntries
@@:     mov     ax, [fs: bx + fs.dw.filetype]
        cmp     ax, 32
        mov     eax, [fs: bx + fs.dd.fat_root]
        je      @f
        xor     eax, eax
        inc     ax
        
        ; Сохранить номер кластера текущей директории    
@@:     mov     [cs: dos.param.current_dir], eax

        ; И базового смещения fs_block для получения информации о FAT
        mov     [cs: dos.param.current_fsblock], bx
        popa
        ret
        

