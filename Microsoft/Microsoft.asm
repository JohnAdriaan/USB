7C00  EB3C              JMP     0x7C3E
7C02  90                NOP

; BIOS Parameter Block (BPB)
7C03  DB  "MSWIN4.1"
7C0B  DW  0x0200        ; Sector size
7C0D  DB  0x40          ; Sectors per Cluster
7C0E  DW  0x0002        ; Reserved sectors (this one)
7C10  DB  0x02          ; Number of FATs
7C11  DW  0x0200        ; Number of Root Directory Entries
7C13  DW  0x0000        ; Number of Sectors (Word)
7C15  DB  0xF8          ; Media type
7C16  DW  0x00AB        ; Sectors per FAT
7C18  DW  0x003F        ; Sectors per Track
7C1A  DW  0x00FF        ; Number of Heads
7C1C  DD  0x00000000    ; Hidden sectors
7C20  DD  0x002A9800    ; Number of sectors (DWord)
7C24  DB  0x80          ; Physical drive number
7C25  DB  0x00          ; Chkdsk flags
7C26  DB  0x29          ; Extended boot signature
7C27  DD  0x18F951C2    ; Volume serial number
7C2B  DB  "NO NAME    " ; Volume label
7C36  DB  "FAT16   "    ; File system type

; Set up stack
7C3E  FA                CLI
7C3F  33C9              XOR     CX,CX
7C41  8ED1              MOV     SS,CX
7C43  BCFC7B            MOV     SP,0x7BFC

; Get Disk Initialisation Parameter Table
7C46  16                PUSH    SS
7C47  07                POP     ES
7C48  BD7800            MOV     BP,0x0078       ; INT 0x1E
7C4B  C57600            LDS     SI,[BP+0x00]

7C4E  1E                PUSH    DS
7C4F  56                PUSH    SI
7C50  16                PUSH    SS
7C51  55                PUSH    BP

; Replace with this one
7C52  BF2205            MOV     DI,0x522
7C55  897E00            MOV     [BP+0x00],DI
7C58  894E02            MOV     [BP+0x02],CX

7C5B  B10B              MOV     CL,0x0B  ; This many bytes - WRONG! Should be 12
7C5D  FC                CLD
7C5E  F3A4              REP     MOVSB           ; Copy into RAM

7C60  06                PUSH    ES              ; Point back here again
7C61  1F                POP     DS
7C62  BD007C            MOV     BP,0x7C00       ; Point to BPB - sort of

7C65  C645FE0F          MOV     [DI-0x02],0x0F  ; Floppy head bounce delay?
7C69  8B4618            MOV     AX,[BP+0x18]    ; Get Sec/Track from BPB
7C6C  8845F9            MOV     [DI-0x7],AL     ; Store in "Last sector on track"
7C6F  384E24            CMP     [BP+0x24],CL    ; Check Drive nmber (CX is zero)
7C72  7D22              JNL     0x96            ; Floppy?
7C74  8BC1              MOV     AX,CX           ; Zero AX
7C76  99                CWD                     ; Zero DX
7C77  E87701            CALL    0x7DF1          ; Read first sector
7C7A  721A              JC      0x7C96          ; Error!

7C7C  83EB3A            SUB     BX,+0x3A        ; Start sector in read Partition table
7C7F  66A11C7C          MOV     EAX,[0x7C1C]    ; My hidden sectors

7C83  663B07            CMP     EAX,[BX]        ; Same as in Start?
7C86  8A57FC            MOV     DL,[BX-0x04]    ; Partition Type
7C89  7506              JNZ     0x7C91          ; Keep looking
7C8B  80CA02            OR      DL,0x02         ; Partition type + 2
7C8E  885602            MOV     [BP+0x02],DL    ; Save partition type here

7C91  80C310            ADD     BL,0x10         ; Next partition table entry
7C94  73ED              JNC     0x7C83          ; Keep looking until overflow

7C96  33C9              XOR     CX,CX           ; Need a zero
7C98  8A4610            MOV     AL,[BP+0x10]    ; Number of FATs
7C9B  98                CBW                     ; As a Word
7C9C  F76616            MUL     WORD [BP+0x16]  ; Sectors per FAT
7C9F  03461C            ADD     AX,[BP+0x1C]    ; Hidden Sectors
7CA2  13561E            ADC     DX,[BP+0x1E]
7CA5  03460E            ADD     AX,[BP+0x0E]    ; Reserved sectors
7CA8  13D1              ADC     DX,CX           ; CX is zero
7CAA  8B7611            MOV     SI,[BP+0x11]    ; Number of Root Dir Entries

7CAD  60                PUSHA
7CAE  8946FC            MOV     [BP-0x04],AX    ; Save these... somewhere
7CB1  8956FE            MOV     [BP-0x02],DX
7CB4  B82000            MOV     AX,0x0020       ; Size of Dir Entry
7CB7  F7E6              MUL     SI              ; Bytes in Root Dir
7CB9  8B5E0B            MOV     BX,[BP+0x0B]    ; Sector size
7CBC  03C3              ADD     AX,BX           ; Add in
7CBE  48                DEC     AX              ; Round off for part-sectors
7CBF  F7F3              DIV     BX              ; Number of sectors
7CC1  0146FC            ADD     [BP-0x04],AX    ; Now is start of File area
7CC4  114EFE            ADC     [BP-0x02],CX
7CC7  61                POPA

7CC8  BF0007            MOV     DI,0x0700       ; Beginnng of Dir Sector
7CCB  E82301            CALL    0x7DF1          ; Read next Root Dir sector
7CCE  7239              JC      0x7D09          ; Error!

7CD0  382D              CMP     [DI],CH         ; End of directory?
7CD2  7417              JZ      0x7CEB          ; Yes! File not found...
7CD4  60                PUSHA                   ; Save everything
7CD5  B10B              MOV     CL,0x0B         ; Size of file name
7CD7  BED87D            MOV     SI,0x7DD8       ; Point to IO.SYS name
7CDA  F3A6              REPE    CMPSB
7CDC  61                POPA
7CDD  7439              JZ      0x7D18          ; Found?
7CDF  4E                DEC     SI              ; No. One less irectory entry.
7CE0  7409              JZ      0x7CEB          ; Finished?
7CE2  83C720            ADD     DI,+0x20        ; No. Next directory entry
7CE5  3BFB              CMP     DI,BX           ; At end of buffer?
7CE7  72E7              JC      0x7CD0          ; Not yet
7CE9  EBDD              JMP     0x7CC8          ; Read next directory sector

7CEB  BE7F7D            MOV     SI,0x7D7F       ; Point to "Invalid..." - sort of

7CEE  AC                LODSB                   ; Get number of bytes to skip
7CEF  98                CBW                     ; As a Word
7CF0  03F0              ADD     SI,AX           ; Skip them

7CF2  AC                LODSB                   ; Character to print
7CF3  84C0              TEST    AL,AL           ; End of strings?
7CF5  7417              JZ      0x7D0E          ; Yes
7CF7  3CFF              CMP     AL,0xFF         ; End of this string?
7CF9  7409              JZ      0x7D04          ; Yes - now print "Replace..."
7CFB  B40E              MOV     AH,0x0E         ; Print TTY
7CFD  BB0700            MOV     BX,0x0007       ; Grey on black
7D00  CD10              INT     0x10
7D02  EBEE              JMP     0x7CF2          ; Keep going

7D04  BE827D            MOV     SI,0x7D82       ; Point to "Replace..." - sort of
7D07  EBE5              JMP     0x7CEE

7D09  BE807D            MOV     SI,0x7D80       ; Point to "Disk..." - sort of
7D0C  EBE0              JMP     0x7CEE

7D0E  98                CBW                     ; AL is zero, so now so is AX
7D0F  CD16              INT     0x16            ; Wait for keypress
7D11  5E                POP     SI              ; Point to INT 0x1E again
7D12  1F                POP     DS
7D13  668F04            POP     DWORD [SI]      ; Restore Disk Initialisation Table
7D16  CD19              INT     0x19            ; Reboot

; Found entry in root directory!
7D18  BE817D            MOV     SI,0x7D81       ; Point to "Invalid..." - sort of
7D1B  8B7D1A            MOV     DI,[DI+0x1A]    ; Get starting Cluster
7D1E  8D45FE            LEA     AX,[DI-0x02]    ; (Less first two)
7D21  8A4E0D            MOV     CL,[BP+0x0D]    ; Sectors per Cluster
7D24  F7E1              MUL     CX              ; Sector offset
7D26  0346FC            ADD     AX,[BP-0x04]    ; Add in start of file area
7D29  1356FE            ADC     DX,[BP-0x02]
7D2C  B104              MOV     CL,0x04         ; Read four sectors
7D2E  E8C100            CALL    0x7DF2
7D31  72D6              JC      0x7D09          ; Print out "Disk..."
7D33  EA00027000        JMP     0x0070:0x0200   ; Boot MS-DOS!

7D38  B442              MOV     AH,0x42         ; Use Extended Read
7D3A  EB2D              JMP     0x7D69          ; Doesn't need any more work

7D3C  60                PUSHA                   ; Save everything

; Prepare Disk Address Packet (DAP) on stack
7D3D  666A00            PUSH DWORD +0x0         ; Sector Address 3 & 2
7D40  52                PUSH    DX              ; Sector Address 1
7D41  50                PUSH    AX              ; Sector Address 0
7D42  06                PUSH    ES              ; Address of Buffer
7D43  53                PUSH    BX
7D44  6A01              PUSH    +0x01           ; One sector
7D46  6A10              PUSH    +0x10           ; Size of DAP
7D48  8BF4              MOV     SI,SP           ; Point to DAP
7D4A  74EC              JZ      0x7D38          ; Can use Extended Read?

7D4C  91                XCHG    AX,CX           ; Save Sector LO
7D4D  92                XCHG    AX,DX           ; Get Sector HI into AX
7D4E  33D2              XOR     DX,DX           ; Zero 32-bit HI
7D50  F77618            DIV     WORD [BP+0x18]  ; Sectors per Track on HI
7D53  91                XCHG    AX,CX           ; Save result & get Sector LO
7D54  F77618            DIV     WORD [BP+0x18]  ; Sectors per Track on LO
7D57  42                INC     DX              ; Sectors are 1-relative
7D58  87CA              XCHG    CX,DX           ; Get HI back & save remainder 
7D5A  F7761A            DIV     WORD [BP+0x1A]  ; Number of Heads
7D5D  8AF2              MOV     DH,DL           ; Save Head remainder
7D5F  8AE8              MOV     CH,AL           ; Cylinder number
7D61  C0CC02            ROR     AH,0x02         ; High bits into correct place
7D64  0ACC              OR      CL,AH           ; OR in Sector number
7D66  B80102            MOV     AX,0x0201       ; Normal CHS Read

7D69  8A5624            MOV     DL,[BP+0x24]    ; Get drive number
7D6C  CD13              INT     0x13
7D6E  8D6410            LEA     SP,[SI+0x10]    ; Remove DAP
7D71  61                POPA
7D72  720A              JC      0x7D7E          ; Error!
7D74  40                INC     AX              ; Next Sector
7D75  7501              JNZ     0x7D78          ; No wrap (yet)
7D77  42                INC     DX              ; Sector wrap!

7D78  035E0B            ADD     BX,[BP+0x0B]    ; Next Sector's Buffer
7D7B  49                DEC     CX              ; Any more Sectors?
7D7C  7577              JNZ     0x7DF5          ; Yep! So load them

7D7E  C3                RET

7D7F  DB  0x03          ; Skip 3 bytes
7D80  DB  0x18          ; Skip 24 bytes
7D81  DB  0x01          ; Skip 1 byte
7D82  DB  0x27          ; Skip 39 bytes

7D83  DB  13, 10, "Invalid system disk", -1
7D99  DB  13, 10, "Disk I/O error", -1
7DAA  DB  13, 10, "Replace the disk, and then press any key", 13, 10, 0

7DD7  DB  0x00

7DD8  DB  "IO      SYS"
7DE3  DB  "MSDOS   SYS"

7DEE  DB  0x7F
7DEF  DB  0x01
7DF0  DB  0x00

7DF1  41                INC     CX              ; Need another Sector

7DF2  BB0007            MOV     BX,0x0700       ; Buffer for sector

7DF5  807E020E          CMP     [BP+0x02],0x0E  ; Support Extended read?
7DF9  E940FF            JMP     0x7D3C

7DFC  DW  0x0000

7DFE  DW  0xAA55
