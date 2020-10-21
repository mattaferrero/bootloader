; Installer for the 2-stage bootloader to be used in conjunction with the MAA Operating System.
; Specifically designed for the Intel 80386. Modify this code at your own risk. Free to 
; distribute, if you ever get your hands on the source code (over my cold dead body).

; Classic BIOS routines will load the MBR into 0:0x7c00. This will set the CS register to 0.

[bits 16]
[org 0x7c00]

; We will first zero out all segment registers with the exception of CS and DS, which will be
; set later for easier offset calculations. Assume SS is undefined.
 
xor ax, ax		; segment registers cannot be directly set.
mov gs, ax
mov fs, ax
mov es, ax

; We are using BIOS low level disk services interrupt 13h, to read in stage2 of the bootloader
; into memory. BIOS interrupt 13h's argument ah is the specific read command, and in our case
; we are using the archaic CHS addressing method to read in sectors of a disk for simplicities
; sake, as opposed to the LBA read command.

mov ah, 0x2		; The Read Command
mov al, 0x5		; Number of Sectors to read (choosing 5 to stay safely below the limit)
xor ch, ch		; Cylinder to start read from
mov cl, 0x2		; Sector to start read from (MBR starts at 1, each sector is 512 bytes)
xor dh, dh		; Head to read from
mov dl, 0x80		; Drive to read from (0x80 is HDD 1)

; es:bx is the Buffer Address Pointer. We are reading the sectors into 0x1000:0x0000.

mov bx, 0x1000
mov es, bx
mov ds, bx
xor bx, bx		

int 0x13		; BIOS low level disk services interrupt

jmp 0x1000:0x0000	; Implicitly setting CS to segment 0x1000.

