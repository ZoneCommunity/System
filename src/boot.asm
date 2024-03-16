%INCLUDE "src/disk/memory.asm"
[BITS 16]
[ORG BOOT]

call LoadSystem
jmp KERNELADDR

%INCLUDE "src/disk/disk.asm"

LoadSystem:
    mov byte[sector], 2      ; Start loading from sector 2
    mov byte[drive], 0x80   ; Drive 0x80 (typically the first hard drive)
    mov byte[sectornum], 40 ; Load 10 sectors
    mov word[segmentaddr], KERNELSEG ; kernel seg
    mov word[segmentoffset], KERNELOFFSET ; kernel offset
    call DiskRead

    ret

jmp $
times 510 - ($ - $$) db 0
dw 0xaa55
