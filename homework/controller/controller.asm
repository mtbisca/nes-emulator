;----------------------------------------------------------------
; constants
;----------------------------------------------------------------

PRG_COUNT = 1 ;1 = 16KB, 2 = 32KB
MIRRORING = %0001 ;%0000 = horizontal, %0001 = vertical, %1000 = four-screen



;----------------------------------------------------------------
; variables
;----------------------------------------------------------------

   .enum $0000

   ;NOTE: declare variables using the DSB and DSW directives, like this:

   ;MyVariable0 .dsb 1
   ;MyVariable1 .dsb 3

   .ende

   ;NOTE: you can also split the variable declarations into individual pages, like this:

   ;.enum $0100
   ;.ende

   ;.enum $0200
   ;.ende

;----------------------------------------------------------------
; iNES header
;----------------------------------------------------------------

   .db "NES", $1a ;identification of the iNES header
   .db PRG_COUNT ;number of 16KB PRG-ROM pages
   .db $01 ;number of 8KB CHR-ROM pages
   .db $00|MIRRORING ;mapper 0 and mirroring
   .dsb 9, $00 ;clear the remaining bytes

;----------------------------------------------------------------
; program bank(s)
;----------------------------------------------------------------

   .base $10000-(PRG_COUNT*$4000)

.org $C000 
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0200, x    ;move all sprites off screen
  INX
  BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2


LoadPalettes:
  LDA $2002    ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006    ; write the high byte of $3F00 address
  LDA #$00
  STA $2006    ; write the low byte of $3F00 address
  LDX #$00
LoadPalettesLoop:
  LDA palette, x        ;load palette byte
  STA $2007             ;write to PPU
  INX                   ;set index to next byte
  CPX #$20            
  BNE LoadPalettesLoop  ;if x = $20, 32 bytes copied, all done



LoadSprites:
  LDX #$00              ; start at 0
LoadSpritesLoop:
  LDA sprites, x        ; load data from address (sprites +  x)
  STA $0200, x          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $20, decimal 32
  BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down

  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0
  STA $2000

  LDA #%00010000   ; enable sprites
  STA $2001

  LDA #$03
  STA $301

Forever: 
   JMP Forever     ;jump back to Forever, infinite loop

NMI:

  LDA #$00
  STA $2003  ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014  ; set the high byte (02) of the RAM address, start the transfer

LatchController:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016       ; tell both the controllers to latch buttons

  LDA $4016       ; player 1 - A
  LDA $4016       ; player 1 - B
  LDA $4016     ; player 1 - Select
  LDA $4016     ; player 1 - Start

ReadUP:
  LDA $4016     ; player 1 - UP
  AND #%00000001  ; erase everything but bit 0
  BEQ ReadUPDone   ; branch to ReadUPDone if button is NOT pressed (0)
  LDA $0200   ; load sprite position
  CMP #$07    ; end of up side
  BEQ ReadUPDone ; branch to ReadUPDone if position is end of up side
  LDX #$00
  LDA #$10
  STA $0302
  JSR MoveRestLow
ReadUPDone:

ReadDown:
  LDA $4016     ; player 1 - Down
  AND #%00000001  ; erase everything but bit 0
  BEQ ReadDownDone   ; branch to ReadADone if button is NOT pressed (0)
  LDA $0200   ; load sprite position
  CMP #$D7    ; end of down side
  BEQ ReadDownDone ; branch to ReadADone if position is end of down side
  LDX #$00
  LDA #$10
  STA $0302
  JSR MoveRestPlus
  
ReadDownDone:

ReadLeft:
  LDA $4016     ; player 1 - Left
  AND #%00000001  ; erase everything but bit 0
  BEQ ReadLeftDone   ; branch to ReadADone if button is NOT pressed (0)
  LDA $0301
  CMP #$03
  BEQ LeftContiue
  LDA #03
  STA $0201 ; reset tile 1
  LDA #%00000000
  STA $0202
  LDA #08
  STA $0205 ; reset tile 2
  LDA #%00000000
  STA $0206
  LDA #14
  STA $0209 ; reset tile 3
  LDA #%00000000
  STA $020A
  LDA #19
  STA $020D ; reset tile 4
  LDA #%00000000
  STA $020E
  LDA #$03
  STA $0301
LeftContiue:
  LDA $0203
  CMP #$07    ; end of left side
  BEQ ReadLeftDone ; branch to ReadADone if position is end of left side
  LDX #$03
  LDA #$13
  STA $0302
  JSR MoveRestLow
  JSR animationRoutineL
ReadLeftDone:

ReadRigth:
  LDA $4016     ; player 1 - Right
  AND #%00000001  ; erase everything but bit 0
  BEQ ReadRigthDone   ; branch to ReadADone if button is NOT pressed (0)
  LDA $0301
  CMP #$01
  BEQ RigthContiue
  LDA #08
  STA $0201 ; reset tile 1
  LDA #%01000000
  STA $0202
  LDA #03
  STA $0205 ; reset tile 2
  LDA #%01000000
  STA $0206
  LDA #19
  STA $0209 ; reset tile 3
  LDA #%01000000
  STA $020A
  LDA #14
  STA $020D ; reset tile 4
  LDA #%01000000
  STA $020E
  LDA #$01
  STA $0301
RigthContiue:
  LDA $0203   ; load sprite position
  CMP #$F1    ; end of rigth side
  BEQ ReadRigthDone ; branch to ReadADone if position is end of rigth side
  LDX #$03
  LDA #$13
  STA $0302
  JSR MoveRestPlus
  JSR animationRoutineR
ReadRigthDone:


  
  RTI        ; return from interrupt

MoveRestPlus:
  LDA $0200, X
  CLC
  ADC #$01     ; A = A + 1
  STA $0200, X
  TXA 
  CLC
  ADC #$04
  TAX
  CMP $0302
  BNE MoveRestPlus
RTS

MoveRestLow:
  LDA $0200, X
  SEC
  SBC #$01     ; A = A - 1
  STA $0200, X
  TXA 
  CLC
  ADC #$04
  TAX
  CMP $0302
  BNE MoveRestLow
RTS

animationRoutineR:
  LDA $0300
  CMP #$0F
  BEQ addifR
  CMP #$1F
  BEQ subifR
  JMP doneifR
addifR:
  JSR addR
  JMP doneifR
subifR:
  JSR subR
  JMP doneifR
doneifR:
  LDA $0300
  ADC #$01
  AND #%00011111
  STA $0300
  RTS

addR:
  LDA #08
  STA $201
  LDA #03
  STA $0205
  LDA #19
  STA $0209
  LDA #14
  STA $020D
  RTS

subR:
  LDA #09
  STA $201
  LDA #04
  STA $0205
  LDA #20
  STA $0209
  LDA #15
  STA $020D
  RTS

animationRoutineL:
  LDA $0300
  CMP #$0F
  BEQ addifL
  CMP #$1F
  BEQ subifL
  JMP doneifL
addifL:
  JSR addL
  JMP doneifL
subifL:
  JSR subL
  JMP doneifL
doneifL:
  LDA $0300
  ADC #$01
  AND #%00011111
  STA $0300
  RTS
addL:
  LDA #03
  STA $0201
  LDA #08
  STA $0205
  LDA #14
  STA $0209
  LDA #19
  STA $020D
  RTS
subL:
  LDA #04
  STA $201
  LDA #09
  STA $0205
  LDA #15
  STA $0209
  LDA #20
  STA $020D
  RTS

animationRoutine2M:
  LDA #$01
  STA $0005
  LDA #$02
  STA $0006
  LDY #$00
  LDA $0300
  AND #%00010000
  BEQ continue2M
  LDX #$03
  JSR animationPace
  JMP animationEnd
continue2M:
  LDX #$04
  JSR animationPace
animationEnd:
  LDA $0300
  ADC #$01
  AND #%00011111
  STA $0300
RTS

animationPace:
  TXA
  STA ($05), Y
  ADC #$05
  TAX 
  TYA
  ADC #04
  TAY
  CMP #20
  BNE animationPace
RTS

flipDino:
  LDX $0201
  LDY $0205
  STY $0201
  STX $0205
  LDX $0201
  LDY $0202
  STY $0201
  STX $0202

IRQ:

   ;NOTE: IRQ code goes here

;----------------------------------------------------------------
; interrupt vectors
;----------------------------------------------------------------

.org $E000
; palette:
;   .db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
;   .db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C

palette: 
.db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
.byte $15,$0B,$30,$0A

sprites:
     ;vert tile attr horiz
  .db $80, $03, $00, $80   ;sprite 0
  .db $80, $08, $00, $88   ;sprite 1
  .db $88, $0E, $00, $80   ;sprite 2
  .db $88, $13, $00, $88   ;sprite 3


   .org $fffa

   .dw NMI
   .dw RESET
   .dw IRQ

;----------------------------------------------------------------
; CHR-ROM bank
;----------------------------------------------------------------

.incbin "dino8_2.chr"
