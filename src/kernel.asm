%INCLUDE "src/disk/memory.asm"
[BITS 16]
[ORG KERNELOFFSET]

section .bss
    buffer resb 255    ; Define a buffer to store input (maximum size 255 bytes)
    buffer_len resb 1  ; Variable to store the length of input

section .text

jmp Main

; Include external code
%INCLUDE "src/utils/print.asm"
%INCLUDE "src/utils/command.asm"

Main:
    call Segmen
    call Stack

    call cls
    
    mov si, welcome_sys
    call print

    mov si, welcome_sys2
    call println

    mov si, welcome_sys3
    call print

    mov si, info1
    call println

    call newln

    mov si, prompt_symb
    call println

    ; Begin typing loop
    call command

    mov si, haltedmsg
    call println

    jmp .hang

.hang:
    cli
    hlt
    jmp $

Stack:
    mov ax, 0x0200b
    mov ss, ax
    mov sp, 0x0300b
ret

Segmen:
    mov ax, es
    mov ds, ax
ret

welcome_sys db 'Welcome to System!', 0
welcome_sys2 db "I'm using println,", 0
welcome_sys3 db " and I'm using print!", 0

info1 db "Type 'help' for a list of commands.", 0

prompt_symb db "C:/>", 0
haltedmsg db 'System has halted!', 0