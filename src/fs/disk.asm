[BITS 16]

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

ebr_drive_number:           DB  0
                            DB  0
ebr_signature:              DB  29h
ebr_volume_id:              DB  12h, 34h, 56h, 78h
ebr_volume_label:           DB  'ReDOS      '
ebr_system_id:              DB  'FAT12   '

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
    jz run_me2
    inc ax

    call run_me2

    jmp $

run_me:
    call load_root
    call print_current_directory
    jmp $

run_me2:
    mov cl, al
    pop ax
    mov dl, [ebr_drive_number]
    mov bx, buffer
    call disk_read

    call print_current_directory

    jmp wow

    jmp $

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
    mov al, ' '
    call print_char

    pop di
    pop cx

.skip_entry:
    add di, 32  ; next dir entry
    loop .next_entry

.done:
    mov si, newline
    call print
    popa
    ret

print_char:
    mov ah, 0x0E
    int 0x10
    ret

lba_to_chs:
    push ax
    push dx

    xor dx, dx
    div word [bpb_sectors_per_track]    ;(LBA % sectors per track) + 1 <- Sector
    inc dx  ; Sector
    mov cx, dx

    xor dx, dx
    div word [bpb_heads]

    mov dh, dl  ; Head
    mov ch, al
    shl ah, 6
    or cl, ah   ; Cylinder
    ;Head: (LBA / sectors per track) % number of heads
    ;Cylinder: (LBA / sectors per track) / number of heads

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

retry:
    stc
    int 13h
    jnc doneRead

    call diskReset

    dec di
    test di, di
    jnz retry

failDiskRead:
    mov si, read_failure
    call println
    hlt

diskReset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc failDiskRead
    popa
    ret

doneRead:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Data
current_directory_start dw 0
data_start dw 0

dir_content_msg db 'Directory content:', 13, 10, 0
dir_indicator db ' <DIR>', 0
dir_not_found_msg db 'Directory not found.', 13, 10, 0
root_dir_msg db 'Content:', 13, 10, 0
read_failure db 'Failed to read disk.', 13, 10, 0
newline db 13, 10, 0
