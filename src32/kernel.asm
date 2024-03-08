%INCLUDE "src32/boot/memory.asm"
[BITS 32]
[ORG KERNELOFFSET]

jmp start
start:
    hlt