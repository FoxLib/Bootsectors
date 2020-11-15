;
; Запуск программы
;
; AH        4bH
; DS:DX     адрес строки ASCIIZ с именем файла, содержащего программу
; ES:BX     адрес EPB (EXEC Parameter Block) -- не учитывается
; AL = 0    загрузить и выполнить
; AL = 3    загрузить программный оверлей -- не учитывается

dos.int21h.ExecFile:

        ; Открыть описатель файла (DS:DX)
        call    dos.int21h.OpenFile
        jb      .failed
        
        ; @TODO Получение размера файла, сверить, можно ли еще загрузить? 
        ; ....

        ; -------------------------------
        ; ЧТЕНИЕ COM-ФАЙЛА
        ; -------------------------------

        ; Читать файл в top_segment + 10h (PSP = 100h байт)
        mov     bx, [cs: dos.param.top_segment]
        mov     ds, bx
        mov     es, bx
        
        ; Очистка всего сегмента
        mov     cx, 8000h
        xor     ax, ax
        xor     di, di
        rep     stosw
        
        ; PSP 00h: INT 20h (CD20h)
        mov     [0], word 020CDh
        
        ; RET -> INT 20h
        mov     [0FFFEh], word 0
        
        ; PSP 02h: Сегмент, расположенный сразу после выделенной программе памяти
        mov     [2], bx
        
        ; Следующий адрес, куда будет прочтена программа
        add     bx, 1000h
        mov     [cs: dos.param.top_segment], bx

        ; PSP 16h: Сегмент PSP вызывающего процесса
        mov     ax, [cs: dos.param.psp_parent]
        mov     [16h], ax
        mov     [cs: dos.param.psp_parent], ds
        
        ; PSP 2Ch ENVIROMENT Segment
        mov     ax, [dos.param.env_seg]
        mov     [2Ch], ax
        
        ; PSP SS:SP Для возврата управления
        mov     ax, [cs: dos.int21h.sp]
        mov     [2Eh], ax
        mov     ax, [cs: dos.int21h.ss]
        mov     [30h], ax

        ; Загрузка COM/EXE-файла в память
        ; Максимальный объем COM: 65536 - 2 - 256
        mov     ax, word [cs: dos.int21h.eax]
        mov     word [cs: dos.int21h.ebx], ax
        mov     word [cs: dos.int21h.ecx], 0FEFEh
        mov     word [cs: dos.int21h.edx], 100h
        call    dos.int21h.ReadFile

        ; Закрыть файл
        call    dos.int21h.CloseFile
        
        ; Записать точку входа в стек последнего вызова
        mov     [cs: dos.exec.sp], sp
        mov     [cs: dos.exec.ss], ss
        
        mov     ax, ds
        mov     ss, ax
        xor     eax, eax
        xor     ebx, ebx
        xor     ecx, ecx
        xor     edx, edx
        xor     ebp, ebp
        xor     esi, esi
        xor     edi, edi

        ; Параметры окружения важны для демок
        mov     cx, 0FFh
        mov     dx, ds
        mov     si, 100h
        mov     sp, 0FFFEh
        mov     di, 0FFFEh
        mov     bp, 0900h

        ; Установить точку входа в программу DS:100h
        mov     [cs: .pem + 0], word 100h
        mov     [cs: .pem + 2], ds
        
        ; Включить прерывания
        sti
        
        ; jmp   far [cs: .pem]
        db      02Eh, 0FFh, 2Eh
        dw      .pem
.pem    dw      0, 0

; --------------
        
.failed:

        ret
