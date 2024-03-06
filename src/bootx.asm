%INCLUDE "src/disk/memory.asm"

[BITS 16]
[ORG 0x7C00]

call start

%INCLUDE "src/disk/disk.asm"

start:
    ; to 32 bit

    mov byte[sector], 2
    mov byte[drive], 80h
    mov byte[sectornum], 2
    mov word[segmentaddr], KERNELSEG ; kernel seg
    mov word[segmentoffset], KERNELOFFSET ; kernel offset
    call DiskRead
    
    cli                 ; disable interrupts
    lgdt [gdt_desc]     ; load GDT descriptor
    mov eax, cr0
    or eax, 1           ; set protection enable bit
    mov cr0, eax
    jmp 08h:PModeMain   ; Jump to 32-bit code

gdt:
    gdt_null:
        dd 0
        dd 0

    gdt_code:
        dw 0FFFFh
        dw 0
        db 0
        db 10011010b
        db 11001111b
        db 0

    gdt_data:
        dw 0FFFFh
        dw 0
        db 0
        db 10010010b
        db 11001111b
        db 0

gdt_end:
gdt_desc:
    dw gdt_end - gdt - 1
    dd gdt

[BITS 32]
PModeMain:
    ; data segment registers
    mov ax, 10h
    mov ds, ax
    mov ss, ax
    mov esp, 0x90000   ; stack pointer
    
    jmp KERNELADDR
    
hang:
    jmp hang


times 510-($-$$) db 0
dw 0xAA55