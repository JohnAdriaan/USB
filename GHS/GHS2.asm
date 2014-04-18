; First, set up the Segment Registers and Stack
??00  FA         CLI
??01  B80000     MOV   AX,0x0000
??04  8ED0       MOV   SS,AX
??06  BC007C     MOV   SP,0x7C00
??09  8BF4       MOV   SI,SP
??0B  50         PUSH  AX
??0C  07         POP   ES
??0D  50         PUSH  AX
??0E  1F         POP   DS
??0F  FB         STI

; Then, move myself out of the way
??10  FC         CLD
??11  BF0006     MOV   DI,0x0600
??14  B90001     MOV   CX,0x0100
??17  F3A5       REP   MOVSW
??19  EA1E060000 JMP   0x0000:0x061E

; Is first Partition active?
061E  BEBE07     MOV   SI,0x07BE
0621  803C80     CMP   [SI],0x80
0624  7402       JZ    0x0628

; No. Boot ROM-BASIC instead
0626  CD18       INT   0x18

; Load first floppy sector.
; Or, load this exact sector back over itself...
; This is probably to confirm whether we're talking 0x80 or 0x00?
0628  56         PUSH  SI
0629  53         PUSH  BX
062A  06         PUSH  ES
062B  BB007C     MOV   BX,0x7C00
062E  B90100     MOV   CX,0x0001
0631  BA0000     MOV   DX,0x0000
0634  B80102     MOV   AX,0x0201
0637  CD13       INT   0x13
0639  07         POP   ES
063A  5B         POP   BX
063B  5E         POP   SI

; Maybe we need 0x80?
063C  B280       MOV   DL,0x80

; Error in load!
063E  720B       JC    0x064B

; No error. Check signature JUST before Partition tables...
0640  BFBC7D     MOV   DI,0x7DBC
0643  813D5553   CMP   [DI],0x5355
0647  7502       JNZ   0x064B

; If it was 0x5355, then back to 0x00
0649  B200       MOV   DL,0x00

; Now save decided-upon value into storage.
064B  BFEB06     MOV   DI,0x06EB
064E  8815       MOV   [DI],DL

; Fish out Head and CylSect to use
0650  8A7401     MOV   DH,[SI+0x01]
0653  8B4C02     MOV   CX,[SI+0x02]
0656  8BEE       MOV   BP,SI            ; Save in BP
0658  EB15       JMP   0x066F ; Load!

; "Invalid Partition Table"
065A  BE9B06     MOV   SI,0x069B

; ERROR! Write out string.
065D  AC         LODSB
065E  3C00       CMP   AL,0x00
0660  740B       JZ    0x066D
0662  56         PUSH  SI
0663  BB0700     MOV   BX,0x0007
0666  B40E       MOV   AH,0x0E
0668  CD10       INT   0x10
066A  5E         POP   SI
066B  EBF0       JMP   0x065D

; Loop forever
066D  EBFE       JMP   0x066D

; Load Volume Boot Record, as determined
066F  BB007C     MOV   BX,0x7C00
0672  B80102     MOV   AX,0x0201
0675  CD13       INT   0x13
0677  7305       JNC   0x067E

; "Error loading operating system"
0679  BEB306     MOV   SI,0x06B3
067C  EBDF       JMP   0x065D

; The load worked. May be invalid though...
; Pre-load "Missing operating system"
067E  BED206     MOV   SI,0x06D2
0681  BFFE7D     MOV   DI,0x7DFE
0684  813D55AA   CMP   [DI],0xAA55
0688  75D3       JNZ   0x065D ; Yep, it was an Error!

; Transfer determined drive number to loaded VBR (assumes BPB!)
068A  BF247C     MOV   DI,0x7C24
068D  BEEB06     MOV   SI,0x06EB
0690  8A04       MOV   AL,[SI]
0692  8805       MOV   [DI],AL          ; DANGER!
0694  8BF5       MOV   SI,BP
0696  EA007C0000 JMP   0x0000:0x7C00

069B  DB  "Invalid partition table", 0x00
06B3  DB  "Error loading operating system", 0x00
06D2  DB  "Missing operating system", 0x00

06EB  DB  0x00   ; Drive number 0x00 or 0x80

07BC  DW  0x0000 ; Code checks here for 0x5355...

07BE  PartEntry  0x00, 0x18, 0x0001, 0x06, 0x1B, 0xF7FB, 0x0000_05E8, 0x001F_3A18
07CE  PartEntry  0x00, 0x00, 0x0000, 0x00, 0x00, 0x0000, 0x0000_0000, 0x0000_0000
07DE  PartEntry  0x00, 0x00, 0x0000, 0x00, 0x00, 0x0000, 0x0000_0000, 0x0000_0000
07EE  PartEntry  0x00, 0x00, 0x0000, 0x00, 0x00, 0x0000, 0x0000_0000, 0x0000_0000

07FE  DW  0xAA55
