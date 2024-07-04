; ReDOS Bootloader v0.2 (fat12 impl)
[BITS 16]
[ORG 0x7C00]

jmp short start
nop

bdb_oem:                    DB  "REDOS0.2"
bdb_bytes_per_sector:       DW  512
bdb_sectors_per_cluster:    DB  1
bdb_reserved_sectors:       DW  1
bdb_fat_count:              DB  2
bdb_dir_entries_count:      DW  0E0h
bdb_total_sectors:          DW  2880
bdb_media_descriptor_type:  DB  0F0h
bdb_sectors_per_fat:        DW  9
bdb_sectors_per_track:      DW  18
bdb_heads:                  DW  2
bdb_hidden_sectors:         DD  0
bdb_large_sector_count:     DD  0

ebr_drive_number:           DB  0
                            DB  0
ebr_signature:              DB  29h
ebr_volume_id:              DB  12h, 34h, 56h, 78h
ebr_volume_label:           DB  'ReDOS      '
ebr_system_id:              DB  'FAT12   '

start:
    ; Set up segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    call cls
    mov si, boot_msg
    call print_string

    ; 4 Segments
    ; Reserved Segment: 1 Sector
    ; FAT: 9 * 2 = 18 Sectors
    ; Root Directory
    ; Data

    mov ax, [bdb_sectors_per_fat]
    mov bl, [bdb_fat_count]
    xor bh, bh
    mul bx  ; Gives the 18 Sectors
    add ax, [bdb_reserved_sectors]  ;LBA of the root directory
    push ax

    mov ax, [bdb_dir_entries_count]
    shl ax, 5 ;ax *= 32
    xor dx, dx
    div word [bdb_bytes_per_sector] ;(32*num of entries)/bytes per sector

    test dx, dx
    jz rootDirAfter
    inc ax

rootDirAfter:
    mov cl, al
    pop ax
    mov dl, [ebr_drive_number]
    mov bx, buffer
    call disk_read

    xor bx, bx
    mov di, buffer

searchKernel:
    mov si, file_kernel_bin
    mov cx, 11
    push di
    repe cmpsb
    pop di
    je foundKernel

    add di, 32
    inc bx
    cmp bx, [bdb_dir_entries_count]
    jl searchKernel

    jmp kernelNotFound

kernelNotFound:
    mov si, msg_kernel_not_found
    call print_string

    hlt

foundKernel:
    mov ax, [di+26] ; di is address of kernel, 26 offset to first cluster field
    mov [kernel_cluster], ax

    mov ax, [bdb_reserved_sectors]
    mov bx, buffer
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]

    call disk_read

    mov bx, kernel_load_segment
    mov es, bx
    mov bx, kernel_load_offset

loadKernelLoop:
    mov ax, [kernel_cluster]
    add ax, 31  ; For floppy disk
    mov cl, 1
    mov dl, [ebr_drive_number]

    call disk_read

    add bx, [bdb_bytes_per_sector]

    mov ax, [kernel_cluster] ;(Kernel Cluster * 3)/2
    mov cx, 3
    mul cx
    mov cx, 2
    div cx

    mov si, buffer
    add si, ax
    mov ax, [ds:si]

    or dx, dx
    jz even ; Even, otherwise odd

odd:
    shr ax, 4
    jmp nextClusterAfter

even:
    and ax, 0x0FFF
    
nextClusterAfter:
    cmp ax, 0x0FF8
    jae readFinish

    mov [kernel_cluster], ax
    jmp loadKernelLoop

readFinish:
    mov dl, [ebr_drive_number]
    mov ax, kernel_load_segment
    mov ds, ax
    mov es, ax
    
    jmp kernel_load_segment:kernel_load_offset

    hlt

; functions

; input: LBA index in ax
; cx [bits 0-5]: sector number
; cx [bits 6-15]: cylinder
; dh: head
lba_to_chs:
    push ax
    push dx

    xor dx, dx
    div word [bdb_sectors_per_track]    ;(LBA % sectors per track) + 1 <- Sector
    inc dx  ; Sector
    mov cx, dx

    xor dx, dx
    div word [bdb_heads]

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
    call print_string
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

    ;mov si, success_msg
    ;call print_string

    ret

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret


cls:
    mov ax, 02
    int 0x10

    mov ah, 0x06
    mov bh, 0x1F
    mov ch, 00d
    mov cl, 00d
    mov dh, 24d
    mov dl, 79d
    int 10h

    mov ah, 0x02
    mov bh, 0x00
    mov dh, 0x00
    mov dl, 0x00
    int 10h

    ret

boot_msg db 'ReDOS Bootloader has loaded', 13, 10, 0

read_failure db 'Read fail!', 13, 10, 0

; this thing
file_kernel_bin db 'KERNEL  BIN'
msg_kernel_not_found db 'KERNEL.BIN not found!'
kernel_cluster DW 0

kernel_load_segment equ 0x2000
kernel_load_offset equ 0

times 510-($-$$) db 0
dw 0xAA55

buffer: