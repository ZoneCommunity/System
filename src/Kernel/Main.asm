; main.asm

[BITS 16]
[ORG 0x0000]

jmp start

start:
    ; DS and ES register
    xor ax, ax
    mov ds, ax
    mov es, ax
    ; Stack
    mov ax, 0x7000
    mov ss, ax
    mov bp, 0x8000
    mov sp, bp

    mov ah, 0x0e
    mov al, 'X'
    int 10h

    call LoadRootDirectory

    mov si, IMAGE_OFFSET
    call println

    cli
    hlt

; %INCLUDE "src/Kernel/LoadBin.asm"
%INCLUDE "src/Kernel/Disk.asm"
%INCLUDE "src/Kernel/Print.asm"


bpbOEM:                  DB  "REDOS0.3"
bpbBytesPerSector:       DW  512
bpbSectorsPerCluster:    DB  1
bpbReservedSectors:      DW  1
bpbNumberOfFATs:         DB  2
bpbRootEntries:          DW  0E0h
bpbTotalSectors:         DW  2880
bpbMedia:                DB  0F0h
bpbSectorsPerFAT:        DW  9
bpbSectorsPerTrack:      DW  18
bpbHeadsPerCylinder:     DW  2
bpbHiddenSectors:        DD  0
bpbTotalSectorsBig:      DD  0

bsDriveNumber:           DB  0
bsUnused:                DB  0
bsExtBootSignature:      DB  29h
bsSerialNumber:          DB  12h, 34h, 56h, 78h
bsVolumeLabel:           DB  'ReDOS      '
bsFileSystem:            DB  'FAT12   '


kernel_load_segment                 EQU 0x8000

ROOTDIRECTORY_AND_FAT_OFFSET        EQU 0x500
IMAGE_OFFSET                        EQU 0x1200
KERNEL_OFFSET                       EQU 0x0000
Sector                              DB 0x00
Head                                DB 0x00
Track                               DB 0x00
FileName                            DB "TEST    TXT"
FileReadError                       DB 'Failure', 0
Cluster                             DW 0x0000
DiskReadErrorMessage:               DB 'Disk read error...', 0
DataSectorBeginning:                DW 0x0000
