  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring


;;;;;;;;;;;;;;;

   SPRITES_BASE_ADDR EQU $0200
   .enum $0000
   carUpdateCounter         .dw 1
   frameCounter             .dw 1
   firstCarSpriteOffset     .dw 1
   carSpeed                 .dw 1
   .ende

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
  CPX #$60
  BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 64, keep going down
LoadBackground:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address
  LDX #$00              ; start out at 0
LoadBackgroundFirst:
  LDA backgroundFirst, x     ; load data from address (background + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$00              ; Compare X to hex $80, decimal 128 - copying 128 bytes
  BNE LoadBackgroundFirst ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down
LoadBackgroundSecond:
  LDA backgroundSecond, x     ; load data from address (background + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$00             ; Compare X to hex $80, decimal 128 - copying 128 bytes
  BNE LoadBackgroundSecond ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down
LoadBackgroundThird:
  LDA backgroundThird, x     ; load data from address (background + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$00             ; Compare X to hex $80, decimal 128 - copying 128 bytes
  BNE LoadBackgroundThird  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down
LoadBackgroundFourth:
  LDA backgroundFourth, x     ; load data from address (background + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$C0              ; Compare X to hex $80, decimal 128 - copying 128 bytes
  BNE LoadBackgroundFourth

LoadAttribute:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006             ; write the high byte of $23C0 address
  LDA #$C0
  STA $2006             ; write the low byte of $23C0 address
  LDX #$00              ; start out at 0
  LDA #$00
LoadAttributeLoop:
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $08, decimal 8 - copying 8 bytes
  BNE LoadAttributeLoop  ; Branch to LoadAttributeLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down

  LDY #$01              ; init carUpdateCounter
  STY carUpdateCounter
  STY frameCounter

  LDA #%10010000   ; enable NMI, sprites from Pattern Table 1
  STA $2000

  LDA #%00011110   ; enable sprites
  STA $2001

Forever:
  JMP Forever     ;jump back to Forever, infinite loop

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
  LDA SPRITES_BASE_ADDR, x       ; load sprite X position
  SEC
  SBC carSpeed
  STA SPRITES_BASE_ADDR, x       ; save sprite X position
  INX
  INX
  INX
  INX
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
  LDA SPRITES_BASE_ADDR, x       ; load sprite X position
  CLC
  ADC carSpeed
  STA SPRITES_BASE_ADDR, x       ; save sprite X position
  INX
  INX
  INX
  INX
  INY
  CPY #$08                        ; 8 sprites processed: full car
  BNE moveCarRightLoop
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
  LDA SPRITES_BASE_ADDR, x        ; load sprite tile
  CLC
  ADC #$01
  STA SPRITES_BASE_ADDR, x        ; store new sprite tile
  TXA
  CLC
  ADC #$04
  TAX
  INY
  CPY #$06             ; 6 processed sprites
  BNE animateCarAdd
  JMP animateTires

animateCarReset:
  LDA SPRITES_BASE_ADDR, x        ; load sprite tile
  SEC
  SBC #$01            ; add 1
  STA SPRITES_BASE_ADDR, x        ; store new sprite tile
  TXA
  CLC
  ADC #$04            ; add 4
  TAX
  INY
  CPY #$06             ; $18 = 24 = 6 processed sprites
  BNE animateCarReset

animateTires:
  LDY carUpdateCounter
  TYA
  AND #$03      ; if zero, its a multiple of 4
  BEQ animateTiresReset
  LDA SPRITES_BASE_ADDR, x
  CLC
  ADC #$01
  STA SPRITES_BASE_ADDR, x
  TXA
  CLC
  ADC #$04
  TAX
  LDA SPRITES_BASE_ADDR, x
  CLC
  ADC #$01
  STA SPRITES_BASE_ADDR, x
  JMP carUpdateEnd

animateTiresReset:
  LDA SPRITES_BASE_ADDR, x
  SEC
  SBC #$03
  STA SPRITES_BASE_ADDR, x
  TXA
  CLC
  ADC #$04
  TAX
  LDA SPRITES_BASE_ADDR, x
  SEC
  SBC #$03
  STA SPRITES_BASE_ADDR, x

carUpdateEnd:
  RTS


NMI:
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer

  LDA #$20
  STA firstCarSpriteOffset
  LDA #$01
  STA carSpeed
  JSR moveCarRight

  LDA #$40
  STA firstCarSpriteOffset
  LDA #$02
  STA carSpeed
  JSR moveCarRight

  LDA #$00
  STA firstCarSpriteOffset
  LDA #$03
  STA carSpeed
  JSR moveCarLeft

  LDY frameCounter
  CPY #$0D
  BNE noUpdateCarFrames

  ; update fist car
  LDA #$00
  STA firstCarSpriteOffset
  JSR updateCarFrames

  ; update second car
  LDA #$20
  STA firstCarSpriteOffset
  JSR updateCarFrames

  ; update third car
  LDA #$40
  STA firstCarSpriteOffset
  JSR updateCarFrames

  LDY carUpdateCounter          ; increment car update
  INY
  STY carUpdateCounter

  LDY #$00                      ; reset frame counter
  STY frameCounter
  JMP ppuCleanUp

noUpdateCarFrames:
  LDY frameCounter              ; increment frame counter
  INY
  STY frameCounter


ppuCleanUp:
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000
  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001
  LDA #$00        ;;tell the ppu there is no background scrolling
  STA $2005
  STA $2005
  RTI
;;;;;;;;;;;;;;



  .org $E000

backgroundFirst:
.byte 00,01,00,01,00,01,00,01,00,01,00,01,00,01,00,01
.byte 00,01,00,01,00,01,00,01,00,01,00,01,00,01,00,01
.byte 02,03,02,03,02,03,02,03,02,03,02,03,02,03,02,03
.byte 02,03,02,03,02,03,02,03,02,03,02,03,02,03,02,03

.byte 00,01,00,01,00,01,00,01,00,01,00,01,00,01,00,01
.byte 00,01,00,01,00,01,00,01,00,01,00,01,00,01,00,01
.byte 02,03,02,03,02,03,02,03,02,03,02,03,02,03,02,03
.byte 02,03,02,03,02,03,02,03,02,03,02,03,02,03,02,03

.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 05,06,05,06,05,06,05,06,05,06,05,06,05,06,05,06
.byte 05,06,05,06,05,06,05,06,05,06,05,06,05,06,05,06

.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 05,06,05,06,05,06,05,06,05,06,05,06,05,06,05,06
.byte 05,06,05,06,05,06,05,06,05,06,05,06,05,06,05,06

backgroundSecond:
.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 07,07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
.byte 07,07,07,07,07,07,07,07,07,07,07,07,07,07,07,07

.byte 00,01,00,01,00,01,00,01,00,01,00,01,00,01,00,01
.byte 00,01,00,01,00,01,00,01,00,01,00,01,00,01,00,01
.byte 02,03,02,03,02,03,02,03,02,03,02,03,02,03,02,03
.byte 02,03,02,03,02,03,02,03,02,03,02,03,02,03,02,03

.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 05,06,05,06,05,06,05,06,05,06,05,06,05,06,05,06
.byte 05,06,05,06,05,06,05,06,05,06,05,06,05,06,05,06

.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 07,07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
.byte 07,07,07,07,07,07,07,07,07,07,07,07,07,07,07,07

backgroundThird:
.byte 00,01,00,01,00,01,00,01,00,01,00,01,00,01,00,01
.byte 00,01,00,01,00,01,00,01,00,01,00,01,00,01,00,01
.byte 02,03,02,03,02,03,02,03,02,03,02,03,02,03,02,03
.byte 02,03,02,03,02,03,02,03,02,03,02,03,02,03,02,03

.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 05,06,05,06,05,06,05,06,05,06,05,06,05,06,05,06
.byte 05,06,05,06,05,06,05,06,05,06,05,06,05,06,05,06

.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 07,07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
.byte 07,07,07,07,07,07,07,07,07,07,07,07,07,07,07,07

.byte 00,01,00,01,00,01,00,01,00,01,00,01,00,01,00,01
.byte 00,01,00,01,00,01,00,01,00,01,00,01,00,01,00,01
.byte 02,03,02,03,02,03,02,03,02,03,02,03,02,03,02,03
.byte 02,03,02,03,02,03,02,03,02,03,02,03,02,03,02,03

backgroundFourth:
.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 05,06,05,06,05,06,05,06,05,06,05,06,05,06,05,06
.byte 05,06,05,06,05,06,05,06,05,06,05,06,05,06,05,06

.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04
.byte 07,07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
.byte 07,07,07,07,07,07,07,07,07,07,07,07,07,07,07,07

.byte 00,01,00,01,00,01,00,01,00,01,00,01,00,01,00,01
.byte 00,01,00,01,00,01,00,01,00,01,00,01,00,01,00,01
.byte 02,03,02,03,02,03,02,03,02,03,02,03,02,03,02,03
.byte 02,03,02,03,02,03,02,03,02,03,02,03,02,03,02,03

sprites:
  ; vert tile attr horiz
  ; car top
  .db $80, $00, $01, $80   ;sprite 0
  .db $80, $02, $01, $88   ;sprite 1
  .db $80, $04, $01, $90   ;sprite 2
  .db $80, $06, $01, $98   ;sprite 3
  ; car bottom
  .db $88, $08, $01, $80   ;sprite 4
  .db $88, $0E, $01, $90   ;sprite 5
  ; car tires
  .db $88, $0A, $01, $88   ;sprite 6
  .db $88, $10, $01, $98   ;sprite 7

  ; car top
  .db $C0, $06, #%01000000, $80   ;sprite 8
  .db $C0, $04, #%01000000, $88   ;sprite 9
  .db $C0, $02, #%01000000, $90   ;sprite 10
  .db $C0, $00, #%01000000, $98   ;sprite 11
  ; car bottom
  .db $C8, $0E, #%01000000, $88   ;sprite 12
  .db $C8, $08, #%01000000, $98   ;sprite 13
  ; car tires
  .db $C8, $10, #%01000000, $80   ;sprite 14
  .db $C8, $0A, #%01000000, $90   ;sprite 15

  ; car top
  .db $40, $06, #%01000010, $80   ;sprite 16
  .db $40, $04, #%01000010, $88   ;sprite 17
  .db $40, $02, #%01000010, $90   ;sprite 18
  .db $40, $00, #%01000010, $98   ;sprite 19
  ; car bottom
  .db $48, $0E, #%01000010, $88   ;sprite 20
  .db $48, $08, #%01000010, $98   ;sprite 21
  ; car tires
  .db $48, $10, #%01000010, $80   ;sprite 22
  .db $48, $0A, #%01000010, $90   ;sprite 23

palette:
  .db $2A,$0B,$2D,$30,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .db $2A,$02,$12,$0F,$00,$04,$14,$0F,$00,$17,$27,$0F,$31,$02,$38,$3C

  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial


;;;;;;;;;;;;;;

  .base $0000
  .incbin "cars.chr"   ;includes 8KB graphics file from SMB1
  .pad $1000, #$00
  .incbin "bg.chr"
  .dsb $6000, $FF
