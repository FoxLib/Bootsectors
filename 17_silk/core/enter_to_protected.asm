; **********************************************************************
; ОПИСАНИЕ МОДУЛЯ
; ---------------
; Этот модуль предназначен для входа в защищенный режим процессора
; Сегменты защищенного режима назначаются простые и базовые. После, GDT
; будет постепенно расширяться и уменьшаться, в зависимости от 
; количества запущенных процессов
; **********************************************************************

    ; Загрузим указатель GDT на те сегменты, что сверху прописаны (кода и данных)
    ; Здесь IDT менять не будем (не требуется для коротких операции)

    mov     word  [Global_Descriptor_Table.link + 0], (4*8) - 1                ; Количество элементов в GDT
    mov     dword [Global_Descriptor_Table.link + 2], Global_Descriptor_Table  ; Начало GDT, линейный адрес
    lgdt          [Global_Descriptor_Table.link]
    
    ; Установка нового указателя IDT    
    mov     word  [Interrupt_Descriptor_Table + 0], 0x7FF ; Количество элементов в IDT (256) 8*256-1 = 2047
    mov     dword [Interrupt_Descriptor_Table + 2], 0     ; Начало IDT, линейный адрес
    lidt          [Interrupt_Descriptor_Table]

    ; Установка особого бита PM=1
    mov     eax, cr0
    or      al,  1
    mov     cr0, eax
    
    ; Переход в PM
    jmp     DESCRIPTOR_CODE_RING0 : start_protected_mode

; ----------------------------------------------------------------------
; Инициализация глобальных дескрипторов
; ----------------------------------------------------------------------

Global_Descriptor_Table: 

; Пустой селектор (NULL)
.null:  
    dd 0, 0        

; 08h 4Гб, вся память, сегмент кода
.code:  

    dw 0xffff              ; limit[15..0]
    dw 0                   ; addr[15..0]
    db 0                   ; addr[23..16]        
    db 80h + (10h + 8)     ; тип=8 (код для чтения) + 10h (s=1) + 80h (p=1), dpl = 0
    db 80h + 0xF + 40h     ; limit[23..16]=0x0f, G=1, D=1
    db 0                   ; addr[31..24]

; 10h 4Гб, вся память, данные
.data:  

    dw 0xffff
    dw 0
    db 0    
    db 80h + (10h + 2)     ; тип=2 (данные для чтения и записи) + 10h (s=1) + 80h (p=1), dpl = 0
    db 80h + 0xF + 40h     ; G=1, D=1, limit=0
    db 0

; 18h Дескриптор TSS
.tss:   

    dw 103                      ; Размер TSS (Обычно 104 байта) 104-1
    dw Main_Task_Segment_State  ; Ссылка на TSS
    db 0
    db 80h + 9                  ; 32-битный свободный TSS, P=1
    db 40h                      ; DPL=0, G=0, D=1 (32 битный)
    db 0 

.link:  dw 0,0,0                ; Указатель на GDT              

; Указатель на IDT
; ----------------------------------------------------------------------
Interrupt_Descriptor_Table:

    dw 0,00

; ----------------------------------------------------------------------
; Основной TSS (Task Segment State)
; ----------------------------------------------------------------------

Main_Task_Segment_State: 

    dw 0, 0         ; 00 -- / LINK
    dd 0            ; 04      ESP0
    dw 0, 0         ; 08 -- / SS0
    dd 0            ; 0C      ESP1
    dw 0, 0         ; 10 -- / SS1
    dd 0            ; 14      ESP2
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
