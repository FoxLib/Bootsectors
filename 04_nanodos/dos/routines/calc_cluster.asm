;
; По заданному кластеру EAX расчитывается его стартовая позиция
; eax - номер сектора
; ecx - секторов на кластер

dos.routines.CalcCluster:

        push    bx
        
        ; Текущий блок информации о ФС
        mov     bx, [cs: dos.param.current_fsblock]
        
        ; Расчитывается позиция сектора
        sub     eax, 2
        movzx   ecx, word [fs: bx + fs.dw.cluster_size]
        mul     ecx
        add     eax, [fs: bx + fs.dd.start_data]
        pop     bx
        ret
