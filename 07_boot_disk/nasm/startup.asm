[BITS 32]

[EXTERN main]
[GLOBAL _start]
[GLOBAL apic_disable]
[GLOBAL out8]
[GLOBAL in8]

; ----------------------------------------------------------------------
_start:

        mov     esp, 0xA0000
        jmp     main

; Отключение локального APIC
; ----------------------------------------------------------------------
apic_disable:

        mov ecx, 0x1b
        rdmsr
        and eax, 0xfffff7ff
        wrmsr
        ret
        
; ----------------------------------------------------------------------
; Запрос идет, используя стек вызова

out8:   

        push    ebp
        mov     ebp, esp
        push    edx 
        push    eax        
        mov     dx, [ebp + 8]
        mov     al, [ebp + 12]
        out     dx, al        
        pop     eax
        pop     edx
        pop     ebp
        ret
        
; ----------------------------------------------------------------------
; Результат в EAX

in8:    

        push    ebp
        mov     ebp, esp 
        push    eax        
        mov     dx, [ebp + 8]
        in      al, dx 
        and     eax, 0xFF 
        pop     eax
        pop     ebp
        ret
