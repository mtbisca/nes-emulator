.inesprg 1   ; 1x 16KB PRG code
.ineschr 0   ; 1x  8KB CHR data
.inesmap 0   ; mapper 0 = NROM, no bank swapping
.inesmir 1   ; background mirroring


;;;;;;;;;;;;;;;

;; VARIABLES
.enum $0000 ;start variables at ram location 0

playerX         .dsw 1
playerY         .dsw 1
playerLeft      .dsw 1
playerRight     .dsw 1
playerTop       .dsw 1
playerBottom    .dsw 1
carLeft         .dsw 1
carRight        .dsw 1
carTop          .dsw 1
carBottom       .dsw 1
carFirstSpriteX .dsw 1
carFirstSpriteY .dsw 1
buttons         .dsw 1

.ende


PAD_A      = %10000000
PAD_B      = %01000000
PAD_SELECT = %00100000
PAD_START  = %00010000
PAD_UP     = %00001000
PAD_DOWN   = %00000100
PAD_LEFT   = %00000010
PAD_RIGHT  = %00000001

RIGHTWALL      = $F1  ; when player reaches one of these, do something
TOPWALL        = $0A
BOTTOMWALL     = $DC
LEFTWALL       = $08

PLAYER_FIRST_SPRITE_Y  EQU $0200
PLAYER_FIRST_SPRITE_X  EQU $0203

CAR_SPRITES_BASE_ADDR EQU $0210

CAR_LEFT_OFFSET EQU     $04
CAR_RIGHT_OFFSET EQU    $1C
CAR_TOP_OFFSET EQU      $04
CAR_BOTTOM_OFFSET EQU   $0C


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
  STA $0200, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0300, x
  INX
  BNE clrmem

vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2


LoadPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address
  LDX #$00              ; start out at 0
LoadPalettesLoop:
  LDA palette, x        ; load data from address (palette + the value in x)
                        ; 1st time through loop it will load palette+0
                        ; 2nd time through loop it will load palette+1
                        ; 3rd time through loop it will load palette+2
                        ; etc
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $10, decimal 16 - copying 16 bytes = 4 sprites
  BNE LoadPalettesLoop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                      ; if compare was equal to 32, keep going down



LoadSprites:
  LDX #$00              ; start at 0
LoadSpritesLoop:
  LDA sprites, x        ; load data from address (sprites +  x)
  STA $0200, x          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  CPX #$40              ; Compare X to hex $20, decimal 32
  BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                      ; if compare was equal to 32, keep going down


;;Set initial stats
  LDA #$84
  STA playerX

  LDA #$8C
  STA playerRight

  LDA #$7C
  STA playerLeft

  LDA #$84
  STA playerY

  LDA #$8C
  STA playerBottom

  LDA #$7C
  STA playerTop

  LDA #$50
  STA carFirstSpriteX

  LDA #$6C
  STA carRight

  LDA #$4C
  STA carLeft

  LDA #$50
  STA carFirstSpriteY

  LDA #$5C
  STA carBottom

  LDA #$4C
  STA carTop


  LDA #%10000000   ; enable NMI, sprites from Pattern Table 1
  STA $2000

  LDA #%00010000   ; enable sprites
  STA $2001

Forever:
  JMP Forever     ;jump back to Forever, infinite loop



NMI:
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer

ReadController:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016       ; tell both the controllers to latch buttons
  LDX #$08
ReadControllerLoop:
  LDA $4016
  LSR A            ; bit0 -> Carry
  ROL buttons     ; bit0 <- Carry
  DEX
  BNE ReadControllerLoop

ReadUp:
  LDA buttons
  AND #%00001000
  BEQ ReadUpDone
  LDX #$00
MoveUpLoop:
  LDA PLAYER_FIRST_SPRITE_Y, x
  CMP #TOPWALL
  BEQ ReadUpDone
  SEC
  SBC #$01        ;;bally position = bally - ballspeedy
  STA PLAYER_FIRST_SPRITE_Y, x
  TXA           ; transfer value of register x to a
  CLC           ; make sure the carry flag is clear
  ADC #$04      ; add 04 to register x
  TAX           ; transfer value of register a to x
  CPX #$10      ; check if x = 10, i.e, 4 sprites have been moved
  BNE MoveUpLoop
ReadUpDone:

ReadDown:
  LDA buttons
  AND #%00000100
  BEQ ReadDownDone
  LDX #$00
MoveDownLoop:
  LDA PLAYER_FIRST_SPRITE_Y, x
  CMP #BOTTOMWALL
  BEQ ReadDownDone
  CLC
  ADC #$01        ;;bally position = bally - ballspeedy
  STA PLAYER_FIRST_SPRITE_Y, x
  TXA           ; transfer value of register x to a
  CLC           ; make sure the carry flag is clear
  ADC #$04      ; add 04 to register x
  TAX           ; transfer value of register a to x
  CPX #$10      ; check if x = 10, i.e, 4 sprites have been moved
  BNE MoveDownLoop
ReadDownDone:


ReadLeft:
  LDA buttons
  AND #%00000010
  BEQ ReadLeftDone  ; branch to ReadLeftDone if button is NOT pressed (0)
                    ; add instructions here to do something when button IS pressed (1)
  LDX #$00
MoveLeftLoop:
  LDA PLAYER_FIRST_SPRITE_X, x
  CMP #LEFTWALL
  BEQ ReadLeftDone
  SEC
  SBC #$01
  STA PLAYER_FIRST_SPRITE_X, x
  TXA           ; transfer value of register x to a
  CLC           ; make sure the carry flag is clear
  ADC #$04      ; add 04 to register x
  TAX           ; transfer value of register a to x
  CPX #$10      ; check if x = 10, i.e, 4 sprites have been moved
  BNE MoveLeftLoop
ReadLeftDone:   ; handling this button is done


ReadRight:
  LDA buttons
  AND #%00000001
  BEQ ReadRightDone  ; branch to ReadRightDone if button is NOT pressed (0)
                    ; add instructions here to do something when button IS pressed (1)
  LDX #$00
MoveRightLoop:
  LDA PLAYER_FIRST_SPRITE_X, x
  CMP #RIGHTWALL
  BEQ ReadRightDone
  CLC               ; make sure the carry flag is clear
  ADC #$01
  STA PLAYER_FIRST_SPRITE_X, x
  TXA           ; transfer value of register x to a
  CLC           ; make sure the carry flag is clear
  ADC #$04      ; add 04 to register x
  TAX           ; transfer value of register a to x
  CPX #$10      ; check if x = 10, i.e, 4 sprites have been moved
  BNE MoveRightLoop
ReadRightDone:       ; handling this button is done

  JSR UpdatePlayerPositionAndLimits
  JSR UpdateCarLimits

CheckCollision:
  LDA playerRight
  LDA carLeft
  CMP playerRight
  BCS GameEngineDone

  LDA playerLeft
  LDA carRight
  CMP playerLeft
  BCC GameEngineDone

  LDA playerBottom
  LDA carTop
  CMP playerBottom
  BCS GameEngineDone

  LDA playerTop
  LDA carBottom
  CMP playerTop
  BCC GameEngineDone

  LDA #$F5
  STA $0202
  RTI
CheckCollisionDone:



UpdatePlayerPositionAndLimits:
  LDA PLAYER_FIRST_SPRITE_Y
  ADC #$04
  STA playerY

  SEC
  SBC #$08
  STA playerTop

  CLC
  ADC #$08
  STA playerBottom

  LDA PLAYER_FIRST_SPRITE_X
  ADC #$04
  STA playerX

  CLC
  ADC #$08
  STA playerRight

  SEC
  SBC #$08
  STA playerLeft

  RTS

UpdateCarLimits:
  LDA carFirstSpriteY
  CLC
  ADC #CAR_BOTTOM_OFFSET
  STA carBottom

  LDA carFirstSpriteY
  SEC
  SBC #CAR_TOP_OFFSET
  STA carTop

  LDA carFirstSpriteX
  CLC
  ADC #CAR_RIGHT_OFFSET
  STA carRight

  LDA carFirstSpriteX
  SEC
  SBC #CAR_LEFT_OFFSET
  STA carLeft

  RTS


GameEngineDone:
  RTI

;;;;;;;;;;;;;;



  .org $E000
palette:
  .db $0F,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$0F
  .db $0F,$1C,$15,$14,$31,$02,$38,$3C,$0F,$1C,$15,$14,$31,$02,$38,$3C

sprites:
   ;vert tile attr horiz
  .db $80, $32, $00, $80   ;sprite 0 player
  .db $80, $33, $00, $88   ;sprite 1 player
  .db $88, $34, $00, $80   ;sprite 2 player
  .db $88, $35, $00, $88   ;sprite 3 player
  ; car top
  .db $50, $00, $02, $50   ;sprite 0
  .db $50, $02, $02, $58   ;sprite 1
  .db $50, $04, $02, $60   ;sprite 2
  .db $50, $06, $02, $68   ;sprite 3
  ; car bottom
  .db $58, $08, $02, $50   ;sprite 4
  .db $58, $0E, $02, $60   ;sprite 5
  ; car tires
  .db $58, $0A, $02, $58   ;sprite 6
  .db $58, $10, $02, $68   ;sprite 7

  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial


;;;;;;;;;;;;;;

;.incbin "mario.chr"
