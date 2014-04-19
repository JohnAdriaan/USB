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
061B  BEBE07       MOV    SI,0x07BE     ; First partition
061E  B104         MOV    CL,0x04       ; Number of partitions

0620  382C         CMP    [SI],CH       ; CH happens to be 0x00
0622  7C09         JL     0x062D        ; Signed? Hard disk!
0624  7515         JNZ    0x063B        ; Not 0x00? Floppy!
0626  83C610       ADD    SI,+0x10      ; Next partition
0629  E2F5         LOOP   0x0620        ; Keep looking!

; Boot ROM-BASIC instead
062B  CD18         INT    0x18

062D  8B14         MOV    DX,[SI]       ; Use partition entry for drive number
062F  8BEE         MOV    BP,SI         ; Save found boot partition
0631  83C610       ADD    SI,+0x10      ; Keep looking for unique entry
0634  49           DEC    CX
0635  7416         JZ     0x064D        ; Only one!
0637  382C         CMP    [SI],CH       ; Only one?
0639  74F6         JZ     0x0631        ; So far...

063B  BE1007       MOV    SI,0x0710     ; "Invalid..." + 1?

063E  4E           DEC    SI            ; Back one character!

063F  AC           LODSB                ; Get character to display
0640  3C00         CMP    AL,0x00       ; Zero?
0642  74FA         JZ     0x063E        ; Yes, so check it again...
0644  BB0700       MOV    BX,0x0007     ; Grey text on black background
0647  B40E         MOV    AH,0x0E       ; Write character
0649  CD10         INT    0x10

064B  EBF2         JMP    0x063F        ; Next character

064D  894625       MOV    [BP+0x25],AX  ; Store zero... as calculated offset
0650  96           XCHG   AX,SI         ; Zero in SI. AX? About to be lost
0651  8A4604       MOV    AL,[BP+0x04]  ; Partition Entry type
0654  B406         MOV    AH,0x06       ; FAT16 alternate
0656  3C0E         CMP    AL,0x0E       ; FAT16X with LBA?
0658  7411         JZ     0x066B        ; Yes!
065A  B40B         MOV    AH,0x0B       ; FAT32 with CHS alternate
065C  3C0C         CMP    AL,0x0C       ; FAT32X with LBA?
065E  7405         JZ     0x0665        ; Yes.
0660  3AC4         CMP    AL,AH         ; Otherwise... same as alternate?
0662  752B         JNZ    0x068F        ; No! Try normal read
0664  40           INC    AX            ; Next type!
0665  C6462506     MOV    [BP+0x25],0x06; Skip 6 sectors
0669  7524         JNZ    0x068F        ; Do normal reaad

066B  BBAA55       MOV    BX,0x55AA     ; Magic "Extensions present" flag
066E  50           PUSH   AX
066F  B441         MOV    AH,0x41       ; Check if Extensions present
0671  CD13         INT    0x13
0673  58           POP    AX
0674  7216         JC     0x068C        ; Error!
0676  81FB55AA     CMP    BX,0xAA55     ; Valid?
067A  7510         JNZ    0x068C        ; No! Error!
067C  F6C101       TEST   CL,0x01       ; Uses DAP?
067F  740B         JZ     0x068C        ; No! Error!
0681  8AE0         MOV    AH,AL         ; So, this can be alternate too!
0683  885624       MOV    [BP+0x24],DL  ; Save drive number
0686  C706A106EB1E MOV    [0x06A1],0x1EEB ; SELF-MODIFYING CODE! JMP 0x06C1

; Error. Pretend it's alternate
068C  886604       MOV    [BP+0x04],AH

068F  BF0A00       MOV    DI,0x000A     ; Countdown

0692  B80102       MOV    AX,0x0201     ; Read one sector
0695  8BDC         MOV    BX,SP         ; To this address

0697  33C9         XOR    CX,CX         ; Start at zeroeth sector
0699  83FF05       CMP    DI,+0x05      ; Where's the countdown?
069C  7F03         JG     0x06A1        ; Still early on
069E  8B4E25       MOV    CX,[BP+0x25]  ; Use calculated offset instead

06A1  034E02       ADD    CX,[BP+0x02]  ; And add in Partition Entry <- SMC!
06A4  CD13         INT    0x13

06A6  7229         JC     0x06D1        ; Error!

06A8  BE4607       MOV    SI,0x0746     ; "Missing..."
06AB  813EFE7D55AA CMP    [0x7DFE],0xAA55 ; Read sector valid?
06B1  745A         JZ     0x070D        ; Yes!
06B3  83EF05       SUB    DI,+0x05      ; Serious blow to attempts!
06B6  7FDA         JG     0x0692        ; Still more to try...

06B8  85F6         TEST   SI,SI         ; Already found a problem?
06BA  7583         JNZ    0x063F        ; Yes. Display it.
06BC  BE2707       MOV    SI,0x0727     ; "Error..."
06BF  EB8A         JMP    0x064B        ; Display it instead (redirected!)

06C1  98           CBW                  ; AH to zero
06C2  91           XCHG   AX,CX         ; AX=0x0000 or 0x0006. CX=0x0001
06C3  52           PUSH   DX
06C4  99           CWD                  ; DX to zero
06C5  034608       ADD    AX,[BP+0x08]  ; Add in Lo Partition Entry Start
06C8  13560A       ADC    DX,[BP+0x0A]  ; Add in Hi Partition Entry Start
06CB  E81200       CALL   0x06E0        ; Use Extended Read
06CE  5A           POP    DX
06CF  EBD5         JMP    0x06A6        ; Check what happened

06D1  4F           DEC    DI            ; One less attempt
06D2  74E4         JZ     0x06B8        ; Too many!
06D4  33C0         XOR    AX,AX         ; Reset drive
06D6  CD13         INT    0x13
06D8  EBB8         JMP    0x0692        ; And keep trying

06DA  0000         ADD    [BX+SI],AL
06DC  0000         ADD    [BX+SI],AL
06DE  0000         ADD    [BX+SI],AL

06E0  56           PUSH   SI            ; Save this
06E1  33F6         XOR    SI,SI         ; Prepare Disk Address Packet (DAP)
06E3  56           PUSH   SI            ; Sector Address 3
06E4  56           PUSH   SI            ; Sector Address 2
06E5  52           PUSH   DX            ; Sector Address 1
06E6  50           PUSH   AX            ; Sector Address 0
06E7  06           PUSH   ES            ; Read Buffer segment
06E8  53           PUSH   BX            ; Read Buffer offset
06E9  51           PUSH   CX            ; Number of sectors to read
06EA  BE1000       MOV    SI,0x0010
06ED  56           PUSH   SI            ; Size of DAP
06EE  8BF4         MOV    SI,SP         ; Address of DAP
06F0  50           PUSH   AX            ; Save these...
06F1  52           PUSH   DX
06F2  B80042       MOV    AX,0x4200     ; ...for this. Read Extended
06F5  8A5624       MOV    DL,[BP+0x24]  ; Determined drive number
06F8  CD13         INT    0x13
06FA  5A           POP    DX            ; Need Sector Address back
06FB  58           POP    AX
06FC  8D6410       LEA    SP,[SI+0x10]  ; Restore stack from DAP
06FF  720A         JC     0x070B        ; Error! Leave

0701  40           INC    AX            ; One more sector (INC means no carry)
0702  7501         JNZ    0x0705        ; That's OK: Not zero
0704  42           INC    DX            ; Zero! Increase this too
0705  80C702       ADD    BH,0x02       ; Next sector buffer
0708  E2F7         LOOP   0x0701        ; Go back for each sector read

070A  F8           CLC                  ; Clear any possible carry - no error!

070B  5E           POP    SI
070C  C3           RET

070D  EB74         JMP    0x0783        ; Success! Go to new code

070F  DB  "Invalid partition table", 0x00
0727  DB  "Error loading operating system", 0x00
0746  DB  "Missing operating system", 0x00

; Everything's read and validated! Start it!
0783  8BFC         MOV    DI,SP         ; This is beginning of VBR
0785  1E           PUSH   DS            ; Simulate CALL address
0786  57           PUSH   DI
0787  8BF5         MOV    SI,BP         ; Prepare for VBR
0789  CB           RETF                 ; So can RETF instead of JMP FAR

07B8  DD  0x52BF8311       ; Volume signature
07BC  DW  0x0000

07BE  PartEntry  0x80, 0x01, 0x0001, 0x0E, 0x80, 0xCEC4, 0x0000_0004, 0x0007_9FFB
07CE  PartEntry  0x00, 0x00, 0x0000, 0x00, 0x00, 0x0000, 0x0000_0000, 0x0000_0000
07DE  PartEntry  0x00, 0x00, 0x0000, 0x00, 0x00, 0x0000, 0x0000_0000, 0x0000_0000
07EE  PartEntry  0x00, 0x00, 0x0000, 0x00, 0x00, 0x0000, 0x0000_0000, 0x0000_0000

07FD  0055AA       ADD   [DI-0x56],DL
