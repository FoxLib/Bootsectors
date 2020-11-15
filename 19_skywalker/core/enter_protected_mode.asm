
; ----------------------------------------------------------------------
; ФУНКЦИИ ИНИЦИАЛИЗАЦИИ ЗАЩИЩЕННОГО РЕЖИА
; ----------------------------------------------------------------------
        
        cli
        cld        

        ; Количество сегментов
        mov     word  [GLOBAL_DESCRIPTOR_TABLE.gdt + 0], (5*8) - 1                
        
        ; Начало GDT, линейный адрес
        mov     dword [GLOBAL_DESCRIPTOR_TABLE.gdt + 2], GLOBAL_DESCRIPTOR_TABLE  

        ; Загрузка GDT в регистр
        lgdt    [GLOBAL_DESCRIPTOR_TABLE.gdt]

        ; Количество элементов в IDT (256) 8*256-1 = 2047
        mov     word  [GLOBAL_DESCRIPTOR_TABLE.idt + 0], 0x7FF
        
        ; Начало IDT, линейный адрес
        mov     dword [GLOBAL_DESCRIPTOR_TABLE.idt + 2], 0             
        
        ; Загрузки прерываний
        lidt    [GLOBAL_DESCRIPTOR_TABLE.idt]
        
        ; Переход в Protected Mode        
        mov     eax, cr0
        or      al,  1
        mov     cr0, eax
        
        jmp     $0008 : protected_mode_entry

; ----------------------------------------------------------------------
; ГЛОБАЛЬНАЯ ТАБЛИЦА ДЕСКРИПТОРОВ (ОСНОВНАЯ)
; ----------------------------------------------------------------------

GLOBAL_DESCRIPTOR_TABLE: 
        
.null:  ; Пустой селектор (NULL)
        dd 0, 0        

.code:  ; 08h 4Гб, вся память, сегмент кода

        dw 0xffff              ; limit[15..0]
        dw 0                   ; addr[15..0]
        db 0                   ; addr[23..16]        
        db 80h + (10h + 8)     ; тип=8 (код для чтения) + 10h (s=1) + 80h (p=1), dpl = 0
        db 80h + 0xF + 40h     ; limit[23..16]=0x0f, G=1, D=1
        db 0                   ; addr[31..24]

.data:  ; 10h 4Гб, вся память, данные

        dw 0xffff
        dw 0
        db 0    
        db 80h + (10h + 2)     ; тип=2 (данные для чтения и записи) + 10h (s=1) + 80h (p=1), dpl = 0
        db 80h + 0xF + 40h     ; G=1, D=1, limit=0
        db 0

.tss:   ; 18h Дескриптор TSS

        dw 103                 ; размер TSS (104 байта)
        dw GENERAL_TSS         ; ссылка на TSS
        db 0
        db 80h + 9             ; 32-битный свободный TSS, P=1
        db 40h                 ; DPL=0, G=0, D=1 (32 битный)
        db 0 
        
.code16: ; 20h Сегмент 16-битного кода
   
        dw 0xffff              ; limit[15..0]
        dw 0                   ; addr[15..0]
        db 0                   ; addr[23..16]        
        db 80h + (10h + 8)     ; тип=8 (код для чтения) + 10h (s=1) + 80h (p=1), dpl = 0
        db 80h + 0xF           ; limit[23..16]=0x0f, G=1, D=0
        db 0                   ; addr[31..24]

.gdt:   dw 0,0,0               ; Указатель на GDT 
.idt:   dw 0,0,0               ; Указатель на IDT

; ------------------------------------------------------------
; ОСНОВНОЙ TASK SEGMENT STATE
; ------------------------------------------------------------

GENERAL_TSS: 

        dw 0, 0         ; 00 -- / LINK
        dd 0            ; 04 ESP0
        dw 0, 0         ; 08 -- / SS0
        dd 0            ; 0C ESP1
        dw 0, 0         ; 10 -- / SS1
        dd 0            ; 14 ESP2
        dw 0, 0         ; 18 -- / SS2
        dd 0            ; 1C CR3
        dd 0            ; 20 EIP
        dd 0            ; 24 EFLAGS
        dd 0            ; 28 EAX
        dd 0            ; 2C ECX
        dd 0            ; 30 EDX 
        dd 0            ; 34 EBX
        dd 0            ; 38 ESP
        dd 0            ; 3C EBP
        dd 0            ; 40 ESI
        dd 0            ; 44 EDI
        dw 0, 0         ; 48 -- / ES
        dw 0, 0         ; 4C -- / CS
        dw 0, 0         ; 50 -- / SS
        dw 0, 0         ; 54 -- / DS
        dw 0, 0         ; 58 -- / FS
        dw 0, 0         ; 5C -- / GS
        dw 0, 0         ; 60 -- / LDTR
        dw 104, 0       ; 64 IOPB offset / --
