command:
    
.readkeys:
    mov ah, 0x00  ;service 0h Read key press
    int 16h    ; Puts the pressed key into al 

    cmp al, 13 ; When enter key is pressed, go to command handler
    je .handler

    mov bx, [buffer_len]            ; Move buffer length to BX
    mov [buffer + bx], byte al      ; Store character in buffer at current buffer length
    inc byte [buffer_len]           ; Increment buffer length

    mov ah, 0x0e
    int 10h
    
    jmp .readkeys



.handler:
    ; Work around for when nothing is entered
    mov si, buffer
    mov cx, [buffer_len]
    mov [buffer_len], cl
    mov si, buffer
    mov cx, [buffer_len]
    mov di, cmd_none
    repe cmpsb
    je .fail

    mov si, buffer
    mov cx, [buffer_len]
    mov [buffer_len], cl
    mov si, buffer
    mov cx, [buffer_len]
    mov di, cmd_help
    repe cmpsb
    je .cmdhelp

    mov si, buffer
    mov cx, [buffer_len]
    mov [buffer_len], cl
    mov si, buffer
    mov cx, [buffer_len]
    mov di, cmd_ver
    repe cmpsb
    je .cmdver

    mov si, failure_cmd
    jmp .fail


.cmdhelp:
    mov si, cmdout_help_1
    call println
    mov si, cmdout_help_2
    call println
    mov si, cmdout_help_3
    call println
    call newln
    jmp .end

.cmdver:
    mov si, cmdout_ver
    call println
    call newln
    jmp .end

; end
.fail:
    mov si, failure_cmd
    call println
    call newln
    jmp .end
    
.end:
    ; Reset buffer
    mov di, buffer
    mov cx, 255
    mov al, 0              ; Fill buffer with zeros
    rep stosb              ; Store AL in buffer

    ; Reset buffer length
    mov byte [buffer_len], 0  ; Reset buffer length to 0

    mov si, prompt_symb
    call println
    
    jmp command

; Command inputs
cmd_help db 'help', 0
cmd_ver db 'ver', 0

; Command outputs
cmdout_help_1 db '---          Help menu          ---', 0
cmdout_help_2 db 'ver       > Displays System version', 0
cmdout_help_3 db 'help      > Shows help menu for CMD', 0

; OS getting too big, needs a proper bootloader and disk features

cmdout_ver db 'System version 0.0.1', 0

; --- fail ---
cmd_none db '', 0
failure_cmd db 'Invalid command or file name.', 0
