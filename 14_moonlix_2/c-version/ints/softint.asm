; Базовые функции ядра
int_c0:
    
    pusha
    push ds es gs fs

    ; (ds = системная память) fs = общая память
    push dword 0x0010
    pop  ds

    push dword 0x0020
    pop  fs ; Восстановление системного сегмента (вся память)
            ; Для доступа к памяти 4 Мб (остальное решается через GS)

    push ss
    pop  es ; Для стековых операции в ядре   
 
    ; Сохранение контекста "задачи"
    ; То есть, симулируется "TSS"
    mov  ebp, esp

    ; EAX ECX EDX EBX ESP EBP ESI EDI
    ; DS  ES  GS  FS

    ; Первые параметры    
    mov eax, [ebp + 0x2C] ; = EAX
    mov ecx, [ebp + 0x28] 
    mov edx, [ebp + 0x24] 
    mov ebx, [ebp + 0x20] 
    mov [param_eax], eax
    mov [param_ebx], ebx
    mov [param_ecx], ecx
    mov [param_edx], edx

    mov eax, [ebp + 0x1C] ; = ESP
    mov ebx, [ebp + 0x18] ; = EBP
    mov ecx, [ebp + 0x14] ; = ESI
    mov edx, [ebp + 0x10] ; = EDI
    mov [param_esp], eax
    mov [param_ebp], ebx
    mov [param_esi], ecx
    mov [param_edi], edx

    ; Третьи параметры (сегменты)
    mov eax, [ebp + 0x0C] ; = DS
    mov ebx, [ebp + 0x08] ; = ES
    mov ecx, [ebp + 0x04] ; = GS
    mov edx, [ebp + 0x00] ; = FS

    mov [param_ds], eax
    mov [param_es], ebx
    mov [param_gs], ecx
    mov [param_fs], edx

    ; Для работы с локальной памятью
    mov gs, word [ebp + 0x00] ; сегмент fs 

    ; Вызов обработчика
    ; ----------

    call syscall_INTC0_dispather

    ; Запись изменений обратно
    mov eax, [param_eax]
    mov ebx, [param_ebx]
    mov ecx, [param_ecx]
    mov edx, [param_edx]    
    mov [ebp + 0x2C], eax
    mov [ebp + 0x28], ecx
    mov [ebp + 0x24], edx
    mov [ebp + 0x20], ebx

    mov eax, [param_esp]
    mov ebx, [param_ebp]
    mov ecx, [param_esi]
    mov edx, [param_edi]
    mov [ebp + 0x1C], eax
    mov [ebp + 0x18], ebx
    mov [ebp + 0x14], ecx
    mov [ebp + 0x10], edx

    pop fs gs es ds
    popa
    iret