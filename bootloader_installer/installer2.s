; This is the Second stage of the boot loader. The code in installer.s Should have run
; first before this code. This code will be loaded directly into memory at 0x1000:0x0000.

[bits 16]
[org 0x0000]

; This portion of code specifically deals with checking and enabling the a20 line. 
; Realistically, the a20 line should be enabled with a classical BIOS by default.
; If it is not, then we will call you_cannot_be_serious() to deal with this mess.

; First step is to modify the data at 0:7DFE (this value should be 0xaa55 initially).

mov ax, [gs:0X7DFE] 		; GS was zerod out earlier
inc ax				; increment by 1 just to ensure we have a different value.

; Next we will store the data at FFFF:7E0E, and do a compare. If the values are
; different, a20 is enabled. Otherwise, a20 is disabled.

mov bx, 0XFFFF
mov gs, bx

mov cx, [gs:0X7E0E]
cmp ax, cx

je .you_cannot_be_serious	; IT BELONGS IN A MUSEUM (so do I for that matter).


; Testing to see if we can print stuff out.

; .you_cannot_be_serious:

; mov al, 0x000A
; mov bh, 0
; mov bl, 0x000F
; mov cx, 1

; mov ah, 0x0a

; int 0x10

; Here we set the Global Descriptor Table entries, as well as the GDT entry point.
; The GDT entries are all 8 bytes each, with a maximum of 8,192 entries. We really
; only need 3 entries here: null start, cs and ds. Each entry is fairly complex due
; to broken fields. See page 108 of the Intel 80386 Programmer's Reference Manual.

mov ax, .GDT_LOAD
LGDT [ax]			; wee..

.GDT:

	; The NULL entry

	dd 0x00000000	
	dd 0x00000000


	; The Data Segment Descriptor (ring 0 access)

	db 0xFF, 0XFF		; Segment Limit field
	db 0x00, 0x00		; Segment Base field (24 bits, last 8 in next field)
	db 0x00, 0x92		; Access byte
	db 0xCF, 0x00		; Flags and Base

	; The Code Segment Descriptor (ring 0 access)

	db 0xFF, 0XFF
	db 0x00, 0x00
	db 0x00, 0x9A
	db 0xCF, 0X00

.GDT_LOAD:

	dw 0x18
	dd .GDT


