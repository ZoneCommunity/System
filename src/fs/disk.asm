[BITS 16]

; BIOS Parameter Block
bpb_oem:                    DB  "REDOS0.2"
bpb_bytes_per_sector:       DW  512
bpb_sectors_per_cluster:    DB  1
bpb_reserved_sectors:       DW  1
bpb_fat_count:              DB  2
bpb_dir_entries_count:      DW  0E0h
bpb_total_sectors:          DW  2880
bpb_media_descriptor_type:  DB  0F0h
bpb_sectors_per_fat:        DW  9
bpb_sectors_per_track:      DW  18
bpb_heads:                  DW  2
bpb_hidden_sectors:         DD  0
bpb_large_sector_count:     DD  0

; Extended Boot Record
ebr_drive_number:           DB  0
                            DB  0
ebr_signature:              DB  29h
ebr_volume_id:              DB  12h, 34h, 56h, 78h
ebr_volume_label:           DB  'ReDOS      '
ebr_system_id:              DB  'FAT12   '

print_root:
    call load_root
    ret

load_root:
    ; Calculate and load root directory
    mov ax, [bpb_sectors_per_fat]
    mov bl, [bpb_fat_count]
    xor bh, bh
    mul bx
    add ax, [bpb_reserved_sectors]  ; LBA of the root directory
    mov [current_directory_start], ax
    push ax

    mov ax, [bpb_dir_entries_count]
    shl ax, 5 ; ax *= 32
    xor dx, dx
    div word [bpb_bytes_per_sector] ; (32*num of entries)/bytes per sector
    
    test dx, dx    
    jz .no_remainder
    inc ax

.no_remainder:
    mov cl, al
    pop ax
    mov dl, [ebr_drive_number]
    mov bx, buffer
    call disk_read

    call print_current_directory
    ret

print_current_directory:
    pusha
    mov si, dir_content_msg
    call println

    mov ax, [current_directory_start]
    mov dl, [ebr_drive_number]
    mov bx, buffer
    mov cl, 1  ; Read one sector for now
    call disk_read

    mov di, buffer
    mov cx, [bpb_dir_entries_count]

.next_entry:
    mov al, [di]
    test al, al
    jz .done  ; end of directory

    cmp al, 0xE5
    je .skip_entry  ; deleted entry

    ; check if it's a valid file or directory
    mov al, [di + 11]  ; attribute byte
    test al, 0x08  ; volume label
    jnz .skip_entry

    ; For changing colors
    mov ah, 0x06
    mov bh, 0x1F
    mov ch, 24d     ; start row
    mov cl, 00d	    ; start col
    mov dh, 24d	    ; end of row
    mov dl, 79d	    ; end of col
    int 10h
    
    ; print filename
    push cx
    push di
    mov cx, 11
.print_char:
    mov al, [di]
    call print_char
    inc di
    loop .print_char

    ; Check if it's a directory
    pop di
    push di
    mov al, [di + 11]
    test al, 0x10
    jz .not_directory
    
    mov si, dir_indicator
    call print

.not_directory:
    call newln

    pop di
    pop cx

.skip_entry:
    add di, 32  ; next dir entry
    loop .next_entry

.done:
    popa
    ret

find_file:
    push ax
    push cx
    push si

    mov ax, [current_directory_start]
    mov dl, [ebr_drive_number]
    mov bx, ext_buffer  ; Use a temporary buffer for reading directory
    mov cl, 1  ; Read one sector for now
    call disk_read

    mov di, ext_buffer
    mov cx, [bpb_dir_entries_count]

.next_entry:
    mov al, [di]
    test al, al
    jz .not_found  ; end of directory

    cmp al, 0xE5
    je .skip_entry  ; deleted entry

    push di
    push cx
    mov si, temp_buffer  ; Compare with our formatted filename
    mov cx, 11
    repe cmpsb
    je .found
    pop cx
    pop di

.skip_entry:
    add di, 32  ; next dir entry
    loop .next_entry

.not_found:
    stc  ; Set carry flag to indicate file not found
    jmp .done

.found:
    pop cx  ; Clean up the stack
    pop di  ; DI now points to the start of the matching directory entry
    clc  ; Clear carry flag to indicate file found

.done:
    pop si
    pop cx
    pop ax
    ret

print_file_contents:
    pusha
    mov si, file_contents_msg
    call println

    ; Get first cluster
    mov ax, [di + 26]  ; First cluster is at offset 26 in directory entry
    
    ; Get file size (located at offset 28-29 in directory entry)
    mov ax, [di + 28]
    mov [file_size], ax

.read_cluster:
    push ax  ; Save current cluster
    
    ; Convert cluster to LBA
    sub ax, 2
    xor cx, cx
    mov cl, [bpb_sectors_per_cluster]
    mul cx
    add ax, [data_start]
    
    ; Read cluster
    mov bx, temp_buffer
    mov cl, [bpb_sectors_per_cluster]
    mov dl, [ebr_drive_number]
    call disk_read
    
    ; Print cluster contents
    mov si, temp_buffer
    mov cx, [file_size]  ; Use file size to control print

.print_loop:
    cmp cx, 0
    jz .next_cluster   ; Stop when file size reaches 0
    lodsb
    dec cx
    cmp al, 32  ; Check if character is below space (non-printable)
    jb .skip_char
    cmp al, 126  ; Check if character is above '~' (non-printable)
    ja .skip_char
    call print_char
.skip_char:
    loop .print_loop

.next_cluster:
    ; Get next cluster
    call get_next_cluster
    test ax, ax
    jz .done  ; End of file if no next cluster
    jmp .read_cluster  ; Continue reading next cluster

.done:
    popa
    ret


get_next_cluster:
    push es
    push bx
    push dx
    
    ; Calculate FAT sector and offset
    mov bx, 3
    mul bx
    shr ax, 1  ; Divide by 2 (same as ax/2)
    mov bx, [bpb_bytes_per_sector]
    div bx  ; AX = FAT sector, DX = offset within sector
    
    add ax, [bpb_reserved_sectors]  ; Add reserved sectors to get LBA
    
    push dx  ; Save offset
    mov bx, buffer
    mov cl, 2  ; Read 2 sectors to ensure we get all data
    mov dl, [ebr_drive_number]
    call disk_read
    
    pop bx  ; Restore offset into BX
    mov ax, [buffer + bx]
    
    ; If it's an odd cluster, shift 4 bits right
    test bx, 1
    jz .even_cluster
    shr ax, 4
.even_cluster:
    and ax, 0x0FFF  ; Mask to 12 bits
    
    pop dx
    pop bx
    pop es
    ret

print_char:
    mov ah, 0x0E
    int 0x10
    ret

lba_to_chs:
    push ax
    push dx

    xor dx, dx
    div word [bpb_sectors_per_track]
    inc dx  ; Sector
    mov cx, dx

    xor dx, dx
    div word [bpb_heads]

    mov dh, dl  ; Head
    mov ch, al
    shl ah, 6
    or cl, ah   ; Cylinder

    pop ax
    mov dl, al
    pop ax

    ret

disk_read:
    push ax
    push bx
    push cx
    push dx
    push di

    call lba_to_chs

    mov ah, 02h
    mov di, 3   ; Loop Counter

.retry:
    stc
    int 13h
    jnc .done

    call disk_reset

    dec di
    test di, di
    jnz .retry

    mov si, read_failure
    call println
    hlt

.done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc disk_read.retry
    popa
    ret

; Data
current_directory_start     dw 0
data_start                  dw 0

dir_content_msg             db 'Directory content:', 13, 10, 0
dir_indicator               db ' <DIR>', 0
dir_not_found_msg           db 'Directory not found.', 13, 10, 0
root_dir_msg                db 'Content:', 13, 10, 0
read_failure                db 'Failed to read disk.', 13, 10, 0
file_contents_msg           db 'File contents:', 13, 10, 0
file_not_found_msg          db 'File not found.', 13, 10, 0
