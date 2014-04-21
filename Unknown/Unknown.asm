7C00  EB3E         JMP    0x7C40        ; JMP over BPB
7C02  90           NOP

7C03  DB           ")o-H]IHC"           ; Indicator (e.g. "MSDOS5.0")

7C0B  DW           0x0200               ; Bytes per sector
7C0D  DB           0x40                 ; Sectors per cluster
7C0E  DW           0x0014               ; Reserved sectors (these ones)
7C10  DB           0x02                 ; Number of FATs
7C11  DW           0x0200               ; Number of Root Dir Entries
7C13  DW           0x0000               ; Number of Sectors (Word)
7C15  DB           0xF8                 ; Media type
7C16  DW           0x00F6               ; Sectors per FAT
7C18  DW           0x003F               ; Sectors per Track
7C1A  DW           0x0040               ; Number of Heads
7C1C  DD           0x00000000           ; Hiddens sectors
7C20  DD           0x003D5800           ; Number of Sectors (DWord)

7C24  DB           0x80                 ; Drive number
7C25  DB           0x00                 ; Chkdsk flags
7C26  DB           0x29                 ; Extended boot signature
7C27  DD           0x4E5DF8F7           ; Volume serial number
7C2B  DB           "NO NAME    "        ; Volume label
7C36  DB           "FAT16   "           ; File System type

7C3E  DW           0x7DF1               ; Pointer to "WINBOOT SYS"

; Set up stack
7C40  FA           CLI
7C41  33C9         XOR    CX,CX
7C43  8ED1         MOV    SS,CX
7C45  BCFC7B       MOV    SP,0x7BFC

; Get Disk Initialisation Parameter Table
7C48  16           PUSH   SS
7C49  07           POP    ES
7C4A  BD7800       MOV    BP,0x0078     ; INT 0x1E
7C4D  C57600       LDS    SI,[BP+0x00]

7C50  1E           PUSH   DS
7C51  56           PUSH   SI
7C52  16           PUSH   SS
7C53  55           PUSH   BP

; Replace with this one
7C54  BF2205       MOV    DI,0x0522
7C57  897E00       MOV    [BP+0x00],DI
7C5A  894E02       MOV    [BP+0x02],CX

7C5D  B10B         MOV    CL,0x0B       ; This many bytes - WRONG! Should be 12
7C5F  FC           CLD
7C60  F3A4         REP    MOVSB         ; Copy into RAM

7C62  06           PUSH   ES            ; Point back here again
7C63  1F           POP    DS
7C64  BD007C       MOV    BP,0x7C00

7C67  C645FE0F     MOV    [DI-0x02],0x0F; Floppy head bounce delay?
7C6B  8B4618       MOV    AX,[BP+0x18]  ; Get Sec/Track from BPB
7C6E  8845F9       MOV    [DI-0x07],AL  ; Store in "Last sector on track"
7C71  FB           STI

7C72  386624       CMP    [BP+0x24],AH  ; Check drive number
7C75  7C04         JL     0x7C7B        ; Floppy?

7C77  CD13         INT    0x13          ; No
7C79  723C         JC     0x7CB7        ; Error!

7C7B  8A4610       MOV    AL,[BP+0x10]  ; Number of FATs
7C7E  98           CBW                  ; As a DWord
7C7F  F76616       MUL    WORD [BP+0x16]; Sectors per FAT
7C82  03461C       ADD    AX,[BP+0x1C]  ; Add in Hidden Sectors (DWord)
7C85  13561E       ADC    DX,[BP+0x1E]  ; BUG! DX is not (necesarily) zero
7C88  03460E       ADD    AX,[BP+0x0E]  ; Add in Reserved Sectors
7C8B  13D1         ADC    DX,CX         ; CX is zero
7C8D  50           PUSH   AX            ; Save Root Directory sector number
7C8E  52           PUSH   DX
7C8F  8946FC       MOV    [BP-0x4],AX   ; Save... somewhere unneeded
7C92  8956FE       MOV    [BP-0x2],DX
7C95  B82000       MOV    AX,0x0020     ; Size of Directory Entry
7C98  8B7611       MOV    SI,[BP+0x11]  ; Number of root directory entries
7C9B  F7E6         MUL    SI            ; DX:AX is now end of Root Directory
7C9D  8B5E0B       MOV    BX,[BP+0x0B]  ; Bytes per Sector
7CA0  03C3         ADD    AX,BX         ; Add in maximum (BUG! should carry to DX)
7CA2  48           DEC    AX            ; Less one (BUG! Should carry to DX)
7CA3  F7F3         DIV    BX            ; Re-divide (to get sector past Root Dir)
7CA5  0146FC       ADD    [BP-0x04],AX  ; Add this in to saved value
7CA8  114EFE       ADC    [BP-0x02],CX  ; CX is still zero
7CAB  5A           POP    DX            ; Restore Root Directory pointer
7CAC  58           POP    AX

7CAD  BB0007       MOV    BX,0x0700     ; Buffer
7CB0  8BFB         MOV    DI,BX
7CB2  B101         MOV    CL,0x01       ; One sector
7CB4  E89400       CALL   0x7D4B        ; Read first root directory sector

7CB7  7247         JC     0x7D00        ; Error!

7CB9  382D         CMP    [DI],CH       ; First byte zero?
7CBB  7419         JZ     0x7CD6        ; Yes. End of directory
7CBD  B10B         MOV    CL,0x0B       ; Size of name
7CBF  56           PUSH   SI            ; Save root directory entry count
7CC0  8B763E       MOV    SI,[BP+0x3E]  ; Get pointer to current search name
7CC3  F3A6         REPE   CMPSB         ; Found?
7CC5  5E           POP    SI            ; (Restore root directory entry count)
7CC6  744A         JZ     0x7D12        ; Yes!
7CC8  4E           DEC    SI            ; One less root directory entry
7CC9  740B         JZ     0x7CD6        ; None left? Look for IO.SYS
7CCB  03F9         ADD    DI,CX         ; Add in rest of name
7CCD  83C715       ADD    DI,+0x15      ; Add in rest of Directory Entry
7CD0  3BFB         CMP    DI,BX         ; Past end of read buffer?
7CD2  72E5         JB     0x7CB9        ; Not yet...
7CD4  EBD7         JMP    0x7CAD        ; Go back and read some more!

7CD6  2BC9         SUB    CX,CX         ; Zero CX again
7CD8  B8D87D       MOV    AX,0x7DD8     ; Point to IO.SYS instead
7CDB  87463E       XCHG   AX,[BP+0x3E]
7CDE  3CD8         CMP    AL,0xD8       ; Already tried it?
7CE0  7599         JNZ    0x7C7B        ; No: start all over again

7CE2  BE807D       MOV    SI,0x7D80     ; "Invalid..." - sort of!

7CE5  AC           LODSB                ; Get lead byte
7CE6  98           CBW                  ; As an offset
7CE7  03F0         ADD    SI,AX         ; Start character

7CE9  AC           LODSB                ; Get next character
7CEA  84C0         TEST   AL,AL         ; Zero?
7CEC  7417         JZ     0x7D05        ; Yes. Wait for key
7CEE  3CFF         CMP    AL,-1         ; -1?
7CF0  7409         JZ     0x7CFB        ; Yes. Print "Press..."

7CF2  B40E         MOV    AH,0x0E       ; Write teletype
7CF4  BB0700       MOV    BX,0x0007     ; Grey on black
7CF7  CD10         INT    0x10
7CF9  EBEE         JMP    0x7CE9        ; Go back for more

7CFB  BE837D       MOV    SI,0x7D83     ; "Press..." - sort of!
7CFE  EBE5         JMP    0x7CE5        ; Print it out

7D00  BE817D       MOV    SI,0x7D81     ; "Disk..." - sort of!
7D03  EBE0         JMP    0x7CE5        ; Print it out

7D05  33C0         XOR    AX,AX         ; Wait for keypress
7D07  CD16         INT    0x16

7D09  5E           POP    SI            ; Restore everything
7D0A  1F           POP    DS
7D0B  8F04         POP    [SI]
7D0D  8F4402       POP    [SI+0x02]
7D10  CD19         INT    0x19          ; Restart boot process

7D12  BE827D       MOV    SI,0x7D82     ; "Invalid..." - sort of!
7D15  8B7D0F       MOV    DI,[DI+0x0F]  ; Get Starting cluster
7D18  83FF02       CMP    DI,+0x02
7D1B  72C8         JC     0x7CE5        ; Below valid? Error!
7D1D  8BC7         MOV    AX,DI         ; Get Starting cluster
7D1F  48           DEC    AX            ; Ignoring special sectors
7D20  48           DEC    AX
7D21  8A4E0D       MOV    CL,[BP+0x0D]  ; Sectors per cluster
7D24  F7E1         MUL    CX            ; (CH still zero) AX is now start of file
7D26  0346FC       ADD    AX,[BP-0x04]  ; Add in offset past root directory entry
7D29  1356FE       ADC    DX,[BP-0x02]
7D2C  BB0007       MOV    BX,0x0700     ; Buffer
7D2F  53           PUSH   BX
7D30  B104         MOV    CL,0x04       ; This should be big enough!
7D32  E81600       CALL   0x7D4B        ; Read file
7D35  5B           POP    BX
7D36  72C8         JC     0x7D00        ; Error!
7D38  813F4D5A     CMP    [BX],0x5A4D   ; "MZ" Signature?
7D3C  75A7         JNZ    0x7CE5        ; No! Print Error
7D3E  81BF0002424A CMP    [BX+0x0200],0x4A42 ; "BJ" Signature?
7D44  759F         JNZ    0x7CE5        ; No! Print Error
7D46  EA00027000   JMP    0x0070:0x0200 ; Start MS-DOS

7D4B  50           PUSH   AX            ; Sector LO
7D4C  52           PUSH   DX            ; Sector HI
7D4D  51           PUSH   CX            ; Number sectors
7D4E  91           XCHG   AX,CX
7D4F  92           XCHG   AX,DX         ; AX:CX = Sector, DX = number
7D50  33D2         XOR    DX,DX         ; Zero DX
7D52  F77618       DIV    WORD [BP+0x18]; Divide by Sectors per Track
7D55  91           XCHG   AX,CX         ; Remember result in CX
7D56  F77618       DIV    WORD [BP+0x18]; Divide by Sectors per Track
7D59  42           INC    DX            ; DX is (was) remainder
7D5A  87CA         XCHG   CX,DX
7D5C  F7761A       DIV    WORD [BP+0x1A]; Divide by number of Heads
7D5F  8AF2         MOV    DH,DL         ; Put remainder in DH
7D61  8A5624       MOV    DL,[BP+0x24]  ; Restore drive number
7D64  8AE8         MOV    CH,AL         ; Cylinder number
7D66  D0CC         ROR    AH,1          ; Rest of cylinder number
7D68  D0CC         ROR    AH,1
7D6A  0ACC         OR     CL,AH         ; OR into Sector number
7D6C  B80102       MOV    AX,0x0201     ; Read one sector
7D6F  CD13         INT    0x13
7D71  59           POP    CX            ; Restore input parameters
7D72  5A           POP    DX
7D73  58           POP    AX
7D74  7209         JC     0x7D7F        ; Error!
7D76  40           INC    AX            ; Next sector LO
7D77  7501         JNZ    0x17A         ; Keep going...
7D79  42           INC    DX            ; Next Sector HI

7D7A  035E0B       ADD    BX,[BP+0x0B]  ; Add Sector size to Buffer
7D7D  E2CC         LOOP   0x14B         ; Keep reading...

7D7F  C3           RET

7D80  DB           0x03                 ; Skip next 3 bytes
7D81  DB           0x18                 ; Skip next 24 bytes
7D82  DB           0x01                 ; Skip next byte
7D83  DB           0x27                 ; Skip next 39 bytes

7D84  DB           13, 10, "Invalid system disk", -1
7D9A  DB           13, 10, "Disk I/O error", -1
7DAB  DB           13, 10, "Replace the disk, and then press any key", 13, 10, 0

7DD8  DB           "IO      SYS"
7DE3  DB           "MSDOS   SYS"

7DEE  DB           0x80
7DEF  DB           0x01
7DF0  DB           0x00

7DF1  DB           "WINBOOT SYS"

7DFC  DW           0x0000

7DFE  DW           0xAA55
