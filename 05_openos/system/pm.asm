
        ; Константы
        include "const.asm"
        include "struct.asm"
        
; ------------------------------------------------------
; ВХОД в защищенный режим 
; ------------------------------------------------------
enter_pm:

        cli

        ; Загрузим указатель GDT на те сегменты, что сверху прописаны (кода и данных)
        ; Здесь IDT менять не будем (не требуется для коротких операции)

        mov word  [pm_descriptor.gdt + 0], (4*8) - 1      ; Количество элементов в GDT
        mov dword [pm_descriptor.gdt + 2], pm_descriptor  ; Начало GDT, линейный адрес
        lgdt [pm_descriptor.gdt]

        ; Переход в Protected Mode        
        mov eax, cr0
        or  al,  1
        mov cr0, eax
        jmp 8 : start_operation_system
