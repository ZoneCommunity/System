%INCLUDE "src/disk/disk.asm"
%INCLUDE "src/disk/memory.asm"

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

    mov si, buffer
    mov cx, [buffer_len]
    mov [buffer_len], cl
    mov si, buffer
    mov cx, [buffer_len]
    mov di, cmd_halt
    repe cmpsb
    je .cmdhalt

    mov si, buffer
    mov cx, [buffer_len]
    mov [buffer_len], cl
    mov si, buffer
    mov cx, [buffer_len]
    mov di, cmd_shutdown
    repe cmpsb
    je .cmdshutdown

    mov si, buffer
    mov cx, [buffer_len]
    mov [buffer_len], cl
    mov si, buffer
    mov cx, [buffer_len]
    mov di, cmd_tui
    repe cmpsb
    je .cmdtui

    mov si, failure_cmd
    jmp .fail


.cmdhelp:
    mov si, cmdout_help_1
    call println
    mov si, cmdout_help_2
    call println
    mov si, cmdout_help_3
    call println
    mov si, cmdout_help_4
    call println
    mov si, cmdout_help_5
    call println
    mov si, cmdout_help_6
    call println
    call newln
    jmp .end

.cmdver:
    mov si, cmdout_ver
    call println
    mov si, sys_ver
    call print
    call newln
    jmp .end

.cmdhalt:
    call newln
    ret

.cmdshutdown:
    mov ax, 5307h
    mov cx, 3
    mov bx, 1
    int 15h

.cmdtui:
    call loadtui
    jmp TUIADDR

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

loadtui:
    mov byte[sector], 2
    mov byte[drive], 80h
    mov byte[sectornum], 2
    mov word[segmentaddr], TUISEG ; kernel seg
    mov word[segmentoffset], TUIOFFSET ; kernel offset
    call DiskRead


; Command inputs
cmd_help db 'help', 0
cmd_ver db 'ver', 0
cmd_halt db 'halt', 0
cmd_shutdown db 'shutdown', 0
cmd_tui db 'tui', 0

cmd_help_len equ $ - cmd_help - 1       ; Calculate length of cmd_help
cmd_ver_len equ $ - cmd_ver - 1         ; Calculate length of cmd_ver
cmd_halt_len equ $ - cmd_halt - 1       ; Calculate length of cmd_halt
cmd_shutdown_len equ $ - cmd_shutdown - 1 ; Calculate length of cmd_shutdown

; Command outputs
cmdout_help_1 db '---          Help menu          ---', 0
cmdout_help_2 db 'ver       > Displays System version', 0
cmdout_help_3 db 'help      > Shows help menu for CMD', 0
cmdout_help_4 db 'halt      > Halts the system', 0
cmdout_help_5 db 'shutdown  > Turns off your PC', 0
cmdout_help_6 db 'tui       > Enables the TUI mode', 0

; OS getting too big, needs a proper bootloader and disk features

cmdout_ver db 'System version ', 0

; --- fail ---
cmd_none db '', 0
failure_cmd db 'Invalid command or file name.', 0
