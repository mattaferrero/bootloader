; This is the Second stage of the boot loader. The code in installer.s Should have run
; first before this code. This code will be loaded directly into memory at 0x1000:0x0000.

[bits 16]
[org 0x0000]

; This section defines our macros for use in the a20 line check code.

%define BOOTSIG_OFFSET		0x7DFE
%define WRAP_SEGMENT		0xFFFF
%define WRAP_OFFSET		0x7E0E

; This section defines our macros for use in the Global Descriptor Table code.
; Please note: the GDT entries are unecessarily complex. These values do not
; correspond directly to the fields they represent (see page 108 of 80386 manual).

%define GDT_TABLE_SIZE		dw 0x18
%define GDT_TABLE_OFFSET	dd GDT_table

; This section defines our macros for use in the memory map detection code.

%define QUERY_MAP_MAGIC_NUM	0x534D4150
%define QUERY_MAP_FUNCTION	0xE820
%define QUERY_MAP_STRUCT_SIZE	24			; 24 bytes per entry.
	

check_a20:

; This portion of code specifically deals with checking and enabling the a20 line. 
; Realistically, the a20 line should be enabled with a classical BIOS by default.
; If it is not, then we will call you_cannot_be_serious() to deal with this mess.

; First step is to modify the data at 0:BOOTSIG_OFFSET (this value should be 0xaa55 initially).

	mov ax, [gs:BOOTSIG_OFFSET]			; gs was zerod out earlier, grabbing 0xaa55 from the offset.
	inc ax						; Increment by 1 just to ensure we have a different value.
	mov [gs:BOOTSIG_OFFSET], ax			; Here we move the incremented value back into the original location.

; Next we will store the data at WRAP_SEGMENT:WRAP_OFFSET, and do a compare. If the values are
; different, a20 is enabled. Otherwise, a20 is disabled.

	mov bx, WRAP_SEGMENT
	mov gs, bx

	mov cx, [gs:WRAP_OFFSET]
	cmp ax, cx

	je you_cannot_be_serious			; IT BELONGS IN A MUSEUM (so do I for that matter).
	jne GDT_table_code


; Testing to see if we can print stuff out.

you_cannot_be_serious:

mov al, 0x000A
mov bh, 0
mov bl, 0x000F
mov cx, 1

mov ah, 0x0a

int 0x10
hlt	; <-- needs to be shutdown code

GDT_table_code:

; Here we set the Global Descriptor Table entries, as well as the GDT entry point.
; The GDT entries are all 8 bytes each, with a maximum of 8,192 entries. We really
; only need 3 entries here: null start, cs and ds. Each entry is fairly complex due
; to broken fields. See page 108 of the Intel 80386 Programmer's Reference Manual.

	lgdt [GDT_LOAD]			; LGDT takes our structure offset as it's only arg.

	jmp memory_map

GDT_table:

	; The NULL entry

	dd 0x00000000				; First 8 bytes are a required "NULL" start entry.
	dd 0x00000000		


	; The Data Segment Descriptor (ring 0 access)

	db 0xFF, 0XFF				; Segment Limit field
	db 0x00, 0x00				; Segment Base field (24 bits, last 8 in next field)
	db 0x00, 0x92				; Access byte (this is a dirty lie).
	db 0xCF, 0x00				; Flags and Base

	; The Code Segment Descriptor (ring 0 access)

	db 0xFF, 0XFF				; Code Limit field
	db 0x00, 0x00				; Code Base field
	db 0x00, 0x9A				; Access byte
	db 0xCF, 0X00				; Flags and Base

GDT_LOAD:

	GDT_TABLE_SIZE
	GDT_TABLE_OFFSET

memory_map:

; This section concerns itself with obtaining a physical memory map of the system
; using BIOS interrupt 15h. Essentially, the data is written to a list of successive
; structures which will be placed in memory at 0x2000:0000. Each structure is 20
; bytes in length (we will use 24 bytes however due to some shenanigans) and contains
; the following fields: 
;
; Offset in Bytes, Name, Description. The first 64 bits in Name are the 64-bit Base
; Address, the next 64 bits are the Length of the address space, and the last 32
; bits are the address Type.
;

	mov ax, QUERY_MAP_FUNCTION		; Function code to read extended memory past 1 MB
	xor bx, bx				; MUST be set to 0 initially. A value of 0 indicates the end of the map
	
; ES:DI is the Pointer to our Address Range Descriptor Structure which the BIOS will fill in.

	mov cx, 0x2000
	mov es, cx
	mov di,	0x0000				; We will start at offset 0x0000 in segment 0x2000.

	mov cx, QUERY_MAP_STRUCT_SIZE		; Minimum size 20 bytes.
	mov edx, QUERY_MAP_MAGIC_NUM		; BIOS signature 'SMAP'. Verifies caller requests system map.

	int 0x15				; BIOS interrupt Misc. System Services.

; We have to do a little bit of math for our subsequent calls and looping iterations
; to get the full address map. If the first call is successful, eax will be set to 
; QUERY_MAP_MAGIC_NUM, and must be reset. The value in bx -must- be retained, and
; di must be incremented by the entry size.

	cmp eax, QUERY_MAP_MAGIC_NUM
	jne you_cannot_be_serious		; Default error code, will replace/fix soon.

	cmp ebx, 0
	jne memory_map2			; This will loop us until ebx is set to 0, indicating the end of the map.

memory_map2:

	mov eax, QUERY_MAP_MAGIC_NUM
	add di, 24				; Incrementing our pointer by 24 bytes
	mov cx, QUERY_MAP_STRUCT_SIZE
	int 0x15

	cmp eax, QUERY_MAP_MAGIC_NUM
	jne you_cannot_be_serious

	cmp ebx, 0
	jne memory_map2

cli
hlt
