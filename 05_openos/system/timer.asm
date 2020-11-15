; Прошедшего времени в 1/100 секундах
timer   dd 0

; -----------------------------------
timer_tick:

        inc  [timer]
        test byte [timer],  0x3F ; ~1/2 секунды
        jne @f
        call cmos_read
@@:     ret

; http://wiki.osdev.org/CMOS#Getting_Current_Date_and_Time_from_RTC
; http://www.bioscentral.com/misc/cmosmap.htm (карта памяти CMOS)
; ---
; 00h        0        1 byte        RTC seconds.  Contains the seconds value of current time
; 01h        1        1 byte        RTC seconds alarm.  Contains the seconds value for the RTC alarm
; 02h        2        1 byte        RTC minutes.  Contains the minutes value of the current time
; 03h        3        1 byte        RTC minutes alarm.  Contains the minutes value for the RTC alarm
; 04h        4        1 byte        RTC hours.  Contains the hours value of the current time
; 05h        5        1 byte        RTC hours alarm.  Contains the hours value for the RTC alarm
; 06h        6        1 byte        RTC day of week.  Contains the current day of the week
; 07h        7        1 byte        RTC date day.  Contains day value of current date
; 08h        8        1 byte        RTC date month.  Contains the month value of current date
; 09h        9        1 byte        RTC date year.  Contains the year value of current date
; -----------------------------------
cmos_read:

        mov edi, const_CMOS
        mov ecx, 128
        mov ax, 0
@@:     mov al, ah
        out 0x70, al        
        in  al, 0x71
        stosb
        inc ah
        loop @b
