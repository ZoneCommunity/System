
command:
    
.readkeys:
    mov ah, 0x00  ; Service 0h: Read key press
    int 16h       ; Put the pressed key into AL

    cmp al, 13    ; Check if Enter key is pressed
    je .handler   ; If Enter is pressed, go to command handler

    cmp al, 8     ; Check if Backspace key is pressed
    je .handle_backspace ; If Backspace is pressed, handle it separately

    cmp al, 0     ; Check for extended key codes
    jne .process_key

    mov ah, 0x00  ; Read the extended key code
    int 16h       ; Put the extended key code into AL

    jmp .readkeys

.process_key:
    mov bx, [buffer_len]       ; Move buffer length to BX
    mov [buffer + bx], byte al ; Store character in buffer at current buffer length
    inc byte [buffer_len]      ; Increment buffer length

    mov ah, 0x0e
    int 10h

    jmp .readkeys


.handle_backspace:
    mov bx, [buffer_len]       ; Move buffer length to BX
    cmp bx, 0                  ; Check if buffer is empty
    je .readkeys               ; If buffer is empty, just read keys again

    dec byte [buffer_len]      ; Decrement buffer length to remove last character
    mov ah, 0x0e
    mov al, 0x08               ; Move back
    int 10h
    mov al, ''                 ; Erase character
    int 10h
    mov al, 0x08               ; Move back again
    int 10h
    jmp .readkeys


.handler:
    mov si, buffer        ; Load the address of buffer into SI
    
    mov di, cmd_help     ; Load the address of cmd_echo into DI
    mov cx, 4            ; Set CX to 4 to compare the first 4 characters
    repe cmpsb           ; Compare the first 4 characters of buffer with cmd_echo
    je .cmdhelp          ; If equal, jump to .cmdecho

    mov si, buffer        ; Load the address of buffer into SI
    mov di, cmd_echo     ; Load the address of cmd_echo into DI
    mov cx, 5            ; Set CX to 4 to compare the first 4 characters
    repe cmpsb           ; Compare the first 4 characters of buffer with cmd_echo
    je .cmdecho          ; If equal, jump to .cmdecho

    mov si, buffer        ; Load the address of buffer into SI
    mov di, cmd_cls     ; Load the address of cmd_echo into DI
    mov cx, 3            ; Set CX to 4 to compare the first 4 characters
    repe cmpsb           ; Compare the first 4 characters of buffer with cmd_echo
    je .cmdcls          ; If equal, jump to .cmdecho

    mov si, buffer        ; Load the address of buffer into SI
    mov di, cmd_shutdown     ; Load the address of cmd_echo into DI
    mov cx, 8            ; Set CX to 4 to compare the first 4 characters
    repe cmpsb           ; Compare the first 4 characters of buffer with cmd_echo
    je .cmdshutdown          ; If equal, jump to .cmdecho

    mov si, failure_cmd
    jmp .fail

.cmdreboot:
    db 0x0ea
    dw 0x0000
    dw 0xffff

.cmdcls:
    call cls
    jmp .end

.cmdhelp:
    mov si, cmdout_help_1
    call println
    mov si, cmdout_help_2
    call println
    mov si, cmdout_help_3
    call println
    mov si, cmdout_help_5
    call println
    mov si, cmdout_help_6
    call println
    jmp .end

.cmdecho:
    mov si, buffer
    add si, 5
    call println
    jmp .end

.cmdhalt:
    ret

.cmdshutdown:
    mov si, buffer        ; Load the address of buffer into SI
    add si, 9
    mov di, cmd_extr     ; Load the address of cmd_echo into DI
    mov cx, 2            ; Set CX to 4 to compare the first 4 characters
    repe cmpsb           ; Compare the first 4 characters of buffer with cmd_echo
    je .cmdreboot          ; If equal, jump to .cmdecho

    mov ax, 5307h
    mov cx, 3
    mov bx, 1
    int 15h



; end
.fail:
    mov si, failure_cmd
    call println
    jmp .end
    
.end:
    ; Reset buffer
    mov di, buffer
    mov cx, 255
    mov al, 0              ; Fill buffer with zeros
    rep stosb              ; Store AL in buffer

    ; Reset buffer length
    mov byte [buffer_len], 0  ; Reset buffer length to 0

    call newln

    mov si, uname
    call println
    mov si, prompt_symb
    call print
    
    jmp command

loadtui:


; Command inputs
cmd_help db 'help', 0
cmd_echo db 'echo ', 0
cmd_cls db 'cls', 0
cmd_shutdown db 'shutdown', 0

cmd_extr db '-r', 0


; Command outputs
cmdout_help_1 db '--------           Help menu           --------', 0
cmdout_help_2 db 'help     > Displays the available commands.', 0
cmdout_help_3 db 'echo     > Repeats the entered text.', 0
cmdout_help_5 db 'cls      > Clears the screen.', 0
cmdout_help_6 db 'shutdown > Turns off your PC. Run -r to reboot.', 0

; OS getting too big, needs a proper bootloader and disk features

; --- fail ---
cmd_none db '', 0
failure_cmd db "Invalid command, type 'help' for commands.", 0
