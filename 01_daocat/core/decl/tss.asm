; Задача при загрузке имеет следующие сегменты
; - LDT 64kb
; - Свой код (32-х разрядный default size)
; - Стек 8kb 
; При загрузке код нечитаемый исполняемый. Каждый сегмент задачи имеет уровень DPL=3. GDT недоступно, только LDT.
; Все операции выполняются через вызов INT. Задача имеет строгую изоляцию памяти и может работать только с локально
; создаваемыми сегментами в LDT.

; Список полей TSS
TSS_LINK   EQU 0x00 ; word

TSS_ESP0   EQU 0x04 ; dword
TSS_SS0    EQU 0x08 ; word
TSS_ESP1   EQU 0x0C ; dword
TSS_SS1    EQU 0x10 ; word
TSS_ESP2   EQU 0x14 ; dword
TSS_SS2    EQU 0x18 ; word

TSS_CR3    EQU 0x1C ; dword
TSS_EIP    EQU 0x20 ; dword
TSS_EFLAGS EQU 0x24 ; dword
TSS_EAX    EQU 0x28 ; dword
TSS_ECX    EQU 0x2C ; dword
TSS_EDX    EQU 0x30 ; dword
TSS_EBX    EQU 0x34 ; dword
TSS_ESP    EQU 0x38 ; dword
TSS_EBP    EQU 0x3C ; dword
TSS_ESI    EQU 0x40 ; dword
TSS_EDI    EQU 0x44 ; dword

TSS_ES     EQU 0x48 ; word
TSS_CS     EQU 0x4C ; word
TSS_SS     EQU 0x50 ; word
TSS_DS     EQU 0x54 ; word
TSS_FS     EQU 0x58 ; word
TSS_GS     EQU 0x5C ; word
TSS_LDTR   EQU 0x60 ; word
TSS_T      EQU 0x64 ; T - нижний бит, бит трассировки
TSS_IOMAP  EQU 0x66 ; Карта портов ввода-вывода

; -----------------------------
TSS_TIMER_SHIFT  EQU 0x4000  ; Смещение в сегменте алиаса