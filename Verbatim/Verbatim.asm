; First, set up the Segment Registers and Stack
0600  33C0                XOR    AX,AX
0602  FA                  CLI
0603  8ED8                MOV    DS,AX
0605  8ED0                MOV    SS,AX
0607  BC007C              MOV    SP,0x7C00
060A  89E6                MOV    SI,SP          ; Start of code to move
060C  06                  PUSH   ES             ; SP=0x7BFE
060D  57                  PUSH   DI             ; SP=0x7BFC
060E  8EC0                MOV    ES,AX
0610  FB                  STI

; Then, move myself out of the way
0611  FC                  CLD
0612  BF0006              MOV    DI,0x0600
0615  B90001              MOV    CX,0x0100      ; Move everything!
0618  F3A5                REP    MOVSW
061A  EA1F060000          JMP    0x0000:0x061F

061F  52                  PUSH   DX             ; Save this SP=0x7BFA
0620  52                  PUSH   DX             ; ... twice SP=0x7BF8
0621  B441                MOV    AH,0x41        ; Check if Extensions present
0623  BBAA55              MOV    BX,0x55AA      ; Magic "Extensions present" flag
0626  31C9                XOR    CX,CX
0628  30F6                XOR    DH,DH
062A  F9                  STC                   ; Prepare for failure if not!
062B  CD13                INT    0x13
062D  7213                JC     0x0642         ; Error!

062F  81FB55AA            CMP    BX,0xAA55      ; Valid?
0633  750D                JNZ    0x0642         ; No! Error!

0635  D1E9                SHR    CX,1           ; Test if can use DAPs
0637  7309                JNC    0x0642         ; No!

; SELF-MODIFYING CODE! (Use DAP function instead)
; 068D  B442    MOV  AH,0x42
; 068F  EB15    JMP  0x06A6
0639  66C7068D06B442EB15  MOV    [0x068D],0x15EB42B4 ; 32-bit code!

0642  5A                  POP    DX             ; Restore drive number SP=0x7BFA
0643  B408                MOV    AH,0x08        ; Read Drive Parameters
0645  CD13                INT    0x13
0647  83E13F              AND    CX,+0x3F       ; Isolate Sectors per Track
064A  51                  PUSH   CX             ; Need this later SP=0x7BF8
064B  0FB6C6              MOVZX  AX,DH          ; Last Head index
064E  40                  INC    AX             ; Number of Heads
064F  F7E1                MUL    CX             ; DX:AX is now Sectors per Cylinder
0651  52                  PUSH   DX             ; SP=0x7BF6
0652  50                  PUSH   AX             ; SP=0x7BF4
0653  6631C0              XOR    EAX,EAX
0656  6699                CDQ                   ; 64-bit zero!
0658  E86600              CALL   0x06C1         ; Get active partition SP=0x7BF2

065B  E82101              CALL   0x077F
065E  DB  "Missing operating system.", 0x0D, 0x0A

; Use Disk Address Packet (DAP) to read VBR - or not (SMC above)!
0679  6660                PUSHAD                ; Push 32-bit everything
067B  6631D2              XOR    EDX,EDX
067E  BB007C              MOV    BX,0x7C00      ; Buffer to read into
0681  6652                PUSH   EDX            ; Address of sector
0683  6650                PUSH   EAX
0685  06                  PUSH   ES             ; Address of buffer
0686  53                  PUSH   BX
0687  6A01                PUSH   +0x01          ; Read one sector
0689  6A10                PUSH   +0x10          ; Size of DAP
068B  89E6                MOV    SI,SP          ; Point to DAP
068D  66F736F47B          DIV    DWORD [0x7BF4] ; Sectors per Cylinder   <- SMC!
0692  C0E406              SHL    AH,0x06        ; High bits of cylinder
0695  88E1                MOV    CL,AH          ; Into LO byte
0697  88C5                MOV    CH,AL          ; Low part into HI byte
0699  92                  XCHG   AX,DX
069A  F636F87B            DIV    BYTE [0x7BF8]  ; Sectors per Track
069E  88C6                MOV    DH,AL          ; Head number
06A0  08E1                OR     CL,AH          ; Or in Sector number
06A2  41                  INC    CX             ; Sectors are 1-based
06A3  B80102              MOV    AX,0x0201      ; Sector read

06A6  8A16FA7B            MOV    DL,[0x7BFA]    ; Get Drive number
06AA  CD13                INT    0x13
06AC  8D6410              LEA    SP,[SI+0x10]   ; POP DAP
06AF  6661                POPAD                 ; Get everything back
06B1  C3                  RET

06B2  E8C4FF              CALL   0x0679         ; Read Sector
06B5  BEBE7D              MOV    SI,0x7DBE      ; Partition Table in sector
06B8  BFBE07              MOV    DI,0x07BE      ; My Partition Table
06BB  B92000              MOV    CX,0x20        ; Size of Partition Table
06BE  F3A5                REP    MOVSW          ; In words
06C0  C3                  RET

06C1  6660                PUSHAD                ; Save everything
06C3  89E5                MOV    BP,SP          ; BP now indexes into registers
06C5  BBBE07              MOV    BX,0x07BE      ; Start of Partition Table
06C8  B90400              MOV    CX,0x0004      ; Number of Partitions
06CB  31C0                XOR    AX,AX          ; Nuber marked Active

06CD  53                  PUSH   BX             ; Save for quick test
06CE  51                  PUSH   CX

06CF  F60780              TEST   [BX],0x80      ; Marked Active?
06D2  7403                JZ     0x06D7         ; No. Keep looking.
06D4  40                  INC    AX             ; Yes. One (more) found
06D5  89DE                MOV    SI,BX          ; This one!
06D7  83C310              ADD    BX,+0x10       ; Look at next Partition
06DA  E2F3                LOOP   0x06CF         ; Keep looking
06DC  48                  DEC    AX             ; CMP AX,1
06DD  745B                JZ     0x073A         ; Only one found. Phew!
06DF  7939                JNS    0x071A         ; More than one found!
06E1  59                  POP    CX             ; None found
06E2  5B                  POP    BX

06E3  8A4704              MOV    AL,[BX+0x04]   ; Get Partition Type
06E6  3C0F                CMP    AL,0x0F        ; Extended LBA Partition?
06E8  7406                JZ     0x06F0         ; Yes. Need to look inside
06EA  247F                AND    AL,0x7F        ; (Linux extended)
06EC  3C05                CMP    AL,0x05        ; Extended CHS partition?
06EE  7522                JNZ    0x0712         ; No.

06F0  668B4708            MOV    EAX,[BX+0x08]  ; Extended Partition Start
06F4  668B5614            MOV    EDX,[BP+0x14]  ; Saved EDX
06F8  6601D0              ADD    EAX,EDX        ; Add in
06FB  6621D2              AND    EDX,EDX        ; Test for zero
06FE  7503                JNZ    0x0703         ; 
0700  6689C2              MOV    EDX,EAX
0703  E8ACFF              CALL   0x06B2         ; Read and copy Partition Table
0706  7203                JC     0x070B         ; Error!
0708  E8B6FF              CALL   0x06C1         ; Recursion!

070B  668B461C            MOV    EAX,[BP+0x1C]  ; Restore saved EAX
070F  E8A0FF              CALL   0x06B2         ; Read and copy Partition Table

0712  83C310              ADD    BX,+0x10       ; Go to next Partition entry
0715  E2CC                LOOP   0x06E3         ; And keep looking
0717  6661                POPAD
0719  C3                  RET

071A  E86200              CALL   0x067F
071D  DB  "Multiple active partitions.", 0x0D, 0x0A

073A  668B4408            MOV    EAX,[SI+0x08]  ; Start sector number
073E  6603461C            ADD    EAX,[BP+0x1C]  ; Add in saved EAX
0742  66894408            MOV    [SI+0x08],EAX  ; Save back
0746  E830FF              CALL   0x0679         ; Read sector
0749  7213                JC     0x075E
074B  813EFE7D55AA        CMP    [0x7DFE],0xAA55 ; Valid boot sector?
0751  0F8506FF            JNZ    0x065B         ; No! "Missing..."

0755  BCFA7B              MOV    SP,0x7BFA      ; Restore back to where we started
0758  5A                  POP    DX
0759  5F                  POP    DI
075A  07                  POP    ES
075B  FA                  CLI
075C  FFE4                JMP    SP             ; JMP to VBR. (I like the technique!)

075E  E81E00              CALL   0x077F
0761  DB  "Operating system load error.", 0x0D, 0x0A

; Print out string.
; This is really cute: they position the string to print directly after the CALL,
; and by never doing a RET they can instead POP the return address as the start
; address of the string. Neat!
; Note it is not an ASCIIZ string - it looks for an LF.
077F  5E                  POP    SI

0780  AC                  LODSB
0781  B40E                MOV    AH,0x0E        ; 
0783  8A3E6204            MOV    BH,[0x0462]    ; Get video page from BDA
0787  B307                MOV    BL,0x07        ; Grey on Black
0789  CD10                INT    0x10
078B  3C0A                CMP    AL,0x0A        ; Wait for LF
078D  75F1                JNZ    0x0780

; Start ROM BIOS
078F  CD18                INT    0x18

; It returned??? HLT repeatedly!
0791  F4                  HLT
0792  EBFD                JMP    0x791

07B8  DD  0xC3072E18    ; Volume signature
07BC  DW  0x0000

07BE  PartEntry  0x80, 0x01, 0x0F0C, 0x0C, 0x0F, 0xDF60, 0x0000_1F80, 0x003B_A080
07CE  PartEntry  0x00, 0x00, 0x0000, 0x00, 0x00, 0x0000, 0x0000_0000, 0x0000_0000
07DE  PartEntry  0x00, 0x00, 0x0000, 0x00, 0x00, 0x0000, 0x0000_0000, 0x0000_0000
07EE  PartEntry  0x00, 0x00, 0x0000, 0x00, 0x00, 0x0000, 0x0000_0000, 0x0000_0000

07FE  DW  0xAA55
