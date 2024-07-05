[BITS 16]
[ORG 0x0000]

section .bss
    buffer resb 100
    buffer_len resb 1
    
section .text

jmp Main

; Include external code
%INCLUDE "src/utils/print.asm"
%INCLUDE "src/utils/command.asm"
%INCLUDE "src/utils/setup.asm"
%INCLUDE "src/fs/disk.asm"

Main:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    ; call cls
    
    call newln
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

    call run_me

    jmp hang

wow:
    ; Reset buffer
    mov di, buffer
    mov cx, 255
    mov al, 0              ; Fill buffer with zeros
    rep stosb              ; Store AL in buffer

    ; Reset buffer length
    mov byte [buffer_len], 0  ; Reset buffer length to 0

    mov si, uname
    call println
    mov si, prompt_symb
    call print

    ; Begin typing loop
    call command

    mov si, haltedmsg
    call println

    jmp hang

hang:
    cli
    hlt
    
    jmp $


welcome_sys db 'Welcome to System ', 0
sys_ver db "0.0.5", 0

usera db 'Enter your username: ', 0

info1 db "Type 'help' for a list of commands.", 0

prompt_symb db "@system# > ", 0
haltedmsg db 'System has halted!', 0

uname resb 20
uname_len resb 1