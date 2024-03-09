; TUI mode
tui_start:
    call loadwelcome
    jmp $

loadwelcome:
    ; clear the screen
    mov ax, 02
    int 0x10

    ; For changing colors
    mov ah, 0x06
    ; Changes to white text on black background
    mov bh, 0x7F
    mov ch, 00d     ; start row
    mov cl, 00d	    ; start col
    mov dh, 24d	    ; end of row
    mov dl, 79d	    ; end of col
    int 10h

    ; then we move the cursor
    mov ah, 0x02	; move cursor Instruction
    mov bh, 0x00	; page
    mov dh, 0x00	; row
    mov dl, 0x00	; column
    int 10h
    
    ret