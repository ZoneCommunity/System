print:
    mov ah, 0Eh

.repeat:
    mov ah, 0Eh
    ; lodsb loads the next character from si
    lodsb
    ; acts as "if else" in a way
    cmp al, 0
    je .done
    int 10h
    ; loops
    jmp .repeat

.done:
    ret ; return to start

println:
    mov bx, 0007h
    mov ax, 0E0Dh
    int 10h
    mov ax, 0E0Ah
    int 10h

    ; For changing colors
    mov ah, 0x06
    mov bh, 0x0F
    mov ch, 24d     ; start row
    mov cl, 00d	    ; start col
    mov dh, 24d	    ; end of row
    mov dl, 79d	    ; end of col
    int 10h

    jmp print

newln:
    mov bx, 0007h
    mov ax, 0E0Dh
    int 10h
    mov ax, 0E0Ah
    int 10h

    ; For changing colors
    mov ah, 0x06
    mov bh, 0x0F
    mov ch, 24d     ; start row
    mov cl, 00d	    ; start col
    mov dh, 24d	    ; end of row
    mov dl, 79d	    ; end of col
    int 10h

    ret

cls:


    ; clear the screen
    mov ax, 02
    int 0x10

    ; For changing colors
    mov ah, 0x06
    mov bh, 0x0F
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