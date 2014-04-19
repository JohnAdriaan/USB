; First, set up the Segment Registers and Stack
??00  33C0         XOR    AX,AX
??02  8ED0         MOV    SS,AX
??04  BC007C       MOV    SP,0x7C00
??07  FB           STI
??08  50           PUSH   AX
??09  07           POP    ES
??0A  50           PUSH   AX
??0B  1F           POP    DS

; Then, move myself out of the way
??0C  FC           CLD
??0D  BE1B7C       MOV    SI,0x7C1B
??10  BF1B06       MOV    DI,0x061B
??13  50           PUSH   AX
??14  57           PUSH   DI
??15  B9E501       MOV    CX,0x01E5
??18  F3A4         REP    MOVSB
??1A  CB           RETF

; Which Partition is active?
061B  BDBE07       MOV    BP,0x07BE     ; First partition
061E  B104         MOV    CL,0x04       ; Number of partitions

0620  386E00       CMP    [BP+0x00],CH  ; CH happens to be 0x00
0623  7C09         JL     0x062E        ; Signed? Hard disk!
0625  7513         JNZ    0x063A        ; Not 0x00? Floppy!
0627  83C510       ADD    BP,+0x10      ; Next partition
062A  E2F4         LOOP   0x0620        ; Keep looking!

; Boot ROM-BASIC instead
062C  CD18         INT    0x18

062E  8BF5         MOV    SI,BP         ; Save found boot partition
0630  83C610       ADD    SI,+0x10      ; Keep looking for unique entry
0633  49           DEC    CX
0634  7419         JZ     0x064F        ; Only one!
0636  382C         CMP    [SI],CH       ; Only one?
0638  74F6         JZ     0x0630        ; So far...

063A  A0B507       MOV    AL,[0x07B5]   ; Get LO of "Invalid..."

063D  B407         MOV    AH,0x07       ; Get HI of Error message
063F  8BF0         MOV    SI,AX         ; Bug makes this always 0x0700!

0641  AC           LODSB                ; Get character to display
0642  3C00         CMP    AL,0x00
0644  74FC         JZ     0x0642        ; Wait for AL to become non-zero...
0646  BB0700       MOV    BX,0x0007     ; Grey text on black background
0649  B40E         MOV    AH,0x0E       ; Write character
064B  CD10         INT    0x10
064D  EBF2         JMP    0x0641        ; Next character

064F  884E10       MOV    [BP+0x10],CL  ; Zero counter of attempts
0652  E84600       CALL   0x069B        ; Call Read function
0655  732A         JNC    0x0681        ; It worked!

0657  FE4610       INC BYTE [BP+0x10]   ; Mark that we tried this
065A  807E040B     CMP    [BP+0x4],0x0B ; Is FAT32 CHS partition?
065E  740B         JZ     0x066B        ; Yep! Try next block
0660  807E040C     CMP    [BP+0x4],0x0C ; Is FAT32X LBA partition?
0664  7405         JZ     0x066B        ; Yep! Try next block
0666  A0B607       MOV    AL,[0x07B6]   ; Get LO of "Error..."
0669  75D2         JNZ    0x063D

; Try next block
066B  80460206     ADD    [BP+0x02],0x06  ; Try 6th sector along
066F  83460806     ADD    [BP+0x08],+0x06 ; Which means we need to fix Start
0673  83560A00     ADC    [BP+0x0A],+0x00 ; (with carry?)
0677  E82100       CALL   0x069B        ; And try again
067A  7305         JNC    0x0681        ; This worked!
067C  A0B607       MOV    AL,[0x07B6]   ; Get LO of "Error..."
067F  EBBC         JMP    0x063D

; Succesful read
0681  813EFE7D55AA CMP    [0x7DFE],0xAA55 ; BIOS Signature?
0687  740B         JZ     0x0694          ; Yep!
0689  807E1000     CMP    [BP+0x10],0x00  ; No. Tried already?
068D  74C8         JZ     0x0657          ; Not yet!

068F  A0B707       MOV    AL,[0x07B7]     ; Get LO of "Missing..."
0692  EBA9         JMP    0x063D

; Everything's read and validated! Start it!
0694  8BFC         MOV    DI,SP         ; This is beginning of VBR
0696  1E           PUSH   DS            ; Simulate CALL address
0697  57           PUSH   DI
0698  8BF5         MOV    SI,BP         ; Prepare for VBR
069A  CB           RETF                 ; So can RETF instead of JMP FAR

; Try to read Volume Boot Reord
069B  BF0500       MOV    DI,0x0005     ; Number of attempts

069E  8A5600       MOV    DL,[BP+0x00]  ; Drive to access
06A1  B408         MOV    AH,0x08       ; Get drive parameters
06A3  CD13         INT    0x13
06A5  7223         JC     0x06CA        ; Uh oh!

06A7  8AC1         MOV    AL,CL
06A9  243F         AND    AL,0x3F       ; Isolate number sectors
06AB  98           CBW                  ; As a WORD
06AC  8ADE         MOV    BL,DH         ; Max head index
06AE  8AFC         MOV    BH,AH         ; AH 'should' be zero
06B0  43           INC    BX            ; Add one for number heads
06B1  F7E3         MUL    BX            ; DX:AX now heads * Sectors
06B3  8BD1         MOV    DX,CX         ; Assumes < 65,536 !
06B5  86D6         XCHG   DL,DH         ; Now get cylinders
06B7  B106         MOV    CL,0x06       ; Shift factor
06B9  D2EE         SHR    DH,CL         ; DX is now max cylinder index
06BB  42           INC    DX            ; Number of cylinders
06BC  F7E2         MUL    DX            ; DX:AX now sector number
06BE  39560A       CMP    [BP+0x0A],DX  ; Compare HI with Partition
06C1  7723         JA     0x06E6        ; Bigger? Go ahead with read
06C3  7205         JC     0x06CA        ; Too small? Error!
06C5  394608       CMP    [BP+0x08],AX  ; Compare LO with Partition
06C8  731C         JNC    0x06E6        ; Not smaller? Go ahead with read

; Error! But goes ahead with read attampt anyway...
06CA  EB1A         JMP    0x06E6

06CC  90           NOP
06CD  BB007C       MOV    BX,0x7C00     ; Buffer for read
06D0  8B4E02       MOV    CX,[BP+0x02]  ; Partition Cylinder/Sector
06D3  8B5600       MOV    DX,[BP+0x00]  ; Partition Drive/Head
06D6  CD13         INT    0x13
06D8  7351         JNC    0x072B        ; It worked!

06DA  4F           DEC    DI            ; One less attempt
06DB  744E         JZ     0x072B        ; Too many!

; Error on read. Retry after reset (although why bother on a USB stick?)
06DD  32E4         XOR    AH,AH         ; Reset drive
06DF  8A5600       MOV    DL,[BP+0x00]  ; (This one!)
06E2  CD13         INT    0x13
06E4  EBE4         JMP    0x06CA        ; Go back for more
                                        ; Bizarre! It JMPs to... here!

06E6  8A5600       MOV    DL,[BP+0x00]  ; Drive to read
06E9  60           PUSHA                ; Save everything
06EA  BBAA55       MOV    BX,0x55AA     ; Magic "Extensions present" flag
06ED  B441         MOV    AH,0x41       ; Check if Extensions present
06EF  CD13         INT    0x13
06F1  7236         JC     0x0729        ; Error!
06F3  81FB55AA     CMP    BX,0xAA55     ; Valid?
06F7  7530         JNZ    0x0729        ; No! Error!
06F9  F6C101       TEST   CL,0x01       ; Uses DAP?
06FC  742B         JZ     0x0729        ; No! Error!
06FE  61           POPA                 ; Restore everything

06FF  60           PUSHA                ; Save everything

; Now create a Disk Address Packet (DAP)
0700  6A00         PUSH   +0x00         ; Sector Address 3
0702  6A00         PUSH   +0x00         ; Sector Address 2
0704  FF760A       PUSH   [BP+0x0A]     ; Sector Address 1
0707  FF7608       PUSH   [BP+0x08]     ; Sector Address 0
070A  6A00         PUSH   +0x0          ; Segment of buffer
070C  68007C       PUSH   0x7C00        ; Offset of buffer
070F  6A01         PUSH   +0x1          ; Only one sector
0711  6A10         PUSH   +0x10         ; Size of DAP

0713  B442         MOV    AH,0x42       ; Extended Disk Read
0715  8BF4         MOV    SI,SP         ; Disk Address Packet
0717  CD13         INT    0x13

0719  61           POPA                 ; "Repair" stack (ADD SP,16 without C Flag)

071A  61           POPA                 ; Restore everything
071B  730E         JNC    0x072B        ; No error?
071D  4F           DEC    DI            ; One less attempt
071E  740B         JZ     0x072B        ; Too many!

; Error on read. Retry after reset (although why bother on a USB stick?)
0720  32E4         XOR    AH,AH
0722  8A5600       MOV    DL,[BP+0x00]  ; (This one!)
0725  CD13         INT    0x13
0727  EBD6         JMP    0x06FF        ; Go back for more

; Using Extensions failed.
0729  61           POPA                 ; Restore everything
072A  F9           STC                  ; But it did fail

; It either worked or it didn't. Leave.
072B  C3           RET

072C  DB  "Invalid partition table", 0x00
0744  DB  "Error loading operating system", 0x00
0763  DB  "Missing operating system", 0x00

; These next three bytes are SUPPOSED to be the LO offset for the above strings
07B5  DB  0x00             ; LO for "Invalid..."
07B6  DW  0x00             ; LO for "Error..."
07B7  DW  0x00             ; LO for "Missing..."

07B8  DD  0x1AEAF2B4       ; Volume signature
07BC  DW  0x0000

07BE  PartEntry  0x80, 0x01, 0x0001, 0x0E, 0xFE, 0x0E3F, 0x0000_003F, 0x0003_D041
07CE  PartEntry  0x00, 0x00, 0x0000, 0x00, 0x00, 0x0000, 0x0000_0000, 0x0000_0000
07DE  PartEntry  0x00, 0x00, 0x0000, 0x00, 0x00, 0x0000, 0x0000_0000, 0x0000_0000
07EE  PartEntry  0x00, 0x00, 0x0000, 0x00, 0x00, 0x0000, 0x0000_0000, 0x0000_0000

07FE  DW  0xAA55
