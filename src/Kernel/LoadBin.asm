; Functions
LBA2CHSBin:
    xor dx, dx              ; Clear DX
    div word [bpbSectorsPerTrack]   ; Divide AX by sectors per track
    inc dl                  ; Adjust sector (0-based to 1-based)
    mov byte [Sector], dl   ; Store sector
    xor dx, dx              ; Clear DX again
    div word [bpbHeadsPerCylinder]  ; Divide AX by heads per cylinder
    mov byte [Head], dl     ; Store head
    mov byte [Track], al    ; Store track
    ret                     ; Return

FATCluster2LBABin:
    sub ax, 0x0002          ; Subtract 2 from FAT cluster
    xor cx, cx              ; Clear CX
    mov cl, byte [bpbSectorsPerCluster] ; Sectors per cluster
    mul cx                  ; AX = AX * CX
    add ax, word [DataSectorBeginning]  ; Add base data sector
    ret                     ; Return

LoadBinSectors:
    push dx                 ; Save DX

    mov ah, 0x02            ; Function: read sectors
    mov al, dh              ; Number of sectors to read
    mov ch, byte [Track]    ; Track
    mov cl, byte [Sector]   ; Sector
    mov dh, byte [Head]     ; Head
    mov dl, 0               ; Drive number (boot drive)
    int 0x13                ; BIOS interrupt

    jc DiskErrorBin            ; Jump if carry flag set (error)

    pop dx                  ; Restore DX
    cmp dh, al              ; Compare read sectors with expected
    jne DiskErrorBin           ; Jump if not equal (error)

    ret                     ; Return

DiskErrorBin:
    ; Handle disk error here
    jmp FailureBin             ; Jump to failure handling

FailureBin:
    ; Handle failure here (endless loop or other actions)
    jmp $                   ; Endless loop

LoadBin:
    ; Calculate root directory size in sectors
    xor cx, cx              ; Clear CX
    xor dx, dx              ; Clear DX
    mov ax, 0x0020          ; 32 bytes per directory entry
    mul word [bpbRootEntries]   ; Total size of directory
    div word [bpbBytesPerSector]    ; Sectors used by directory
    xchg ax, cx             ; Move result to CX

    ; Calculate LBA address of root directory
    mov al, byte [bpbNumberOfFATs]  ; Number of FATs
    mul word [bpbSectorsPerFAT]     ; Sectors used by FATs
    add ax, word [bpbReservedSectors]   ; Add reserved sectors
    mov word [DataSectorBeginning], ax    ; Store LBA address
    add word [DataSectorBeginning], cx    ; Add directory size

    ; Convert LBA address to CHS
    call LBA2CHSBin

    ; Read root directory into memory
    mov bx, ROOTDIRECTORY_AND_FAT_OFFSET   ; Offset to load root directory
    mov dh, cl              ; Number of sectors
    call LoadBinSectors        ; Read sectors

    ; Find file in root directory
    mov cx, [bpbRootEntries]    ; Number of entries
    mov di, ROOTDIRECTORY_AND_FAT_OFFSET    ; Address of root directory

.loop:
    push cx                 ; Save CX
    mov cx, 11              ; Compare 11 characters (8.3 convention)
    mov si, FileName        ; File name to compare
    push di                 ; Save DI
    rep cmpsb               ; Compare strings
    pop di                  ; Restore DI
    je LoadFATBin              ; Jump if match found
    pop cx                  ; Restore CX
    add di, 32              ; Move to next directory entry
    loop .loop              ; Loop until all entries checked
    jmp FailureBin             ; File not found

LoadFATBin:
    ; Load FAT into memory
    mov dx, word [di + 0x001A]  ; Start cluster
    mov word [Cluster], dx  ; Store cluster

    ; Calculate number of sectors used by all FATs
    xor ax, ax              ; Clear AX
    mov byte [Track], al    ; Initialize track
    mov byte [Head], al     ; Initialize head
    mov al, 1               ; Read one FAT
    mul word [bpbSectorsPerFAT] ; Sectors per FAT
    mov dh, al              ; Store sectors in DX

    ; Load FAT sectors
    mov bx, ROOTDIRECTORY_AND_FAT_OFFSET   ; Memory offset for FATs
    mov cx, word [bpbReservedSectors]     ; Reserved sectors
    add cx, 1               ; Start from second sector
    mov byte [Sector], cl   ; Sector to start reading
    call LoadBinSectors        ; Read sectors

    ; Load image data
    mov bx, kernel_load_segment
    mov es, bx
    mov bx, KERNEL_OFFSET

.load_image_loop:
    mov ax, word [Cluster]  ; FAT cluster to read
    call FATCluster2LBABin     ; Convert cluster to LBA
    call LBA2CHSBin            ; Convert LBA to CHS

    xor dx, dx              ; Clear DX
    mov dh, byte [bpbSectorsPerCluster] ; Sectors to read
    call LoadBinSectors        ; Read cluster
    add bx, [bpbBytesPerSector]  ; Advance address by sector size

    ; Calculate next cluster
    mov ax, word [Cluster]  ; Current cluster
    mov cx, ax              ; Copy cluster
    mov dx, ax              ; Copy cluster
    shr dx, 1               ; Divide by 2
    add cx, dx              ; Sum for (3/2)
    mov di, ROOTDIRECTORY_AND_FAT_OFFSET   ; FAT memory location
    add di, cx              ; Index into FAT
    mov dx, word [di]       ; Read FAT entry
    test ax, 0x0001         ; Check if odd or even
    jnz .odd_cluster        ; Jump to odd cluster handling

.even_cluster:
    and dx, 0000111111111111b   ; Take lowest 12 bits
    jmp .done               ; Jump to done

.odd_cluster:
    shr dx, 0x0004          ; Take highest 12 bits

.done:
    mov word [Cluster], dx  ; Store new cluster
    cmp dx, 0x0FF0          ; Check for end of file
    jb .load_image_loop     ; Jump to load next cluster if not end

.end_load_image:
    pop bx                  ; Restore stack
    pop bx                  ; Restore stack

    ret                     ; Return
