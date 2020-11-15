include 'names.asm'
include 'functions.asm'
include 'string_stream.asm'
include 'fetch_opcode.asm'
include 'print_modrm.asm'
include 'print_reg.asm'
include 'print_mnemonic.asm'
include 'print_operands.asm'
include 'fpu.asm'

; Дизассемблировать строку в fs:edi (2-й параметр)

; get_disassemble(uint32_t offset, uint32_t flat_addr)
; результат выполнения операции offset + <кол-во байт на инструкцию>
; -----------------------------------------------------------------------------
get_disassemble:

    push ebp
    mov  ebp, esp
    mov  esi, [ebp + 8] ; параметр "offset" (1)
    mov  edi, [ebp + 12]  ; куда писать строку 0x123800

    ; Что проинициализировано по умолчанию
    mov  [dreg32], byte 0 ; 0/1
    mov  [dmem32], byte 0 ; 0/1    
    
    ; Сканирование опкода с префиксами
    call fetch_opcode 

    ; Печать мнемоники
    call print_mnemonic

    ; Имеется ли ModRM? Если да - разобрать
    call print_operands
   
    ; Завершающий символ
    WSYMB 0

    mov  eax, esi 
    pop  ebp    
    ret