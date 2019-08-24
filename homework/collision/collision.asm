.inesprg 1   ; 1x 16KB PRG code
.ineschr 0   ; 1x  8KB CHR data
.inesmap 0   ; mapper 0 = NROM, no bank swapping
.inesmir 1   ; background mirroring



;----------------------------------------------------------------
; VARIABLES
;----------------------------------------------------------------
.enum $0000 ;start variables at ram location 0

; Player center positions
playerX                 .dsw 1
playerY                 .dsw 1

; Player limits
playerLeft              .dsw 1
playerRight             .dsw 1
playerTop               .dsw 1
playerBottom            .dsw 1

; Car Limits
carLeft                 .dsw 1
carRight                .dsw 1
carTop                  .dsw 1
carBottom               .dsw 1

; Positions of the car first sprite's center
carFirstSpriteY         .dsw 1
carFirstSpriteX         .dsw 1

firstCarSpriteOffset    .dsw 1
carSpeed                .dsw 1
carUpdateCounter        .dsw 1

buttons                 .dsw 1    ; each pad constant represents when each
                                  ; button is pressed

.ende


;----------------------------------------------------------------
; CONSTANTS
;----------------------------------------------------------------
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

PLAYER_FIRST_SPRITE_Y   EQU $0200
PLAYER_FIRST_SPRITE_X   EQU $0203

CAR_FIRST_SPRITE_Y_BASE_ADDR   EQU $0210
CAR_FIRST_SPRITE_X_BASE_ADDR   EQU $0213

CAR_SPRITES_BASE_ADDR         EQU $0210
CAR_SPRITES_LAST_OFFSET_ADDR  EQU $40

CAR_LEFT_OFFSET         EQU $04
CAR_RIGHT_OFFSET        EQU $1C
CAR_TOP_OFFSET          EQU $04
CAR_BOTTOM_OFFSET       EQU $0C


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
  CPX #$60              ; Compare X to hex $20, decimal 32
  BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                      ; if compare was equal to 32, keep going down


  LDA #%10000000   ; enable NMI, sprites from Pattern Table 1
  STA $2000

  LDA #%00010000   ; enable sprites
  STA $2001

Forever:
  JMP Forever     ;jump back to Forever, infinite loop

;;;;;;
;;;;;;   UTILS
AddFourToRegisterX:
  TXA           ; transfer value of register x to a
  CLC           ; make sure the carry flag is clear
  ADC #$04      ; add 04 to register x
  TAX           ; transfer value of register a to x
  RTS


;;;;;;
;;;;;;   CAR MOVING FUNCTIONS
;;;;;;   Params:
;;;;;;     firstCarSpriteOffset -> offset address of car's first sprite byte
;;;;;;     carSpeed -> number of pixels to add/subtract to car's x coord
;;;;;;

moveCarLeft:
  LDA firstCarSpriteOffset
  CLC
  ADC #$03                        ; offset for getting sprite X position
  TAX
  LDY #$00
moveCarLeftLoop:
  LDA CAR_SPRITES_BASE_ADDR, x       ; load sprite X position
  SEC
  SBC carSpeed
  STA CAR_SPRITES_BASE_ADDR, x       ; save sprite X position
  STA carFirstSpriteX
  CPY #$00
  BNE ContinueMoveCarLeftLoop
  JSR UpdateCarFirstSpriteX
ContinueMoveCarLeftLoop:
  JSR AddFourToRegisterX
  INY
  CPY #$08                        ; 8 sprites processed: full car
  BNE moveCarLeftLoop
  RTS

moveCarRight:
  LDA firstCarSpriteOffset
  CLC
  ADC #$03                        ; offset for getting sprite X position
  TAX
  LDY #$00                       ; Y will keep track of sprites count
moveCarRightLoop:
  LDA CAR_SPRITES_BASE_ADDR, x       ; load sprite X position
  CLC
  ADC carSpeed
  STA CAR_SPRITES_BASE_ADDR, x       ; save sprite X position
  CPY #$00
  BNE ContinueMoveCarRightLoop
  JSR UpdateCarFirstSpriteX
ContinueMoveCarRightLoop:
  JSR AddFourToRegisterX
  INY
  CPY #$08                        ; 8 sprites processed: full car
  BNE moveCarRightLoop
  RTS

UpdateCarFirstSpriteX:
  STA carFirstSpriteX
  RTS

;;;;;;
;;;;;;   CAR ANIMATION FUNCTIONS
;;;;;;   Params:
;;;;;;     firstCarSpriteOffset -> offset address of car's first sprite byte
;;;;;;

updateCarFrames:
  LDX firstCarSpriteOffset
  INX                          ; add 1 to get sprite tile address
  LDY #$00                     ; init loop counter
  LDA carUpdateCounter
  AND #$01
  BEQ animateCarReset      ; if update counter is even, add 1 to all tiles, else subtract 1


animateCarAdd:
  LDA CAR_SPRITES_BASE_ADDR, x        ; load sprite tile
  CLC
  ADC #$01
  STA CAR_SPRITES_BASE_ADDR, x        ; store new sprite tile
  JSR AddFourToRegisterX
  INY
  CPY #$06             ; 6 processed sprites
  BNE animateCarAdd
  JMP animateTires

animateCarReset:
  LDA CAR_SPRITES_BASE_ADDR, x        ; load sprite tile
  SEC
  SBC #$01            ; add 1
  STA CAR_SPRITES_BASE_ADDR, x        ; store new sprite tile
  JSR AddFourToRegisterX
  INY
  CPY #$06             ; $18 = 24 = 6 processed sprites
  BNE animateCarReset

animateTires:
  LDY carUpdateCounter
  TYA
  AND #$03      ; if zero, its a multiple of 4
  BEQ animateTiresReset
  LDA CAR_SPRITES_BASE_ADDR, x
  CLC
  ADC #$01
  STA CAR_SPRITES_BASE_ADDR, x
  JSR AddFourToRegisterX
  LDA CAR_SPRITES_BASE_ADDR, x
  CLC
  ADC #$01
  STA CAR_SPRITES_BASE_ADDR, x
  JMP carUpdateEnd

animateTiresReset:
  LDA CAR_SPRITES_BASE_ADDR, x
  SEC
  SBC #$03
  STA CAR_SPRITES_BASE_ADDR, x
  JSR AddFourToRegisterX
  LDA CAR_SPRITES_BASE_ADDR, x
  SEC
  SBC #$03
  STA CAR_SPRITES_BASE_ADDR, x

carUpdateEnd:
  RTS


;;;;;;
;;;;;;   UPDATE POSITIONS FUNCTIONS
;;;;;;

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



NMI:
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer

  LDA #$00
  STA firstCarSpriteOffset
  LDA #$02
  STA carSpeed
  JSR moveCarRight

  ; update car
  LDA #$00
  STA firstCarSpriteOffset
  JSR updateCarFrames

  LDA #$20
  STA firstCarSpriteOffset
  LDA #$02
  STA carSpeed
  JSR moveCarRight

  ; update car
  LDA #$20
  STA firstCarSpriteOffset
  JSR updateCarFrames

;;;;;;
;;;;;;   CONTROLLER FUNCTIONS
;;;;;;   Store at variable buttons if each button was pressed
;;;;;;

ReadController:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016        ; tell both the controllers to latch buttons
  LDX #$08
ReadControllerLoop:
  LDA $4016
  LSR A            ; bit0 -> Carry
  ROL buttons      ; bit0 <- Carry
  DEX
  BNE ReadControllerLoop


;;;;;;
;;;;;;   PLAYER MOVING FUNCTIONS
;;;;;;

ReadUp:
  LDA buttons
  AND #%00001000
  BEQ ReadUpDone
  LDX #$00
MovePlayerUpLoop:
  LDA PLAYER_FIRST_SPRITE_Y, x
  CMP #TOPWALL
  BEQ ReadUpDone
  SEC
  SBC #$01        ; player y position = player y - player y speed
  STA PLAYER_FIRST_SPRITE_Y, x
  JSR AddFourToRegisterX
  CPX #$10        ; check if x = 10, i.e, 4 sprites have been moved
  BNE MovePlayerUpLoop
ReadUpDone:

ReadDown:
  LDA buttons
  AND #%00000100
  BEQ ReadDownDone
  LDX #$00
MovePlayerDownLoop:
  LDA PLAYER_FIRST_SPRITE_Y, x
  CMP #BOTTOMWALL
  BEQ ReadDownDone
  CLC
  ADC #$01        ; player y position = player y + player y speed
  STA PLAYER_FIRST_SPRITE_Y, x
  JSR AddFourToRegisterX
  CPX #$10        ; check if x = 10, i.e, 4 sprites have been moved
  BNE MovePlayerDownLoop
ReadDownDone:

ReadLeft:
  LDA buttons
  AND #%00000010
  BEQ ReadLeftDone  ; branch to ReadLeftDone if button is NOT pressed (0)
  LDX #$00
MovePlayerLeftLoop:
  LDA PLAYER_FIRST_SPRITE_X, x
  CMP #LEFTWALL
  BEQ ReadLeftDone
  SEC
  SBC #$01
  STA PLAYER_FIRST_SPRITE_X, x
  JSR AddFourToRegisterX
  CPX #$10      ; check if x = 10, i.e, 4 sprites have been moved
  BNE MovePlayerLeftLoop
ReadLeftDone:

ReadRight:
  LDA buttons
  AND #%00000001
  BEQ ReadRightDone  ; branch to ReadRightDone if button is NOT pressed (0)
  LDX #$00
MovePlayerRightLoop:
  LDA PLAYER_FIRST_SPRITE_X, x
  CMP #RIGHTWALL
  BEQ ReadRightDone
  CLC
  ADC #$01
  STA PLAYER_FIRST_SPRITE_X, x
  JSR AddFourToRegisterX
  CPX #$10            ; check if x = 10, i.e, 4 sprites have been moved
  BNE MovePlayerRightLoop
ReadRightDone:


;;;;;;
;;;;;;   CHECK CAR COLLISION WITH PLAYER PIPELINE
;;;;;;   Checks car collision for each car moving
;;;;;;

  JSR UpdatePlayerPositionAndLimits

  LDX #$00
CheckCarCollisionLoop:
  LDA CAR_FIRST_SPRITE_Y_BASE_ADDR, x
  STA carFirstSpriteY

  LDA CAR_FIRST_SPRITE_X_BASE_ADDR, x
  STA carFirstSpriteX

  JSR UpdateCarLimits
  JSR CheckCarCollision

  TXA
  CLC
  ADC #$20
  TAX           ; add 20 (offset to another car) to register X
  CPX #CAR_SPRITES_LAST_OFFSET_ADDR
  BEQ GameEngineDone
  BNE CheckCarCollisionLoop

CheckCarCollision:
  LDA playerRight
  LDA carLeft
  CMP playerRight
  BCS NoCarCollision

  LDA playerLeft
  LDA carRight
  CMP playerLeft
  BCC NoCarCollision

  LDA playerBottom
  LDA carTop
  CMP playerBottom
  BCS NoCarCollision

  LDA playerTop
  LDA carBottom
  CMP playerTop
  BCC NoCarCollision

  ; Collision
  LDA #$F5
  STA $0202
  RTS
CheckCarCollisionDone:

NoCarCollision:
  RTS


GameEngineDone:
  RTI

;;;;;;;;;;;;;;



  .org $E000
palette:
  .db $0F,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$0F
  .db $0F,$1C,$15,$14,$31,$02,$38,$3C,$0F,$1C,$15,$14,$31,$02,$38,$3C

sprites:
  ;; Player
  .db $80, $32, $00, $80   ;sprite 0
  .db $80, $33, $00, $88   ;sprite 1
  .db $88, $34, $00, $80   ;sprite 2
  .db $88, $35, $00, $88   ;sprite 3

  ;; Car 0
  ; car top
  .db $40, $00, $02, $80   ;sprite 0
  .db $40, $02, $02, $88   ;sprite 1
  .db $40, $04, $02, $90   ;sprite 2
  .db $40, $06, $02, $98   ;sprite 3
  ; car bottom
  .db $48, $08, $02, $88   ;sprite 4
  .db $48, $0E, $02, $98   ;sprite 5
  ; car tires
  .db $48, $0A, $02, $80   ;sprite 6
  .db $48, $10, $02, $90   ;sprite 7

  ;; Car 1
  ; car top
  .db $B0, $06, $02, $80   ;sprite 8
  .db $B0, $04, $02, $88   ;sprite 9
  .db $B0, $02, $02, $90   ;sprite 10
  .db $B0, $00, $02, $98   ;sprite 11
  ; car bottom
  .db $B8, $0E, $02, $88   ;sprite 12
  .db $B8, $08, $02, $98   ;sprite 13
  ; car tires
  .db $B8, $10, $02, $80   ;sprite 14
  .db $B8, $0A, $02, $90   ;sprite 15


  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial


;;;;;;;;;;;;;;

;.incbin "mario.chr"
