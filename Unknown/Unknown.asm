7C00  EB3E         JMP    0x7C40        ; JMP over BPB
7C02  90           NOP

7C03  296F2D       SUB    [BX+0x2D],BP
7C06  48           DEC    AX
7C07  5D           POP    BP
7C08  49           DEC    CX
7C09  48           DEC    AX
7C0A  43           INC    BX
7C0B  0002         ADD    [BP+SI],AL
7C0D  40           INC    AX
7C0E  1400         ADC    AL,0x0
7C10  0200         ADD    AL,[BX+SI]
7C12  0200         ADD    AL,[BX+SI]
7C14  00F8         ADD    AL,BH
7C16  F6003F       TEST   BYTE [BX+SI],0x3F
7C19  004000       ADD    [BX+SI+0x0],AL
7C1C  0000         ADD    [BX+SI],AL
7C1E  0000         ADD    [BX+SI],AL
7C20  00583D       ADD    [BX+SI+0x3D],BL
7C23  00800029     ADD    [BX+SI+0x2900],AL
7C27  60           PUSHA
7C28  F7F8         IDIV   AX
7C2A  5D           POP    BP
7C2B  4E           DEC    SI
7C2C  4F           DEC    DI
7C2D  204E41       AND    [BP+0x41],CL
7C30  4D           DEC    BP
7C31  45           INC    BP
7C32  2020         AND    [BX+SI],AH
7C34  2020         AND    [BX+SI],AH
7C36  46           INC    SI
7C37  41           INC    CX
7C38  54           PUSH   SP
7C39  31362020     XOR    [0x2020],SI
7C3D  20F1         AND    CL,DH
7C3F  7D

7C40  FA           CLI
7C41  33C9         XOR    CX,CX
7C43  8ED1         MOV    SS,CX
7C45  BCFC7B       MOV    SP,0x7BFC
7C48  16           PUSH   SS
7C49  07           POP    ES
7C4A  BD7800       MOV    BP,0x0078     ; INT 0x1E
7C4D  C57600       LDS    SI,[BP+0x00]
7C50  1E           PUSH   DS
7C51  56           PUSH   SI
7C52  16           PUSH   SS
7C53  55           PUSH   BP

7C54  BF2205       MOV    DI,0x0522
7C57  897E00       MOV    [BP+0x00],DI
7C5A  894E02       MOV    [BP+0x02],CX
7C5D  B10B         MOV    CL,0x0B
7C5F  FC           CLD
7C60  F3A4         REP    MOVSB
7C62  06           PUSH   ES
7C63  1F           POP    DS
7C64  BD007C       MOV    BP,0x7C00
7C67  C645FE0F     MOV    [DI-0x02],0x0F
7C6B  8B4618       MOV    AX,[BP+0x18]
7C6E  8845F9       MOV    [DI-0x07],AL
7C71  FB           STI

7C72  386624       CMP    [BP+0x24],AH
7C75  7C04         JL     0x7B
7C77  CD13         INT    0x13
7C79  723C         JC     0xB7
7C7B  8A4610       MOV    AL,[BP+0x10]
7C7E  98           CBW
7C7F  F76616       MUL    WORD [BP+0x16]
7C82  03461C       ADD    AX,[BP+0x1C]
7C85  13561E       ADC    DX,[BP+0x1E]
7C88  03460E       ADD    AX,[BP+0x0E]
7C8B  13D1         ADC    DX,CX
7C8D  50           PUSH   AX
7C8E  52           PUSH   DX
7C8F  8946FC       MOV    [BP-0x4],AX
7C92  8956FE       MOV    [BP-0x2],DX
7C95  B82000       MOV    AX,0x0020
7C98  8B7611       MOV    SI,[BP+0x11]
7C9B  F7E6         MUL    SI
7C9D  8B5E0B       MOV    BX,[BP+0x0B]
7CA0  03C3         ADD    AX,BX
7CA2  48           DEC    AX
7CA3  F7F3         DIV    BX
7CA5  0146FC       ADD    [BP-0x04],AX
7CA8  114EFE       ADC    [BP-0x02],CX
7CAB  5A           POP    DX
7CAC  58           POP    AX
7CAD  BB0007       MOV    BX,0x0700
7CB0  8BFB         MOV    DI,BX
7CB2  B101         MOV    CL,0x01
7CB4  E89400       CALL   0x7D4B
7CB7  7247         JC     0x7D00
7CB9  382D         CMP    [DI],CH
7CBB  7419         JZ     0xD6
7CBD  B10B         MOV    CL,0xB
7CBF  56           PUSH   SI
7CC0  8B763E       MOV    SI,[BP+0x3E]
7CC3  F3A6         REPE   CMPSB
7CC5  5E           POP    SI
7CC6  744A         JZ     0x7D12
7CC8  4E           DEC    SI
7CC9  740B         JZ     0x7CD6
7CCB  03F9         ADD    DI,CX
7CCD  83C715       ADD    DI,+0x15
7CD0  3BFB         CMP    DI,BX
7CD2  72E5         JC     0xB9
7CD4  EBD7         JMP    0x7CAD
7CD6  2BC9         SUB    CX,CX
7CD8  B8D87D       MOV    AX,0x7DD8
7CDB  87463E       XCHG   AX,[BP+0x3E]
7CDE  3CD8         CMP    AL,0xD8
7CE0  7599         JNZ    0x7C7B

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
7D03  EBE0         JMP    SHORT 0x7CE5  ; Print it out

7D05  33C0         XOR    AX,AX
7D07  CD16         INT    0x16

7D09  5E           POP    SI
7D0A  1F           POP    DS
7D0B  8F04         POP    [SI]
7D0D  8F4402       POP    [SI+0x02]
7D10  CD19         INT    0x19

7D12  BE827D       MOV    SI,0x7D82
7D15  8B7D0F       MOV    DI,[DI+0x0F]
7D18  83FF02       CMP    DI,+0x02
7D1B  72C8         JC     0x7CE5
7D1D  8BC7         MOV    AX,DI
7D1F  48           DEC    AX
7D20  48           DEC    AX
7D21  8A4E0D       MOV    CL,[BP+0x0D]
7D24  F7E1         MUL    CX
7D26  0346FC       ADD    AX,[BP-0x04]
7D29  1356FE       ADC    DX,[BP-0x02]
7D2C  BB0007       MOV    BX,0x0700
7D2F  53           PUSH   BX
7D30  B104         MOV    CL,0x04
7D32  E81600       CALL   0x7D4B
7D35  5B           POP    BX
7D36  72C8         JC     0x7D00
7D38  813F4D5A     CMP    [BX],0x5A4D
7D3C  75A7         JNZ    0x7CE5
7D3E  81BF0002424A CMP    WORD [BX+0x0200],0x4A42
7D44  759F         JNZ    0x7CE5
7D46  EA00027000   JMP    0x0070:0x0200

7D4B  50           PUSH   AX
7D4C  52           PUSH   DX
7D4D  51           PUSH   CX
7D4E  91           XCHG   AX,CX
7D4F  92           XCHG   AX,DX
7D50  33D2         XOR    DX,DX
7D52  F77618       DIV    WORD [BP+0x18]
7D55  91           XCHG   AX,CX
7D56  F77618       DIV    WORD [BP+0x18]
7D59  42           INC    DX
7D5A  87CA         XCHG   CX,DX
7D5C  F7761A       DIV    WORD [BP+0x1A]
7D5F  8AF2         MOV    DH,DL
7D61  8A5624       MOV    DL,[BP+0x24]
7D64  8AE8         MOV    CH,AL
7D66  D0CC         ROR    AH,1
7D68  D0CC         ROR    AH,1
7D6A  0ACC         OR     CL,AH
7D6C  B80102       MOV    AX,0x201
7D6F  CD13         INT    0x13
7D71  59           POP    CX
7D72  5A           POP    DX
7D73  58           POP    AX
7D74  7209         JC     0x17F
7D76  40           INC    AX
7D77  7501         JNZ    0x17A
7D79  42           INC    DX
7D7A  035E0B       ADD    BX,[BP+0xB]
7D7D  E2CC         LOOP   0x14B
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
