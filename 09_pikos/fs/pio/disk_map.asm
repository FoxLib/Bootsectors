;
; Определить разделы и доступные файловые системы на дисках
;

; DISK_DRIVES
; ----------------------------------------------------------------------
;
; struct DD (32 байта) {
;
;   word    fs_type = enum(0: none, 1: fat12, 2:fat16, 3:fat32)
;   word    cluster_size                секторов в кластере
;   dword   start_lba                   стартовый lba с данными о FS
;   dword   start_fat                   сектор начала fat
;   dword   start_data                  сектор начала data
;   dword   root_cluster                кластер с root-dir
;   word    disk_id                     номер диска (0..3)
;
; }

struct.dd.fs_type               equ 0
struct.dd.cluster_size          equ 2
struct.dd.start_lba             equ 4
struct.dd.start_fat             equ 8
struct.dd.start_data            equ 12
struct.dd.root_cluster          equ 16
struct.dd.disk_id               equ 20

fs.pio.Disks:       dw 0, 0, 0, 0       ; Перечислитель типов дисков на 4-х каналах IDE
fs.pio.DisksNumber: dw 0                ; Количество файловых систем

; Тест файловых систем
fs.pio.DiskMap:

        ; Определение физических носителей
        xor     eax, eax
        call    dev.pio.DriveDetection
        mov     [fs.pio.Disks + 0], ax

        mov     ax, 1
        call    dev.pio.DriveDetection
        mov     [fs.pio.Disks + 2], ax
        
        mov     ax, 2
        call    dev.pio.DriveDetection
        mov     [fs.pio.Disks + 4], ax
        
        mov     ax, 3
        call    dev.pio.DriveDetection
        mov     [fs.pio.Disks + 6], ax

        ret
