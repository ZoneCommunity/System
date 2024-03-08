[BITS 16]
[ORG 0x7C00]

call start

start:
    ; to 32 bit
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
    
    ; Clear screen and make it blue
    mov eax, 0xB8000    ; VGA text buffer address
    mov ecx, 80*25      ; Number of characters on the screen
    mov edi, eax        ; Destination pointer
    xor eax, eax        ; ' ' character
    mov ah, 1Bh         ; Blue attribute
    rep stosw           ; Fill screen with spaces and blue attribute

    mov eax, 0xB8000    ; VGA text buffer address
    mov edi, eax        ; Destination pointer
    mov esi, msg        ; Source pointer (address of string)
    mov ecx, msg_len    ; String length
    cld                 ; Clear direction flag (forward direction)
    mov ah, 1Bh         ; Attribute byte (bright magenta on blue background)

    
    
copy_loop:
    lodsb               ; Load byte from string into AL, increment SI
    stosw               ; Store character and attribute into VGA text buffer, increment DI
    loop copy_loop      ; Repeat until ECX becomes zero

hang:
    jmp hang


msg db 'Hello, World! Wow you work amazing whatever', 0   ; Null-terminated string
msg_len equ $ - msg         ; Length of the string (excluding null terminator)


times 510-($-$$) db 0
dw 0xAA55