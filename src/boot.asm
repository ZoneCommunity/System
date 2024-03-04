; From: https://github.com/MrEmpy/SimpleASMKernel

%INCLUDE "src/disk/memory.asm"
[BITS 16]
[ORG BOOT]

call LoadSystem
jmp KERNELADDR

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
