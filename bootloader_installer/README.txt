				PLEASE READ THIS FIRST
================================================================================

Introduction
------------
	This is a small bootloader project to be used in conjunction with the 
MAA operating system, designed specifically for the x86 Intel 80386 CPU circa
1986. The entire purpose of this project is soley for educational purposes only,
using a relatively simplistic legacy x86 system and BIOS. This bootloader and
operating system project are meant to be run on a LEGACY x86 32-bit system. In 
an effort to maintain backwards compatibility, the x86 CPU is notorious for 
suffering from anachronistic tendencies and less-than-elegant design choices in
systems programming. 

A far better choice for an aspiring programmer (such as myself) to learn OS 
development around would be to program for a much simpler microcontroller system
such as the Arduino or Rasperry Pi. Yet despite, and in part because of the 
challenges in coding for a difficult architecture, I have decided to learn OS
development using x86 as the backbone. Simply be warned this is by no means the
most efficient or easiest method. 

Furthermore, in modern OS development a standardized approach to the booting
sequence was implemented in UEFI, replacing the now defunct and legacy BIOS
systems. For those interested in /modern/ OS development, it is wise to learn
the intracacies of UEFI, which provides a far easier environment for kernel 
loading.

With all the warnings and caveats out of the way, let's begin.


The Boot Sequence
-----------------

	The sequence of events that occur after CPU reset are fairly complex, 
but necessary to understand to dissect the bootloader code. After reset, the
Instruction Pointer (IP) is set to 0xFFFFFFF0 which contains a single jump
instruction to wherever the BIOS startup code is located (likely in some ROM
chip). The BIOS will then begin its POST code operations. The details of POST
vary from BIOS to BIOS and are not relevant from an OS developer standpoint.

The CPU begins execution in 16-bit mode (known as Real Mode), using a complex
segmentation memory model. Once POST operations are complete, the BIOS will
attempt to "scan" for a bootable drive, typically prioritizing the CD-ROM drive,
the Floppy Disk Drive, and the attached Hard Drive Disks in that order. 
Depending on the bootable medium type, the BIOS may first scan for an existing 
partition table. 

The BIOS will scan for 2 consecutive single-byte sequences: 0x55 and 0xAA, at
byte offsets 510 and 511 respectively in each device's boot sector (typically 
the first sector in a drive). Upon successful read of the bootable flag, the
BIOS will load the entire boot sector into memory at 0x0000:0x7c00 (segment 0,
offset 0x7c00).

The IP will now be set to the first byte of where the boot sector was loaded
into memory, marking the end of the boot process and giving control of the 
system to the programmer. As a consequence of the IP being set to the loaded
bootsector offset, the first instruction of the bootloader /must/ be a valid
opcode - it cannot contain data.


The installer.s file
--------------------

	The bootloader is designed to operate in stages 1 and 2. installer.s 
represents stage 1, and is meant to be written to the bootable drive at the
first offset in the boot sector. Stage 1 concerns itself primarily with some
minor initialization operations and loading stage 2 into memory. The reason for
a dual stage bootloader is due to considerable memory restraints. In a classical
Master Boot Record (MBR) we would have a grand total of 446 bytes to perform
operations in. Dividing the bootloader into two stages lets us operate in a 
larger memory space.

First all of the segment registers with the exception of the Code Segment (CS)  
and Data Segment (DS) registers are set to 0. It is extremely important that the
Stack Segment (SS) register is set to 0, for reasons that are not entirely clear
to this programmer (presumably the computer cries and makes a frowny face).

Next, we will call BIOS Interrupt 0x13 - the BIOS Low Level Disk Services
Interrupt, with function call 0x2 - Read Sectors From Drive. The choice to use
function 0x2, which uses the now defunct and archaic CHS drive addressing method
is primarily for simplicities' sake. More modern systems will likely wish to use
LBA.

With function 0x2, we read in the first 5 sectors of the first detected Hard 
Drive and load them into memory at 0x1000:0x0000. This loaded code will be stage2 
of our bootloader, contained in file installer2.s. 

The Data Segment is then explicitly set to segment 0x1000, and the Code Segment
is implicitly set with a far jump to segment 0x1000.

Finally, the rest of the file is necessarily padded out with 0s up to byte 
offset 446, marking the start of the partition table in a classical MBR. This
leaves the decision of writing the bootable flag to the partition tool.


