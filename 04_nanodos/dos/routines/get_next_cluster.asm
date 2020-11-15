;
; Найти следующий кластер
;
; eax - первый
; eax - следующий (если 0 - значит, все)

dos.routines.GetNextCluster:

        push    bx di ecx edx    
        mov     bx, [cs: dos.param.current_fsblock] 
        cmp     [fs: bx + fs.dw.filetype], byte 20h
        je      .fat32
        
        ; @todo ....
        
        jmp     .done
        
.fat32:
        
        ; Расчет сектора FAT
        mov     ecx, 128
        cdq
        idiv    ecx
        mov     di, dx
        add     eax, [fs: bx + fs.dd.start_fat]
        
        ; Читать сектор FAT
        call    dev.DiskReadA
        
        shl     di, 2
        mov     eax, [fs: dos.param.tmp_sector + di]
        
        ; Если =0, то кластер является последним
        cmp     eax, 0x0FFFFFF0
        jb      .done
        xor     eax, eax

.done:

        pop     edx ecx di bx
        ret
