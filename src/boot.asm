; From: https://github.com/MrEmpy/SimpleASMKernel

%INCLUDE "src/disk/memory.asm"
[BITS 16]
[ORG BOOT]

call LoadSystem
jmp KERNELADDR

OEM_LABEL      db "SYSTEM"  ; OEM Label
BYTES_PER_SECTOR dw 512   ; Bytes per sector
SECTORS_PER_CLUSTER db 1  ; Sectors per cluster
RESERVED_SECTORS dw 1     ; Number of reserved sectors
NUM_FATS db 2             ; Number of FATs
ROOT_DIR_ENTRIES dw 224   ; Number of root directory entries (for FAT12/16)
TOTAL_SECTORS dw 2880     ; Total sectors in the filesystem (for FAT12)
MEDIA_TYPE db 0xF8        ; Media descriptor byte
SECTORS_PER_FAT dw 9      ; Sectors per FAT
SECTORS_PER_TRACK dw 18   ; Sectors per track
NUM_HEADS dw 2            ; Number of heads
HIDDEN_SECTORS dd 0       ; Number of hidden sectors before the partition
TOTAL_SECTORS_BIG dd 0    ; Total sectors if TOTAL_SECTORS is 0
DRIVE_NUMBER db 0x80      ; Drive number
EXTENDED_BOOT_SIGNATURE db 0x29 ; Extended boot signature
VOLUME_ID dd 0            ; Volume serial number
VOLUME_LABEL db "SYSTEM " ; Volume label
FILE_SYSTEM_TYPE db "FAT12" ; Filesystem type

%INCLUDE "src/disk/disk.asm"

LoadSystem:
    mov byte[sector], 2
    mov byte[drive], 80h
    mov byte[sectornum], 2
    mov word[segmentaddr], KERNELSEG ; kernel seg
    mov word[segmentoffset], KERNELOFFSET ; kernel offset
    call DiskRead

    ret


jmp $
times 510 - ($ - $$) db 0
dw 0xaa55