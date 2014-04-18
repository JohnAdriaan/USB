; First, set up the Segment Registers and Stack
??00  FA         CLI
??01  33C0       XOR   AX,AX
??03  8ED0       MOV   SS,AX
??05  BC007C     MOV   SP,0x7C00
??08  8BF4       MOV   SI,SP       ; Start of code to move
??0A  50         PUSH  AX
??0B  07         POP   ES
??0C  50         PUSH  AX
??0D  1F         POP   DS
??0E  FB         STI

; Then, move myself out of the way
??0F  FC         CLD
??10  BF0006     MOV   DI,0x0600
??13  B90001     MOV   CX,0x0100   ; Move everything!
??16  F2A5       REPNE MOVSW       ; This is incorrect, but it works!
??18  EA1D060000 JMP   0x0000:0x061D

; Which Partition is active?
061D  BEBE07     MOV   SI,0x07BE
0620  B304       MOV   BL,0x0004
0622  803C80     CMP   [SI],0x80
0625  740E       JZ    0x0635      ; Found!
0627  803C00     CMP   [SI],0x00
062A  751C       JNZ   0x0648      ; Invalid!
062C  83C610     ADD   SI,+0x10
062F  FECB       DEC   BL
0631  75EF       JNZ   0x0622

; No. Boot ROM-BASIC instead
0633  CD18       INT   0x18

; Fish out Head and CylSect to use
0635  8B14       MOV   DX,[SI]      ; Get Head, but REPLACEs DL with 80h!
0637  8B4C02     MOV   CX,[SI+0x02] ; Get Cylinder/Sector
063A  8BEE       MOV   BP,SI        ; Save found boot partition
063C  83C610     ADD   SI,+0x10     ; Keep looking for unique entry
063F  FECB       DEC   BL
0641  741A       JZ    0x065D       ; Only one!
0643  803C00     CMP   [SI],0x00    ; Only one?
0646  74F4       JZ    0x063C       ; So far...

; "Invalid Partition Table"
0648  BE8B06     MOV   SI,0x068B    ; Oh no!

; ERROR! Write out string.
064B  AC         LODSB
064C  3C00       CMP   AL,0x00
064E  740B       JZ    0x065B
0650  56         PUSH  SI
0651  BB0700     MOV   BX,0x0007
0654  B40E       MOV   AH,0x0E
0656  CD10       INT   0x10
0658  5E         POP   SI
0659  EBF0       JMP   0x064B

; Loop forever
065B  EBFE       JMP   0x065B

; Load Volume Boot Record, as determined
065D  BF0500     MOV   DI,0x0005        ; Try this many times

0660  BB007C     MOV   BX,0x7C00
0663  B80102     MOV   AX,0x0201
0666  57         PUSH  DI
0667  CD13       INT   0x13
0669  5F         POP   DI
066A  730C       JNC   0x0678

; Error on read. Retry after reset (although why bother on a USB stick?)
066C  33C0       XOR   AX,AX
066E  CD13       INT   0x13
0670  4F         DEC   DI               ; One less attempt
0671  75ED       JNZ   0x0660

; "Error loading operating system"
0673  BEA306     MOV   SI,0x06A3
0676  EBD3       JMP   0x064B

; The read worked. May be invalid though...
; Pre-load "Missing operating system"
0678  BEC206     MOV   SI,0x06C2
067B  BFFE7D     MOV   DI,0x7DFE
067E  813D55AA   CMP   [DI],0xAA55
0682  75C7       JNZ   0x064B       ; Yep, it was an Error!

; Jump to VBR
0684  8BF5       MOV   SI,BP
0686  EA007C0000 JMP   0x0000:0x7C00

068B  DB  "Invalid partition table", 0x00
06A3  DB  "Error loading operating system", 0x00
06C2  DB  "Missing operating system", 0x00

07B8  DD  0x5AFD5371       ; Volume signature
07BC  DW  0x0000

07BE  PartEntry  0x00, 0x00, 0x0000, 0x0B, 0x00, 0x0000, 0x000F_BA0C, 0x000F_B9EC
07CE  PartEntry  0x80, 0x01, 0x0001, 0x0B, 0x00, 0x0000, 0x0000_0020, 0x000F_B9EC
07DE  PartEntry  0x00, 0x00, 0x0000, 0x00, 0x00, 0x0000, 0x0000_0000, 0x0000_0000
07EE  PartEntry  0x00, 0x00, 0x0000, 0x00, 0x00, 0x0000, 0x0000_0000, 0x0000_0000

07FE  DW  0xAA55
