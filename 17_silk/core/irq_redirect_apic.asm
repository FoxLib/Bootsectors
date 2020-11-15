
    ; http://ru.osdev.wikia.com/wiki/I/O_APIC
    ; http://ru.osdev.wikia.com/wiki/Local_APIC#LVT_Timer_Register
    
    MSR_APIC_BASE equ 0x1b
    mov ecx, MSR_APIC_BASE
    xor eax, eax
    xor ebx, ebx
    rdmsr
    test ah,8
    jnz apic_init_end
    bts eax,11		
    wrmsr
    
apic_init_end:
    and eax, 0xFFFFF000
    
    brk    
    
    mov eax, [eax + 0x30]
