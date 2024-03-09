[BITS 16]
[ORG 0x0000]


; TUI mode
tui_start:
    call loadwelcome
    call loadtext
    jmp inputreciever

    ; call cls
    
    ret

loadwelcome:
    ; clear the screen
    mov ax, 02
    int 0x10

    ; For changing colors
    mov ah, 0x06
    ; Changes to white text on black background

    mov bh, 0x8F
    mov ch, 00d     ; start row
    mov cl, 00d     ; start col
    mov dh, 00d     ; end of row
    mov dl, 79d     ; end of col
    int 10h

    mov bh, 0x7F
    mov ch, 01d     ; start row
    mov cl, 00d     ; start col
    mov dh, 24d     ; end of row
    mov dl, 79d     ; end of col
    int 10h

    ; Hide Cursor
    mov ah, 0x01    ; Set cursor size function
    mov cx, 0x2000  ; Make cursor invisible, CX = 0x2000
    int 0x10
    ret

loadtext:
    mov ah, 0x02    ; move cursor Instruction
    mov bh, 0x00    ; page
    mov dh, 0x00    ; row
    mov dl, 0x00    ; column
    int 10h
    
    mov si, menubar_1
    ; call print

    ret
    

inputreciever:
.readkeys:
    mov ah, 0x00  ; Service 0h: Read key press
    int 16h       ; Put the pressed key into AL

    ;cmp al, 13    ; Check if Enter key is pressed
    ;je .handler   ; If Enter is pressed, go to command handler

    ;cmp al, 8     ; Check if Backspace key is pressed
    ;je .handle_backspace ; If Backspace is pressed, handle it separately

    ;cmp al, 0     ; Check for extended key codes
    ;jne .process_key

    ;mov ah, 0x00  ; Read the extended key code
    ;int 16h       ; Put the extended key code into AL

    ;mov ah, 0x0e
    ;int 10h

    ; Assume al contains the scan code of the pressed key
    cmp ah, 0x4B  ; Compare with left arrow scan code
    je .left_pressed  ; Jump if equal to left arrow scan code
    cmp ah, 0x4D  ; Compare with right arrow scan code
    je .right_pressed  ; Jump if equal to right arrow scan code

    cmp al, 27
    ret

    jmp .readkeys

.left_pressed:
    mov si, left
    call println
    
    jmp .readkeys
.right_pressed:
    mov si, right
    call println
    
    jmp .readkeys

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
    mov ax, 0E0Dh ; BIOS.Teletype
    int 10h
    mov ax, 0E0Ah   ;0Ah = linefeed
    int 10h

    jmp print

newln:
    mov bx,0007h
    mov ax, 0E0Dh ; BIOS.Teletype
    int 10h
    mov ax,0E0Ah   ;0Ah = linefeed
    int 10h

    ret

cls:
    ; clear the screen
    mov ax, 02
    int 0x10

    ; For changing colors
    ;mov ah, 0x06
    ; Changes to white text on black background
    ;mov bh, 0x0F
    ;mov ch, 00d     ; start row
    ;mov cl, 00d	    ; start col
    ;mov dh, 24d	    ; end of row
    ;mov dl, 79d	    ; end of col
    ;int 10h

    ; then we move the cursor
    mov ah, 0x02	; move cursor Instruction
    mov bh, 0x00	; page
    mov dh, 0x00	; row
    mov dl, 0x00	; column
    int 10h
    
    ret

; scrolling

scrollup:
    mov ah, 06h      ; AH = 06h for scroll window up BIOS function
    inc al
    mov bh, 0        ; BH = 0 for scrolling entire window
    mov cx, 0        ; CH = 0 (upper row), CL = 0 (leftmost column)
    mov dh, 24       ; DH = 24 (bottom row)
    mov dl, 79       ; DL = 79 (rightmost column)
    int 10h          ; Call BIOS video interrupt to scroll window up
    ret

; Strings
menubar_1 db 'Welcome app -------------------------------------------------------------- About', 0

left db 'left', 0
right db 'right', 0