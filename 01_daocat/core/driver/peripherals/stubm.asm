;======================================================================================
; Call before writing to 60h/64h.
;======================================================================================
kybd_ctrl_in_empty:
   push rcx
   push rbx
   mov rbx,[k_ms_since_boot]
   add rbx,100
   clc
kybd_wait0:
   in al,64h
   test al,02h
   jz short kybd_wait0_done
   mov rcx,[k_ms_since_boot]
   cmp rcx,rbx
   jl short kybd_wait0
   stc
kybd_wait0_done:
   pop rbx
   pop rcx
   ret

;======================================================================================
; Call before reading from 60h.
;======================================================================================
kybd_ctrl_out_full:
   push rcx
   push rbx
   mov rbx,[k_ms_since_boot]
   add rbx,100
   clc
kybd_wait1:
   in al,64h
   test al,01h
   jnz short kybd_wait1_done
   mov rcx,[k_ms_since_boot]
   cmp rcx,rbx
   jl short kybd_wait1
   stc
kybd_wait1_done:
   pop rbx
   pop rcx
   ret

;======================================================================================
; Empty the 8042 output buffer.
;======================================================================================
kybd_wait_8042:
   push rcx
   push rbx
   xor rcx,rcx
   mov rbx,16                  ; 16bytes = maximum size of 8042 buffer.
flush8042:   
   in al,64h
   test al,01h
   jz short no_8042_data
   in al,60h
   inc rcx
   cmp rcx,rbx
   jle short flush8042
no_8042_data:
   pop rbx
   pop rcx
   ret

;======================================================================================
; Wait for keyboard controller or mouse to return ACK.
;======================================================================================
kybd_wait_ack:
   push rcx
   push rbx
   mov rbx,[k_ms_since_boot]
   add rbx,500
   clc
kybd_wait2:
   in al,60h
   cmp al,0fah
   je short kybd_wait2_done
   mov rcx,[k_ms_since_boot]
   cmp rcx,rbx
   jl short kybd_wait2
   stc
kybd_wait2_done:
   pop rbx
   pop rcx
   ret

;======================================================================================
; Wait for Keyboard/Mouse to send Reset 0aah,00h
;======================================================================================
kybd_wait_reset_ack:
   push rcx
   push rbx
   mov rbx,[k_ms_since_boot]         ; Current ms since boot.
   add rbx,500                     ; Maximum ms to wait.
   clc
kybd_wait3:
   in al,60h                     ; This should be 0aah BAT passed.
   cmp al,0aah
   je short reset_ackok
   cmp al,0fch
   je short reset_ack_fail
   mov rcx,[k_ms_since_boot]
   cmp rcx,rbx
   jl short kybd_wait3
reset_ack_fail:                     ; Device returned 0fch instead of 0aah or timeout.
   stc
reset_ackok:
   in al,60h                     ; Read in 00h (Device ID) too.
   pop rbx
   pop rcx
   ret

;======================================================================================
; Write to PS2 Device B (mouse).
; -> Command Byte in BL.
;======================================================================================
ps2_deviceB_write:
   call kybd_ctrl_in_empty
   mov al,0d4h
   out 64h,al
   call kybd_ctrl_in_empty
   mov al,bl
   out 60h,al   
   ret

;======================================================================================
; Return Device B ID
; -> BL is ID.
;======================================================================================
ps2_get_deviceB_id:
   mov bl,0f2h                     ; Get MouseID command.
   call ps2_deviceB_write
   call kybd_wait_ack
   call kybd_ctrl_out_full
   in al,60h                     ; Read MouseID byte.
   ret

;======================================================================================
; Sample Rate in BL
; (10,20,40,60,80,100,200)
;======================================================================================
ps2_deviceB_set_sample:
   push rbx
   mov bl,0f3h                     ; Set Packet Sample-Rate Command.
   call ps2_deviceB_write
   call kybd_wait_ack
   pop rbx
   call ps2_deviceB_write
   call kybd_wait_ack
   ret

;======================================================================================
; Resolution in BL
; (0=1pixel/mm,1=2pixel/mm,2=4pixel/mm,3=8pixel/mm)
;======================================================================================
ps2_deviceB_set_resolution:
   push rbx
   mov bl,0e8h                     ; Set Packet Sample-Rate Command.
   call ps2_deviceB_write
   call kybd_wait_ack
   pop rbx
   call ps2_deviceB_write
   call kybd_wait_ack
   ret

;======================================================================================
; Set PS/2 Device B (Mouse) Scaling 2:1
;======================================================================================
ps2_deviceB_set_scaling21:
   mov bl,0e7h
   call ps2_deviceB_write
   call kybd_wait_ack
   ret
   
;======================================================================================
; Set PS/2 Device B (Mouse) Scaling 1:1
;======================================================================================
ps2_deviceB_set_scaling11:
   mov bl,0e6h
   call ps2_deviceB_write
   call kybd_wait_ack
   ret

;======================================================================================
; Enable PS/2 Streaming Mode.
;======================================================================================
ps2_deviceB_set_streammode:
   call kybd_ctrl_in_empty
   mov bl,0eah                     ; Ensure stream mode is enabled.
   call ps2_deviceB_write
   call kybd_wait_ack
   ret
   
;======================================================================================
; Enable PS/2 Device B (Mouse).
;======================================================================================
ps2_deviceB_enable:
   mov bl,0f4h
   call ps2_deviceB_write
   call kybd_wait_ack
   ret

;======================================================================================
; Disable PS/2 Device B (Mouse).
;======================================================================================   
ps2_deviceB_disable:
   mov bl,0f5h
   call ps2_deviceB_write
   call kybd_wait_ack
   ret

;======================================================================================
; Enable Keyboard (Device A).
;======================================================================================
ps2_deviceA_enable:
   call kybd_ctrl_in_empty
   mov al,0aeh
   out 64h,al
   ret
   
;======================================================================================
; Disable Keyboard (Device A).
;======================================================================================
ps2_deviceA_disable:
   call kybd_ctrl_in_empty
   mov al,0adh
   out 64h,al
   ret

;======================================================================================
; Set active scancode set on device A.
;======================================================================================
ps2_deviceA_set_scancodeset:
   ret

;======================================================================================
; Set typematic rate/delay on device A.
;======================================================================================
ps2_deviceA_set_ratedelay:
   ret


;======================================================================================
; Set typematic rate/delay on device B (dual keyboard PS2).
;======================================================================================
ps2_deviceB_set_ratedelay:
   ret

;======================================================================================
; Set LED states on Device A - Keyboard.
; BH -> Input Keyboard LEDS 
; Bit 0: Scroll lock LED | Bit 1: Num lock LED | Bit 2: Caps lock LED
;======================================================================================
ps2_deviceA_set_leds:
   call kybd_ctrl_in_empty   
   mov al,0edh
   out 60h,al
   call kybd_ctrl_in_empty
   mov al,bh
   out 60h,al      
   ret

;======================================================================================
; Clear LED states on Device A - Keyboard.
;======================================================================================
ps2_deviceA_clear_leds:
   call kybd_ctrl_in_empty   
   mov al,0edh
   out 60h,al
   call kybd_ctrl_in_empty
   mov al,0
   out 60h,al
   call kybd_wait_ack
   ret
   
;======================================================================================
; Set LED states on Device B - (dual keyboard PS2).
;======================================================================================
ps2_deviceB_set_leds:
   ret

;======================================================================================
; Reset the PC via Keyboard Controller.
;======================================================================================
ps2_system_reset:
   mov bl,0d1h
   call kybd_ctrl_in_empty
   mov al,0d1h
   out 64h,al
   ; writes 11111110 to the output port (sets reset system line low)
   call kybd_ctrl_in_empty
   mov al,0feh
   out 60h,al
   ret
   
;======================================================================================
; Initialize the PS/2 Controller Interface and Attached Devices.
;======================================================================================
ps2_ctrl_init:

   ;--------------------------------------------------------
   ; Begin Initialization - Enable Aux Port and 
   ; Determine PS2 Controller Type.
   ;--------------------------------------------------------
   call kybd_wait_8042               ; Ensure we empty out the 8042 data port if it still has data in it.
   call kybd_ctrl_in_empty            ; Wait for keyboard controller to be ready to receive a command.
   mov al,0a8h                     ; Enable PS2 Aux Port and Mouse.
   out 64h,al
   call kybd_wait_ack
   call kybd_ctrl_in_empty            ; Wait for keyboard controller to be ready to receive a command.
   jnc short ps2_init00
   
   mov [ps2_init_failed],1            ; Timeout when trying to communicate with ps2 controller.
   ret
   
ps2_init00:
   mov al,020h                     ; Send command 20h (read configuration byte).
   out 64h,al
   call kybd_wait_ack
   call kybd_ctrl_out_full            ; Wait for the data to be ready.
   jnc short ps2_init01

   mov [ps2_init_failed],1            ; Timeout when trying to communicate with ps2 controller.
   ret

ps2_init01:   
   in al,60h                     ; read configuration byte (no ACK).
   
   call kybd_ctrl_in_empty            ; Wait for keyboard controller to be ready to receive a command.
   jnc short ps2_init02
   
   mov [ps2_init_failed],1            ; Timeout when trying to communicate with ps2 controller.
   ret
   
ps2_init02:
   mov al,060h                     ; Send command 60h (set configuration byte).
   out 64h,al
   call kybd_wait_ack
   call kybd_ctrl_in_empty
   jnc short ps2_init03
   
   mov [ps2_init_failed],1            ; Timeout when trying to communicate with ps2 controller.
   ret
   
ps2_init03:
   mov al,0                     ; New configuration byte (Enable PS/2 device A and B and no BAT flag).
   out 60h,al
   call kybd_ctrl_in_empty
   jnc short ps2_init04
   
   mov [ps2_init_failed],1            ; Timeout when trying to communicate with ps2 controller.
   ret
   
ps2_init04:
   mov al,0a7h                     ; Send command a7h (disable device B).
   out 64h,al
   call kybd_wait_ack
   call kybd_ctrl_in_empty            ; Wait for keyboard controller to be ready to receive a command.
   jnc short ps2_init05
   
   mov [ps2_init_failed],1            ; Timeout when trying to communicate with ps2 controller.
   ret
   
ps2_init05:
   mov al,020h                     ; Send command 20h (read configuration byte).
   out 64h,al
   call kybd_wait_ack
   call kybd_ctrl_out_full            ; Wait for the data to be ready.
   jnc short ps2_init06
   
   mov [ps2_init_failed],1            ; Timeout when trying to communicate with ps2 controller.
   ret
   
ps2_init06:
   in al,60h                     ; read configuration byte.
   test al,00100000b               ; Is Device B still Enabled?
   jnz short dual_ps2

   ;--------------------------------------------------------
   ; Single Port PS/2 Controller.
   ;--------------------------------------------------------
   mov [ps2_ctrl_type],0
   mov [ps2_deviceB_type],0         ; Since single port, device B must be none.
   mov [ps2_deviceB_use],0            ; Ensure Device B is marked as unusable.
   jmp short got_ps2_type
   
   ;--------------------------------------------------------
   ; Dual Port PS/2 Controller.
   ;--------------------------------------------------------
dual_ps2:
   mov [ps2_ctrl_type],1
   
   call kybd_ctrl_in_empty            ; Wait for keyboard controller to be ready to receive a command.
   jnc short ps2_init07
   
   mov [ps2_init_failed],1            ; Timeout when trying to communicate with ps2 controller.
   ret

ps2_init07:
   mov al,060h
   out 64h,al
   call kybd_wait_ack
   call kybd_ctrl_in_empty            ; Wait for keyboard controller to be ready to receive a command.
   jnc short ps2_init08
   
   mov [ps2_init_failed],1            ; Timeout when trying to communicate with ps2 controller.
   ret
   
ps2_init08:
   mov al,00110000b               ; disable ? Re-Enable both devices but leave IRQs off.
   out 60h,al
   call kybd_ctrl_in_empty
   jnc short ps2_dualdone

   mov [ps2_init_failed],1            ; Timeout when trying to communicate with ps2 controller.
   ret
   
ps2_dualdone:
   mov [ps2_deviceA_use],1            ; Ensure so-far that both devices are flagged usable.
   mov [ps2_deviceB_use],1
   
   ;--------------------------------------------------------
   ; We now know if the PS2 Controller is single/dual device
   ; -> Perform Interface tests on attached devices.
   ; -> From here it's safe to ignore the general
   ; -> PS2 timeouts as it should be in place.
   ; -> We'll ack. device specific timeouts now.
   ;--------------------------------------------------------
got_ps2_type:

   call kybd_ctrl_in_empty
   mov al,0f5h                     ; Disable scanning for device A (keyboard).
   out 60h,al
   call kybd_wait_ack

   ;--------------------------------------------------------
   ; Perform Interface Test on Device A.
   ;--------------------------------------------------------
   call kybd_ctrl_in_empty
   mov al,0abh                     ; Device A Interface Test command.
   out 64h,al
   call kybd_wait_ack
   call kybd_ctrl_out_full
   in al,60h

   mov [ps2_deviceA_res],al
   mov al,[ps2_deviceA_res]
   test al,al
   jz short devA_int_ok
   mov [ps2_deviceA_use],0            ; Device A Interface Test failed, mark device unusable.
   jmp test_devB
devA_int_ok:

   ;--------------------------------------------------------
   ; Perform Reset of Device A.
   ;--------------------------------------------------------
reset_devA:
   call kybd_ctrl_in_empty
   mov al,0ffh                     ; Reset device A command.
   out 60h,al
   call kybd_wait_reset_ack         ; Keyboard might not ACK reset, so wait for 0aah instead.
   jnc short deDevA

   mov [ps2_deviceA_type],0         ; ACK from Device A failed, mark it as unusable for now.
   mov [ps2_deviceA_use],0

   ;--------------------------------------------------------
   ; Disable Scanning on Device A again.
   ; -> Only if device responded to reset (use=1).
   ;--------------------------------------------------------
deDevA:
   cmp [ps2_deviceA_use],1
   jne short test_devB         
   call kybd_ctrl_in_empty
   mov al,0f5h                     ; Disable scanning for device A (keyboard).
   out 60h,al
   call kybd_wait_ack
   jnc short test_devB
   
   mov [ps2_deviceA_use],0            ; Disable Device A scanning failed, mark as unusable.
   
   ;--------------------------------------------------------
   ; Perform Interface Test on Device B.
   ;--------------------------------------------------------
test_devB:
   cmp [ps2_deviceB_use],0
   je no_disable_devB               ; No Device B so skip.

   call kybd_ctrl_in_empty            ; Disable packet sending (mouse) / disable device B.
   mov al,0d4h
   out 64h,al
   call kybd_ctrl_in_empty
   mov al,0f5h
   out 60h,al
   call kybd_wait_ack

   call kybd_ctrl_in_empty
   mov al,0a9h                     ; Test Mouse Port (Device B) command.
   out 64h,al
   call kybd_wait_ack
   call kybd_ctrl_out_full
   in al,60h

   mov [ps2_deviceB_res],al
   mov al,[ps2_deviceB_res]
   test al,al
   jz short no_disable_devB
   mov [ps2_deviceB_use],0            ; Device B Interface Test failed, mark device unsuable. 
   jmp no_devB_reset
   
   ;--------------------------------------------------------
   ; Perform Reset of Device B if present.
   ;--------------------------------------------------------
   call kybd_ctrl_in_empty
   mov al,0d4h
   out 64h,al
   call kybd_ctrl_in_empty
   mov al,0ffh
   out 60h,al   
   call kybd_wait_reset_ack         ; Reset Command might not ACK, rather wait for 0aah.
   jnc short no_disable_devB
   
   mov [ps2_deviceB_use],0            ; Reset of Device A failed, so mark it not usable.
   mov [ps2_deviceB_type],0

no_disable_devB:
no_devB_reset:
   
   ;--------------------------------------------------------
   ; Disable Scanning on Device B again.
   ; -> Only if device responded to reset (use=1).
   ;--------------------------------------------------------
no_descanA:
   cmp [ps2_deviceB_use],1
   jne short no_descanB
   call kybd_ctrl_in_empty            ; Disable packet sending (mouse) / disable device B.
   mov al,0d4h
   out 64h,al
   call kybd_ctrl_in_empty
   mov al,0f5h
   out 60h,al
   call kybd_wait_ack
   jnc short no_descanB
   
   mov [ps2_deviceB_use],0            ; Disable Device B scanning failed, mark as unusable.
   
   ;--------------------------------------------------------
   ; Identify Device A if it's still usable.
   ;--------------------------------------------------------
no_descanB:
   cmp [ps2_deviceA_use],1
   jne short identifyB               ; Only identify device A if still present and usable.
   
   call kybd_ctrl_in_empty
   mov al,0f2h                     ; Send the get keyboard ID command to encoder.
   out 60h,al
     
     mov rdi,offset ps2_deviceA_type
     mov dword [rdi],0               ; Ensure device type is 0.
     call kybd_wait_ack               ; Wait for the ACK byte 0fah.
     jnc short ps2_idA00
     
   mov [ps2_deviceA_type],0         ; ACK from Device A failed, mark it as unusable for now.
   mov [ps2_deviceA_use],0
   jmp short identifyB               ; Go on to Device B identification.
   
ps2_idA00:
     mov [rdi+0],al                  ; byte 0 = 0fah.
     call kybd_ctrl_out_full
     jc short identifyB               ; If this happens ID was only 1 byte.
     in al,60h
     cmp al,0fah
     je short ps2_idA00               ; Sometimes we get a double ACK? so ignore it..
   mov [rdi+1],al                  ; byte 1 = ?
     call kybd_ctrl_out_full
     jc short identifyB               ; ID was 2 bytes long.
   in al,60h
     mov [rdi+2],al                  ; byte 2 = ?
     call kybd_ctrl_out_full
     jc short identifyB               ; ID was 3 bytes long.
     in al,60h
     mov [rdi+3],al                  ; byte 3 = ? (shouldn't happen as ids are 3 bytes or less).
     
   ;--------------------------------------------------------
   ; Identify Device B if it's still usable.
   ;--------------------------------------------------------
identifyB:
   cmp [ps2_deviceB_use],1
   jne short no_devB_identify         ; No device B present or responding so skip identify.
   
   call kybd_ctrl_in_empty
   mov al,0d4h
   out 64h,al
   call kybd_ctrl_in_empty
   mov al,0f2h                     ; Send Get Mouse ID / identify command.
   out 60h,al
   
   mov rdi,offset ps2_deviceB_type
   mov dword [rdi],0
   call kybd_wait_ack               ; Wait for the ACK byte 0fah.
   jnc short ps2_idB00
   
   mov [ps2_deviceB_type],0         ; ACK from Device B failed, mark it as unusable for now.
   mov [ps2_deviceB_use],0
   jmp short no_devB_identify         ; Identify Device B Failed.

ps2_idB00:
   mov [rdi+0],al                  ; byte 0 = 0fah.
     call kybd_ctrl_out_full
     jc short no_devB_identify         ; If this happens ID was only 1 byte.
   in al,60h
   cmp al,0fah
     je short ps2_idB00               ; Sometimes we get a double ACK? so ignore it..
   mov [rdi+1],al                  ; byte 1 = ?
     call kybd_ctrl_out_full
     jc short no_devB_identify         ; ID was 2 bytes long.
     in al,60h
     mov [rdi+2],al                  ; byte 2 = ?
     call kybd_ctrl_out_full
     jc short no_devB_identify         ; ID was 3 bytes long.
     in al,60h
     mov [rdi+3],al                  ; byte 3 = ? (shouldn't happen as ids are 3 bytes or less).

   ;--------------------------------------------------------
   ; If Device B is a PS2 Mouse and
   ; it's ID = 0, perform mouse specific init sequence
   ; to determin enhanced type (wheel, 5 button).
   ;--------------------------------------------------------
no_devB_identify:
   cmp [ps2_deviceB_use],1            ; No Device B so skip.
   jne short ps2_done

   cmp [ps2_deviceB_type],000000fah   ; Mouse ID reported seems to be correct, no need to determine enhanced state (Could've been inited by another pc on kvm?).
   jne short ps2_done

   mov bl,200
   call ps2_deviceB_set_sample
   mov bl,100
   call ps2_deviceB_set_sample
   mov bl,80
   call ps2_deviceB_set_sample
   call ps2_get_deviceB_id
   cmp al,3
   jne short ps2_done               ; ID remained 0 so we've got a std. PS/2 mouse.
   
   mov [ps2_deviceB_packet],4         ; Update the packet size as we know we have at least a scroll wheel.
   mov rdi,offset ps2_deviceB_type
   mov [rdi+1],al                  ; Store the updated ID byte.
   
   mov bl,200
   call ps2_deviceB_set_sample
   mov bl,200
   call ps2_deviceB_set_sample
   mov bl,80
   call ps2_deviceB_set_sample
   call ps2_get_deviceB_id
   cmp al,4
   jne short ps2_done               ; ID remained 3 so we've got a PS/2 mouse with scroll wheel.

   mov [ps2_deviceB_packet],4         ; Update the packet size as we know we have a scroll wheel + 5 buttons.
   mov rdi,offset ps2_deviceB_type
   mov [rdi+1],al                  ; Store the updated ID byte.
   
ps2_done:
   cli
   MONITOR_WRITE_BYTE [ps2_init_failed],00ff0000h
   MONITOR_WRITE_BYTE [ps2_ctrl_type],00ffff00h
   MONITOR_WRITE_DWORD [ps2_deviceA_type],00f0ff00h
   MONITOR_WRITE_DWORD [ps2_deviceB_type],00ff00f0h
   MONITOR_WRITE_BYTE [ps2_deviceA_res],00ffff0fh
   MONITOR_WRITE_BYTE [ps2_deviceB_res],00fffff0h
   MONITOR_WRITE_BYTE [ps2_deviceA_use],00ffff00h
   MONITOR_WRITE_BYTE [ps2_deviceB_use],00ffff00h
   ret

;######################################################################################
; PS/2 Controller Driver Data / Variables.
;######################################################################################

   ; Possible Identification ID's returned.
   ;0xFA               AT keyboard with translation (not possible for device B)
     ;0xFA, 0xAB, 0x41   MF2 keyboard with translation (not possible for device B)
     ;0xFA, 0xAB, 0xC1   MF2 keyboard with translation (not possible for device B)
     ;0xFA, 0xAB, 0x83   MF2 keyboard without translation
     ;0xFA, 0x00         Standard mouse
     ;0xFA, 0x03         Mouse with a scroll wheel
     ;0xFA, 0x04         5 button mouse with a scroll wheel
   ;0xFA, 0x08         Typhoon 6byte packet mouse
   
ps2_init_failed    db 0               ; [ 0 = ps2 controller is ready, 1 = ps2 controller init failed ]
ps2_ctrl_type      db 0               ; [ 0 = single port, 1 = dual port ]
ps2_deviceA_type   dd 0               ; [ 0 = none, else use table above ]
ps2_deviceB_type   dd 0               ; [ 0 = none, else use table above ]
ps2_deviceA_res    db 0               ; [ Result Byte from device A interface test (0=ok) all else = h/w failure ]
ps2_deviceB_res    db 0               ; [ Result Byte from device B interface test (0=ok) all else = h/w failure ]
ps2_deviceA_use    db 1               ; [ 0 = Not usable, 1 = usable ]
ps2_deviceB_use    db 1               ; [ 0 = Not usable, 1 = usable ]
ps2_deviceA_packet dd 1               ; [ Size in bytes of Device A packet ]
ps2_deviceB_packet dd 3               ; [ Size in bytes of Device B packet ]