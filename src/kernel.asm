%INCLUDE "src/disk/memory.asm"

[BITS 16]
[ORG KERNELOFFSET]

jmp to32bit

cool:

    jmp cool

to32bit:    
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

    ; clear screen and make it blue omg
    mov eax, 0xB8000   ; address of VGA text buffer
    mov ecx, 80*25     ; number of characters on the screen
    mov edi, eax       ; destination pointer
    xor eax, eax       ; ' ' character
    mov ah, 1Bh        ; blue attribute
    rep stosw          ; fill screen with spaces and blue attribute

    mov eax, 0xB8000   ; address of VGA text buffer
    mov edi, eax       ; destination pointer
    mov esi, msg       ; source pointer (address of string)
    mov ecx, msg_len   ; string length
    cld                ; clear direction flag (forward direction)
    mov ah, 1Bh        ; attribute byte (bright magenta on blue background)


copy_loop:
    lodsb              ; load byte from string into AL, increment SI
    stosw              ; store character and attribute into VGA text buffer, increment DI
    loop copy_loop     ; repeat until ECX becomes zero



hang:
    jmp hang

msg db 'Hello, World!', 0   ; null-terminated string
msg_len equ $ - msg           ; length of the string (excluding null terminator)