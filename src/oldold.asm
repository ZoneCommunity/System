; ReDOS Bootloader v0.2 (fat12 impl)
[BITS 16]
[ORG 0x7c00]

jmp start
nop

; BIOS Parameter Block (BPB)
bpbOEM         db "ReDOS   "     ; OEM Name
bpbBytesPerSec dw 512            ; Bytes per sector
bpbSecPerClus  db 1              ; Sectors per cluster
bpbResSectors  dw 1              ; Reserved sectors
bpbFATs        db 2              ; Number of FATs
bpbRootEntries dw 224            ; Max number of root directory entries
bpbSectors     dw 2880           ; Total number of sectors
bpbMedia       db 0xF0           ; Media descriptor
bpbFATSize     dw 9              ; Sectors per FAT
bpbSecPerTrack dw 18             ; Sectors per track
bpbHeads       dw 2              ; Number of heads
bpbHiddenSecs  dd 0              ; Number of hidden sectors
bpbTotalSecs   dd 0              ; Total number of sectors (if bpbSectors is 0)


; Constants
KERNEL_SEGMENT equ 0x1000
KERNEL_OFFSET equ 0x0000
KERNEL_SECTORS equ 40

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

    
    call read_fat
    call read_root_dir
    call print_root_dir

    mov si, boot_msg
    call print_string

    jmp $

read_fat:
    mov ah, 0x02       ; BIOS read sector function
    mov al, bpbFATSize ; Number of sectors to read
    mov ch, 0x00       ; Cylinder number
    mov cl, 0x02       ; Sector number (first FAT starts at sector 2)
    mov dh, 0x00       ; Head number
    mov dl, 0x00       ; Drive number (0 for floppy)
    mov bx, 0x8100     ; ES:BX points to buffer (0x0000:0x8100)
    int 0x13           ; BIOS interrupt
    jc fat_error

    ret

fat_error:
    mov si, fat_error_msg
    call print_string
    jmp $

read_root_dir:
    mov ah, 0x02              ; BIOS read sector function
    mov al, 14                ; Number of sectors to read (224 entries * 32 bytes per entry / 512 bytes per sector = 14 sectors)
    mov ch, 0x00              ; Cylinder number
    mov cl, 0x11              ; Sector number (first root directory sector, after reserved sectors and FATs)
    mov dh, 0x00              ; Head number
    mov dl, 0x00              ; Drive number (0 for floppy)
    mov bx, 0x8200            ; ES:BX points to buffer (0x0000:0x8200)
    int 0x13                  ; BIOS interrupt
    jc root_error

    ret

root_error:
    mov si, root_error_msg
    call print_string
    jmp $


print_root_dir:
    mov bx, 0x8200            ; Root directory buffer
    mov cx, 224               ; Number of entries

.next_entry:
    ; Check if we've reached the end
    cmp cx, 0
    je .done

    ; Read the first byte to check if the entry is used
    mov al, [bx]
    cmp al, 0x00              ; Unused entry
    je .next

    ; Print the filename (8 characters)
    mov si, bx
    call print_filename

    ; Print the file extension (3 characters)
    add si, 8
    call print_extension

    ; Print newline
    call print_newline

.next:
    add bx, 32                ; Move to the next entry (32 bytes per entry)
    dec cx
    jmp .next_entry

.done:
    ret

print_filename:
    mov cx, 8
.print_next_char:
    lodsb
    cmp al, 0x20              ; Check for space (unused character in filename)
    je .skip
    call print_char
.skip:
    loop .print_next_char
    ret

print_extension:
    mov cx, 3
.print_next_ext_char:
    lodsb
    cmp al, 0x20              ; Check for space (unused character in extension)
    je .skip_ext
    call print_char
.skip_ext:
    loop .print_next_ext_char
    ret


; ----------------------------------------------------------------------------------

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

print_char:
    mov ah, 0x0E
    int 0x10
    ret

print_newline:
    mov al, 13
    call print_char
    mov al, 10
    call print_char
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
loading_msg db 'Loading kernel...', 13, 10, 0
successfat_msg db 'Read successful!', 13, 10, 0
error_msg db 'Something went wrong while attempting to boot ReDOS.', 13, 10, 0
fat_error_msg db 'FAT error', 13, 10, 0
root_error_msg db 'Root error', 13, 10, 0
boot_drive db 0

times 510-($-$$) db 0
dw 0xAA55

