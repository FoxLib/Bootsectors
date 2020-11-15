ACPISDTHeader:                       ; struct ACPISDTHeader 

        dd 0x00000000                ; char Signature[4];
        dd 0x00000000                ; uint32_t Length;
        db 0                         ; uint8_t Revision;
        db 0                         ; uint8_t Checksum;
        db 'OEMID '                  ; char OEMID[6];
        dd 0x00000000                ; uint32_t OEMRevision;
        dd 0x00000000                ; uint32_t CreatorID;
        dd 0x00000000                ; uint32_t CreatorRevision;

; ACPI_FADT:
