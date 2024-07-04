; ReDOS 0.1 Bootloader
[BITS 16]
[ORG 0x7c00]

; Constants
KERNEL_SEGMENT equ 0x1000
KERNEL_OFFSET equ 0x0000
KERNEL_SECTORS equ 40

start:
    ; Set up segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov [boot_drive], dl

    call cls

    mov si, boot_msg
    call print_string

    ; Load kernel
    mov ax, KERNEL_SEGMENT
    mov es, ax
    xor bx, bx

    mov si, loading_msg
    call print_string

    mov ah, 0x02    ;  read sector function
    mov al, KERNEL_SECTORS  ; sectors to read
    mov ch, 0       ; cylinder number
    mov cl, 2       ; sector number (1 is boot sector)
    mov dh, 0       ; head number
    mov dl, [boot_drive]  ; drive number
    int 0x13        ; BIOS interrupt

    jc disk_error

    jmp KERNEL_SEGMENT:KERNEL_OFFSET

disk_error:
    mov si, error_msg
    call print_string
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

print_char:
    mov ah, 0x0E
    int 0x10
    ret

print_newline:
    mov al, 13
    call print_char
    mov al, 10
    call print_char
    ret

cls:
    mov ax, 02
    int 0x10

    mov ah, 0x06
    mov bh, 0x1F
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

boot_msg db 'ReDOS Bootloader has loaded', 13, 10, 0
loading_msg db 'Loading kernel...', 13, 10, 0
error_msg db 'Something went wrong while attempting to boot ReDOS.', 13, 10, 0
boot_drive db 0

times 510-($-$$) db 0
dw 0xAA55
