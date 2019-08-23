  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring


;;;;;;;;;;;;;;;
   .enum $0000
   carUpdateCounter         .dw 1
   frameCounter        .dw 1
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
  CPX #$40
  BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 64, keep going down

  LDY #$01              ; init carUpdateCounter
  STY carUpdateCounter
  STY frameCounter

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

  LDX #$00

moveCar:
  LDA $0203, x       ; load sprite X position
  SEC
  SBC #$01        ; A = A + 1
  STA $0203, x       ; save sprite X position
  INX
  INX
  INX
  INX
  CPX #$20
  BNE moveCar

  LDY frameCounter
  CPY #$0D
  BEQ switchFrames
  INY
  STY frameCounter
  RTI

switchFrames:
  LDX #$00
  LDY carUpdateCounter
  TYA
  AND #$01
  BEQ animateCarReset      ; if frame counter is even, add 1 to all tiles, else subtract 1

animateCarAdd:
  LDA $0201, x        ; load sprite tile
  CLC
  ADC #$01            ; add 1
  STA $0201, x        ; store new sprite tile
  TXA
  CLC
  ADC #$04            ; add 4
  TAX
  CPX #$18             ; $18 = 24 = 6 processed sprites
  BNE animateCarAdd
  JMP animateTires

animateCarReset:
  LDA $0201, x        ; load sprite tile
  SEC
  SBC #$01            ; add 1
  STA $0201, x        ; store new sprite tile
  TXA
  CLC
  ADC #$04            ; add 4
  TAX
  CPX #$18             ; $18 = 24 = 6 processed sprites
  BNE animateCarReset

animateTires:
  LDX #$00
  TYA
  AND #$03      ; if zero, its a multiple of 4
  BEQ animateTiresReset
  LDA $0219
  CLC
  ADC #$01
  STA $0219
  LDA $021D
  CLC
  ADC #$01
  STA $021D
  JMP carUpdateEnd

animateTiresReset:
  LDA $0219
  SEC
  SBC #$03
  STA $0219
  LDA $021D
  SEC
  SBC #$03
  STA $021D

carUpdateEnd:

  INY
  STY carUpdateCounter
  LDY #$00
  STY frameCounter
  RTI             ; return from interrupt

;;;;;;;;;;;;;;



  .org $E000
palette:
  .db $14,$0C,$03,$0F,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$0F
  .db $00,$02,$12,$0F,$00,$04,$14,$0F,$00,$17,$27,$0F,$31,$02,$38,$3C

sprites:
  ; vert tile attr horiz
  ; car top
  .db $80, $00, $02, $80   ;sprite 0
  .db $80, $02, $02, $88   ;sprite 1
  .db $80, $04, $02, $90   ;sprite 2
  .db $80, $06, $02, $98   ;sprite 3
  ; car bottom
  .db $88, $08, $02, $80   ;sprite 4
  .db $88, $0E, $02, $90   ;sprite 5
  ; car tires
  .db $88, $0A, $02, $88   ;sprite 6
  .db $88, $10, $02, $98   ;sprite 7

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

  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial


;;;;;;;;;;;;;;


  .incbin "cars8.chr"   ;includes 8KB graphics file from SMB1
