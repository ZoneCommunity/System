%INCLUDE "src/disk/memory.asm"
[BITS 16]
[ORG KERNELOFFSET]

section .bss
    buffer resb 100    ; Define a buffer to store input (maximum size 255 bytes)
    buffer_len resb 1  ; Variable to store the length of input
    
section .text

jmp Main

; Include external code
%INCLUDE "src/utils/print.asm"
%INCLUDE "src/utils/command.asm"
%INCLUDE "src/utils/setup.asm"

%INCLUDE "src/zonefs/zonefs.asm"


Main:
    call Segmen
    call Stack

    call cls
    
    mov si, welcome_sys
    call print
    mov si, sys_ver
    call print
    mov al, '!'
    int 10h

    mov si, info1
    call println

    call newln

    mov si, usera
    call println

    ; Get the username
    call username

    mov si, uname
    call println
    mov si, prompt_symb
    call print

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

welcome_sys db 'Welcome to System ', 0
sys_ver db "0.0.4", 0

usera db 'Enter your username: ', 0

info1 db "Type 'help' for a list of commands.", 0

prompt_symb db "@system# > ", 0
haltedmsg db 'System has halted!', 0

current_directory resb 255

uname resb 20
uname_len resb 1