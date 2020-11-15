[BITS 32]

[EXTERN main]
[EXTERN kernel_pic_keyb]
[EXTERN handler_page_fault]

[GLOBAL _start]
[GLOBAL apic_disable]
[GLOBAL interrupt_null]
[GLOBAL interrupt_keyb]

[GLOBAL exception_page_fault]
[GLOBAL exception_GP_fault]

[GLOBAL service_interrupt_40h]
[GLOBAL app_exec]

; ----------------------------------------------------------------------
_start:

        mov     esp, 0xA0000
        jmp     main

; Отключение локального APIC
; ----------------------------------------------------------------------
apic_disable:

        mov     ecx, 0x1b
        rdmsr
        and     eax, 0xfffff7ff
        wrmsr
        ret

; ----------------------------------------------------------------------
; Исполнение кванта времени процесса
; http://wiki.osdev.org/Task_State_Segment
; http://wiki.osdev.org/Getting_to_Ring_3#Entering_Ring_3

app_exec:

        push    ebp
        lea     ebp, [esp + 4]
        mov     edx, [ebp + 4]      ; Локальный TSS

        ; LocalTSS.EIP
        mov     eax, [edx + 20h]
        mov     [ebp + 4], eax

        ; Запись в TSS [SS0 : ESP0]
        mov     eax, 800h
        mov     ebx, ebp
        mov     [eax + 4], ebx
        mov     [eax + 8], ss

        ; CR3.MAP
        mov     eax, [ebp + 8]
        mov     cr3, eax

        ; Назначим сегменты
        mov     eax, 30h + 3
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax

        mov     ebx, [edx + 0x14]   ; Local.TSS.ESP3
        push    eax                 ; Пользовательский Data Segment (RPL=3)
        push    ebx                 ; Пользовательский Stack Segment

        ; flags : cs : eip
        pushfd
        pop     eax
        or      ax, 200h            ; IF=1
        push    eax        
        push    38h + 3
        push    dword [ebp + 4]

        ; Очистить регистры перед входом в приложение
        xor     eax, eax
        xor     ebx, ebx
        xor     ecx, ecx
        xor     edx, edx
        xor     esi, esi
        xor     edi, edi
        xor     ebp, ebp

        iretd

; (возврата пока сюда нет)

; ----------------------------------------------------------------------
; ПРЕРЫВАНИЯ

interrupt_null:

        xchg    bx, bx
        iretd

; Обработчик клавиатуры
interrupt_keyb:

        pushad
        call    kernel_pic_keyb
        mov     al, 20h
        out     20h, al
        popad
        iretd

; ----------------------------------------------------------------------
; Обработчик 0E Page Fault

exception_page_fault:

        pushad

        mov     eax, cr2
        mov     ebp, esp
        
        push    ebp                     ; stack
        push    dword [ebp + 8*4]       ; code_id
        push    eax                     ; address
        
        call    handler_page_fault
        mov     esp, ebp

        popad
        add     esp, 4
        iret

; ----------------------------------------------------------------------
; Обработчик 0D General Protection

exception_GP_fault:

        xchg    bx, bx
        
        ; !!
        iret

; ----------------------------------------------------------------------
; Обработчик сервисного прерывания INT 40h

service_interrupt_40h:

        xchg bx, bx
        pushad
        


        popad
        ret

