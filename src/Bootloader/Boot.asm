; boot.asm

; ReDOS Bootloader v0.3 (fat12 impl)
[BITS 16]
[ORG 0x7C00]

jmp start
nop

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

    call cls
    mov si, boot_msg
    call print_string

    ; 4 Segments
    ; Reserved Segment: 1 Sector
    ; FAT: 9 * 2 = 18 Sectors
    ; Root Directory
    ; Data

    call LoadBin

    ;mov si, IMAGE_OFFSET
    ;call print_string

    mov dl, [bsDriveNumber]
    mov ax, kernel_load_segment
    mov ds, ax
    mov es, ax
    
    jmp kernel_load_segment:KERNEL_OFFSET

    jmp $


print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

cls:
    mov ax, 02
    int 0x10

    mov ah, 0x06
    mov bh, 0x0F
    mov ch, 00d
    mov cl, 00d
    mov dh, 24d
    mov dl, 79d
    int 10h

    mov ah, 0x02
    mov bh, 0x00
    mov dh, 0x00
    mov dl, 0x00
    int 10h

    ret

; INCLUDE
%INCLUDE "src/Kernel/LoadBin.asm"

; DEBUG
boot_msg db 'ReDOS Bootloader has loaded', 13, 10, 0

kernel_load_segment                 EQU 0x8000

ROOTDIRECTORY_AND_FAT_OFFSET        EQU 0x500
IMAGE_OFFSET                        EQU 0x1200
KERNEL_OFFSET                       EQU 0x0000
Sector                              DB 0x00
Head                                DB 0x00
Track                               DB 0x00
FileName                            DB "KERNEL  BIN"
FileReadError                       DB 'Failure', 0
Cluster                             DW 0x0000
DiskReadErrorMessage:               DB 'Disk read error...', 0
DataSectorBeginning:                DW 0x0000

times 510-($-$$) db 0
dw 0xAA55

buffer: