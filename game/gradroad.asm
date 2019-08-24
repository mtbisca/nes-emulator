;----------------------------------------------------------------
; CONSTANTS
;----------------------------------------------------------------

PRG_COUNT = 1 ;1 = 16KB, 2 = 32KB
MIRRORING = %0001 ;%0000 = horizontal, %0001 = vertical, %1000 = four-screen

DINO1_TILE = $0201
DINO2_TILE = $0205
DINO3_TILE = $0209
DINO4_TILE = $020D
DINO1_ATR = $0202
DINO2_ATR = $0206
DINO3_ATR = $020A
DINO4_ATR = $020E

DINO_X = $0203
DINO_Y = $0200

PAD_A      = %10000000
PAD_B      = %01000000
PAD_SELECT = %00100000
PAD_START  = %00010000
PAD_UP     = %00001000
PAD_DOWN   = %00000100
PAD_LEFT   = %00000010
PAD_RIGHT  = %00000001

RIGHTWALL      = $F1  ; when dino reaches one of these, do something
TOPWALL        = $0A
BOTTOMWALL     = $DC
LEFTWALL       = $08

MORTARBOARD_LEFT         EQU $74
MORTARBOARD_RIGHT        EQU $84
MORTARBOARD_TOP          EQU $08
MORTARBOARD_BOTTOM       EQU $18

DINO_FIRST_SPRITE_Y   EQU $0200
DINO_FIRST_SPRITE_X   EQU $0203

CAR_FIRST_SPRITE_Y_BASE_ADDR   EQU $0210
CAR_FIRST_SPRITE_X_BASE_ADDR   EQU $0213

CAR_SPRITES_BASE_ADDR         EQU $0210
CAR_SPRITES_LAST_OFFSET_ADDR  EQU $C0

CAR_LEFT_OFFSET         EQU $04
CAR_RIGHT_OFFSET        EQU $1C
CAR_TOP_OFFSET          EQU $04
CAR_BOTTOM_OFFSET       EQU $0C

;----------------------------------------------------------------
; VARIABLES
;----------------------------------------------------------------

  .enum $0000

  ;NOTE: declare variables using the DSB and DSW directives, like this:

  ;MyVariable0 .dsb 1
  ;MyVariable1 .dsb 3
  sleeping .dsb 1          ;main program sets this and waits for the NMI to clear it.
  sound_disable_flag .dsb 1   ;a flag variable that keeps track of whether the sound engine is disabled or not.
  sound_ptr .dsb 2  ;a 2-byte pointer variable.
  sound_ptr2		.dsb	2
  ptr1 .dsb 2              ;a pointer
  jmp_ptr		.dsb	2
  end_game_sound_flag		.dsb	1

  sound_temp2 .dsb 6
  sound_temp1 .dsb 6
  sound_sq1_old		.dsb	1 ; The last value written to $4003
  sound_sq2_old		.dsb	1 ; The last value written to $4007
  soft_apu_ports		.dsb	16

  stream_curr_sound .dsb 6     ;reserve 6 bytes, one for each stream
  stream_status .dsb 6
  stream_channel .dsb 6
  stream_vol_duty .dsb 6
  stream_ptr_lo .dsb 6        ;The first byte will hold the LO byte of an address
  stream_ptr_hi .dsb 6         ;The second byte will hold the HI byte of an address      ;high 3 bits of the note period
  sound_frame_counter .dsb 1   ;a primitive counter used to time notes in this demo
  stream_note_lo .dsb 6    ;low 8 bits of period
  stream_note_hi .dsb 6    ;high 3 bits of period
  stream_tempo		.dsb	6 ; The value to add to our ticker each frame
  stream_ticker_total	.dsb	6 ; Our running ticker totoal
  stream_note_length_counter .dsb 6
  stream_note_length	.dsb	6
  current_song		.dsb 	1
  stream_ve		.dsb	6 ; Current volume envelope
  stream_ve_index	.dsb	6 ; Current position within volume envelope
  stream_loop1		.dsb	6 ; Loop counter
  stream_note_offset	.dsb	6 ; For key changes

  ; Dino center positions
  dinoX                 .dsw 1
  dinoY                 .dsw 1

  ; Dino limits
  dinoLeft              .dsw 1
  dinoRight             .dsw 1
  dinoTop               .dsw 1
  dinoBottom            .dsw 1

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
  frameCounter             .dw 1

  dinoPace                 .dw 1
  dinoDirection            .dw 1
  dinoMoveVar              .dw 1

  endGameFrameCounter      .dw 1

  buttons                 .dsw 1    ; each pad constant represents when each
                                    ; button is pressed

   .ende


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
  INX
  CPX #$E0              ; Decimal 224: total number of sprites
  BNE LoadSpritesLoop


LoadBackground:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address
  LDX #$00              ; start out at 0

LoadBackgroundFirst:
  LDA backgroundFirst, x
  STA $2007             ; write to PPU
  INX
  CPX #$00              ; if X overflows back to 0, loop ran 256
  BNE LoadBackgroundFirst

LoadBackgroundSecond:
  LDA backgroundSecond, x
  STA $2007
  INX
  CPX #$00
  BNE LoadBackgroundSecond

LoadBackgroundThird:
  LDA backgroundThird, x
  STA $2007
  INX
  CPX #$00
  BNE LoadBackgroundThird

LoadBackgroundFourth:
  LDA backgroundFourth, x
  STA $2007
  INX
  CPX #$C0              ; Compare X to hex $C0, decimal 192 - copying 192 bytes
  BNE LoadBackgroundFourth

LoadAttribute:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006             ; write the high byte of $23C0 address
  LDA #$C0
  STA $2006             ; write the low byte of $23C0 address
  LDX #$00
  LDA #$00              ; all attribute tables are 0: background uses one palette
LoadAttributeLoop:
  STA $2007             ; write to PPU
  INX
  CPX #$20              ; decimal 64: all attribute table entries
  BNE LoadAttributeLoop

  LDY #$01              ; init car controller variables
  STY carUpdateCounter
  STY frameCounter

  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0
  STA $2000

  LDA #%00011110   ; enable sprites
  STA $2001

  LDA #$03
  STA dinoDirection


  JSR sound_init ; sound initialization
  pha     ;save registers
  txa
  pha
  tya
  pha
  lda #$04
  jsr sound_load

  pla     ;restore registers
  tay
  pla
  tax
  pla
Forever:
 inc sleeping ;go to sleep (wait for NMI).
@loop:
    lda sleeping
    bne @loop ;wait for NMI to clear the sleeping flag and wake us up

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

MoveCarLeft:
  LDA firstCarSpriteOffset
  CLC
  ADC #$03                        ; offset for getting sprite X position
  TAX
  LDY #$00
MoveCarLeftLoop:
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
  BNE MoveCarLeftLoop
  RTS

MoveCarRight:
  LDA firstCarSpriteOffset
  CLC
  ADC #$03                        ; offset for getting sprite X position
  TAX
  LDY #$00                       ; Y will keep track of sprites count
MoveCarRightLoop:
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
  BNE MoveCarRightLoop
  RTS

UpdateCarFirstSpriteX:
  STA carFirstSpriteX
  RTS

;;;;;;
;;;;;;   CAR ANIMATION FUNCTIONS
;;;;;;   Params:
;;;;;;     firstCarSpriteOffset -> offset address of car's first sprite byte
;;;;;;

UpdateCarFrames:
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
  CPY #$06             ; $18 = 24 = 6 processed sprites -> all but tires
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
  AND #$03      ; if zero, updateCounter is a multiple of 4
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
;;;;;;   UPDATE LIMITS FUNCTIONS
;;;;;;

UpdateDinoPositionAndLimits:
  LDA DINO_FIRST_SPRITE_Y
  ADC #$04
  STA dinoY

  SEC
  SBC #$08
  STA dinoTop

  CLC
  ADC #$08
  STA dinoBottom

  LDA DINO_FIRST_SPRITE_X
  ADC #$04
  STA dinoX

  CLC
  ADC #$08
  STA dinoRight

  SEC
  SBC #$08
  STA dinoLeft

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

;;;;;;
;;;;;; DINO CONTROL FUNCTIONS
;;;;;;

resetLeft:
  LDY #03
  STY DINO1_TILE
  LDY #08
  STY DINO2_TILE
  LDY #14
  STY DINO3_TILE
  LDY #19
  STY DINO4_TILE
  LDA #%00000011
  STA DINO1_ATR
  STA DINO2_ATR
  STA DINO3_ATR
  STA DINO4_ATR
  LDA #$03
  STA dinoDirection
  LDA #$00
  STA dinoPace
RTS

resetRigth:
  LDY #08
  STY DINO1_TILE
  LDY #03
  STY DINO2_TILE
  LDY #19
  STY DINO3_TILE
  LDY #14
  STY DINO4_TILE
  LDA #%01000011
  STA DINO1_ATR
  STA DINO2_ATR
  STA DINO3_ATR
  STA DINO4_ATR
  LDA #$01
  STA dinoDirection
  LDA #$00
  STA dinoPace
RTS

resetUp:
  LDY #00
  STY DINO1_TILE
  LDY #05
  STY DINO2_TILE
  LDY #10
  STY DINO3_TILE
  LDY #16
  STY DINO4_TILE
  LDA #%00000011
  STA DINO1_ATR
  STA DINO2_ATR
  STA DINO3_ATR
  STA DINO4_ATR
  LDA #$00
  STA dinoDirection
  STA dinoPace
RTS

resetDown:
  LDY #02
  STY DINO1_TILE
  LDY #07
  STY DINO2_TILE
  LDY #12
  STY DINO3_TILE
  LDY #18
  STY DINO4_TILE
  LDA #%00000011
  STA DINO1_ATR
  STA DINO2_ATR
  STA DINO3_ATR
  STA DINO4_ATR
  LDA #$02
  STA dinoDirection
  LDA #$00
  STA dinoPace
RTS


MoveRestPlus:
  LDA DINO_Y, X
  CLC
  ADC #$01     ; A = A + 1
  STA DINO_Y, X
  TXA
  CLC
  ADC #$04
  TAX
  CMP dinoMoveVar
  BNE MoveRestPlus
RTS

MoveRestLow:
  LDA DINO_Y, X
  SEC
  SBC #$01     ; A = A - 1
  STA DINO_Y, X
  TXA
  CLC
  ADC #$04
  TAX
  CMP dinoMoveVar
  BNE MoveRestLow
RTS

animationRoutineS:
  LDA dinoPace
  CMP #$0F
  BEQ addifS
  CMP #$1F
  BEQ subifS
  JMP doneifS
addifS:
  JSR add

  LDA #$05
  JSR sound_load
  JMP doneifS
subifS:

  LDA #$05
  JSR sound_load
  JSR sub
doneifS:
  LDA dinoPace
  ADC #$01
  AND #%00011111
  STA dinoPace

  RTS

animationRoutineB:
  LDA dinoPace
  CMP #04
  BEQ addifB
  CMP #08
  BEQ flipifB
  CMP #16
  BEQ subifB
  CMP #20
  BEQ addifB
  CMP #24
  BEQ flipifB
  CMP #28
  BEQ subifB
  JMP doneifB
addifB:
  JSR add
  JMP doneifB
subifB:
  JSR sub
  JMP doneifB
flipifB:
  JSR flipDino
doneifB:
  LDA dinoPace
  CMP #28
BNE paceB
  LDA #00
  STA dinoPace
RTS
paceB:
  ADC #01
  STA dinoPace
RTS

animationRoutineF:
  LDA dinoPace
  CMP #04
  BEQ addif3F
  CMP #08
  BEQ flipifF
  CMP #16
  BEQ subif4F
  CMP #20
  BEQ addif4F
  CMP #24
  BEQ flipifF
  CMP #28
  BEQ subif3F
  JMP doneifF
flipifF:
  JSR flipDino
  JMP doneifF
addif3F:
  LDY DINO3_TILE
  INY
  STY DINO3_TILE
  JMP doneifF
addif4F:
  LDY DINO4_TILE
  INY
  STY DINO4_TILE
  JMP doneifF
subif3F:
  LDY DINO3_TILE
  DEY
  STY DINO3_TILE
  JMP doneifF
subif4F:
  LDY DINO4_TILE
  DEY
  STY DINO4_TILE
doneifF:

  LDA dinoPace
  CMP #28
BNE paceF
  LDA #00
  STA dinoPace
RTS
paceF:
  ADC #01
  STA dinoPace
RTS

add:
  LDY DINO1_TILE
  INY
  STY DINO1_TILE
  LDY DINO2_TILE
  INY
  STY DINO2_TILE
  LDY DINO3_TILE
  INY
  STY DINO3_TILE
  LDY DINO4_TILE
  INY
  STY DINO4_TILE
RTS

sub:
  LDY DINO1_TILE
  DEY
  STY DINO1_TILE
  LDY DINO2_TILE
  DEY
  STY DINO2_TILE
  LDY DINO3_TILE
  DEY
  STY DINO3_TILE
  LDY DINO4_TILE
  DEY
  STY DINO4_TILE
RTS

flipDino:
  LDX DINO1_TILE
  LDY DINO2_TILE
  STY DINO1_TILE
  STX DINO2_TILE
  LDX DINO3_TILE
  LDY DINO4_TILE
  STY DINO3_TILE
  STX DINO4_TILE
  LDA DINO1_ATR
  CMP #%01000011
  BEQ secondBit
  LDA #%01000011
  JMP doneBit
secondBit:
  LDA #%00000011
doneBit:
  STA DINO1_ATR
  STA DINO2_ATR
  STA DINO3_ATR
  STA DINO4_ATR

  LDA #$05
  JSR sound_load
RTS


NMI:
  PHA     ;save registers
  TXA
  PHA
  TYA
  PHA

  LDA #$00
  STA $2003  ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014  ; set the high byte (02) of the RAM address, start the transfer
  JSR sound_play_frame
  LDA #$00 
  STA sleeping            ;wake up the main program


  PLA     ;restore registers
  TAY
  PLA
  TAX
  PLA

  LDA end_game_sound_flag
  CMP #01
  BNE moveAll
  RTI
  ; JMP ppuCleanUp

moveAll:
;; MOVE CARS PIPELINE
  LDA #$00
  STA firstCarSpriteOffset
  LDA #$03
  STA carSpeed
  JSR MoveCarLeft

  LDA #$20
  STA firstCarSpriteOffset
  LDA #$01
  STA carSpeed
  JSR MoveCarRight

  LDA #$40
  STA firstCarSpriteOffset
  LDA #$01
  STA carSpeed
  JSR MoveCarLeft

  LDA #$60
  STA firstCarSpriteOffset
  LDA #$02
  STA carSpeed
  JSR MoveCarRight

  LDA #$80
  STA firstCarSpriteOffset
  LDA #$02
  STA carSpeed
  JSR MoveCarLeft

  LDA #$A0
  STA firstCarSpriteOffset
  LDA #$01
  STA carSpeed
  JSR MoveCarRight

;; ANIMATE CARS PIPELINE
  LDY frameCounter
  CPY #$0D
  BNE NoUpdateCarFrames

  LDA #$00
AnimateCars:
  STA firstCarSpriteOffset
  PHA
  JSR UpdateCarFrames
  PLA
  CLC
  ADC #$20
  CMP #$C0
  BNE AnimateCars

  LDY carUpdateCounter          ; increment car update
  INY
  STY carUpdateCounter

  LDY #$00                      ; reset frame counter
  STY frameCounter
  JMP ReadController

NoUpdateCarFrames:
  LDY frameCounter              ; increment frame counter
  INY
  STY frameCounter
  JMP ReadController

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
;;;;;;   DINO MOVING FUNCTIONS
;;;;;;

ReadUp:
  LDA buttons
  AND #%00001000
  BEQ ReadUpDone   ; branch to ReadUpDone if button is NOT pressed (0)
  LDA dinoDirection
  CMP #$00
  BEQ UpContinue
  JSR resetUp
  LDA #$00
  STA dinoDirection
UpContinue:
  LDA DINO_Y   ; load sprite position
  CMP #$07    ; end of up side
  BEQ ReadUpDone ; branch to ReadUpDone if position is end of up side
  LDX #$00
  LDA #$10
  STA dinoMoveVar
  JSR MoveRestLow
  JSR animationRoutineB
  JMP endController
ReadUpDone:

ReadDown:
  LDA buttons
  AND #%00000100
  BEQ ReadDownDone   ; branch to ReadADone if button is NOT pressed (0)
  LDA dinoDirection
  CMP #$02
  BEQ DownContinue
  JSR resetDown
  LDA #$02
  STA dinoDirection
DownContinue:
  LDA DINO_Y   ; load sprite position
  CMP #$D8    ; end of down side
  BEQ ReadDownDone ; branch to ReadADone if position is end of down side
  LDX #$00
  LDA #$10
  STA dinoMoveVar
  JSR MoveRestPlus
  JSR animationRoutineF
  JMP endController
ReadDownDone:

ReadLeft:
  LDA buttons
  AND #%00000010
  BEQ ReadLeftDone   ; branch to ReadADone if button is NOT pressed (0)
  LDA dinoDirection
  CMP #$03
  BEQ LeftContiue
  CMP #$01
  BEQ FlipLeft
  JSR resetLeft
  JMP LeftContiue
FlipLeft:
  JSR flipDino
  LDA #$03
  STA dinoDirection
LeftContiue:
  LDA DINO_X
  CMP #$07    ; end of left side
  BEQ ReadLeftDone ; branch to ReadADone if position is end of left side
  LDX #$03
  LDA #$13
  STA dinoMoveVar
  JSR MoveRestLow
  JSR animationRoutineS
  JMP endController
ReadLeftDone:

ReadRigth:
  LDA buttons
  AND #%00000001
  BEQ ReadRigthDone   ; branch to ReadADone if button is NOT pressed (0)
  LDA dinoDirection
  CMP #$01
  BEQ RigthContiue
  CMP #$03
  BEQ FlipRigth
  JSR resetRigth
  JMP RigthContiue
FlipRigth:
  JSR flipDino
  LDA #$01
  STA dinoDirection
RigthContiue:
  LDA DINO_X   ; load sprite position
  CMP #$F1    ; end of rigth side
  BEQ ReadRigthDone ; branch to ReadADone if position is end of rigth side
  LDX #$03
  LDA #$13
  STA dinoMoveVar
  JSR MoveRestPlus
  JSR animationRoutineS
  JMP endController
ReadRigthDone:

endController:


	; lda	#$00
	; sta	sleeping	; Wake up the main program

  JSR UpdateDinoPositionAndLimits

;;;;;;
;;;;;;   CHECK CAR COLLISION WITH DINO PIPELINE
;;;;;;   Checks car collision for each car moving
;;;;;;

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
  BEQ CheckMortarboardCollision
  BNE CheckCarCollisionLoop

CheckCarCollision:
  LDA carLeft
  CMP dinoRight
  BCS NoCarCollision

  LDA carRight
  CMP dinoLeft
  BCC NoCarCollision

  LDA carTop
  CMP dinoBottom
  BCS NoCarCollision

  LDA carBottom
  CMP dinoTop
  BCC NoCarCollision

  ; Collision
  LDA #$09
  JSR sound_load
  JMP endgame
  
  ; RTS
CheckCarCollisionDone:

NoCarCollision:
  RTS


;;;;;;
;;;;;;   CHECK MORTARBOARD COLLISION WITH DINO
;;;;;;

CheckMortarboardCollision:
  LDA #MORTARBOARD_LEFT
  CMP dinoRight
  BCS ppuCleanUp

  LDA #MORTARBOARD_RIGHT
  CMP dinoLeft
  BCC ppuCleanUp

  LDA #MORTARBOARD_TOP
  CMP dinoBottom
  BCS ppuCleanUp

  LDA #MORTARBOARD_BOTTOM
  CMP dinoTop
  BCC ppuCleanUp

  LDA #$00
  CMP end_game_sound_flag
  LDA #$09
  JSR sound_load
  JMP endgame

endgame:
  LDX #$01
  STX end_game_sound_flag
  ; JSR sound_load

ppuCleanUp:
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000
  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001
  LDA #$00        ;;tell the ppu there is no background scrolling
  STA $2005
  STA $2005
  ; JSR	sound_play_frame
  lda	#$00
	sta	sleeping	; Wake up the main program

  RTI


IRQ:
  RTI

;----------------------------------------------------------------
;   Sound engine
;----------------------------------------------------------------
.org $D000


.include "sound.asm"
.include "constants_sound.asm"
.include "sound_data.i"

.include "sound_opcodes.asm"
.include "volume_envelopes.asm"
;----------------------------------------------------------------
; interrupt vectors
;----------------------------------------------------------------

.org $E000
; palette:
;   .db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
;   .db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C
note_table:
    .word                                                                $07F1, $0780, $0713 ; A1-B1 ($00-$02)
    .word $06AD, $064D, $05F3, $059D, $054D, $0500, $04B8, $0475, $0435, $03F8, $03BF, $0389 ; C2-B2 ($03-$0E)
    .word $0356, $0326, $02F9, $02CE, $02A6, $027F, $025C, $023A, $021A, $01FB, $01DF, $01C4 ; C3-B3 ($0F-$1A)
    .word $01AB, $0193, $017C, $0167, $0151, $013F, $012D, $011C, $010C, $00FD, $00EF, $00E2 ; C4-B4 ($1B-$26)
    .word $00D2, $00C9, $00BD, $00B3, $00A9, $009F, $0096, $008E, $0086, $007E, $0077, $0070 ; C5-B5 ($27-$32)
    .word $006A, $0064, $005E, $0059, $0054, $004F, $004B, $0046, $0042, $003F, $003B, $0038 ; C6-B6 ($33-$3E)
    .word $0034, $0031, $002F, $002C, $0029, $0027, $0025, $0023, $0021, $001F, $001D, $001B ; C7-B7 ($3F-$4A)
    .word $001A, $0018, $0017, $0015, $0014, $0013, $0012, $0011, $0010, $000F, $000E, $000D ; C8-B8 ($4B-$56)
    .word $000C, $000C, $000B, $000A, $000A, $0009, $0008

.word $0000			; Rest
song_headers:
	.word	song0_header	; This is a silence song.
	.word	song1_header	; Evil, demented notes
	.word	song2_header	; A sound effect. Try playing it over other songs
	.word	song3_header	; A little chord progression
  .word song4_header
  .word song5_header
  .word song6_header
  .word song7_header
  .word song8_header
  .word song9_header

note_length_table:
	.byte	$01		; 32nd note
	.byte	$02		; 16th note
	.byte	$04		; 8th note
	.byte	$08		; Quarter note
	.byte	$10		; Half note
	.byte	$20		; Whole note

	;; Dotted notes
	.byte	$03		; Dotted 16th note
	.byte	$06		; Dotted 8th note
	.byte	$0c		; Dotted quarter note
	.byte	$18		; Dotted half note
	.byte	$30		; Dotted whole note?

	;; Other
	;; Modified quarter to fit after d_sixtength triplets
	.byte	$07
  .byte	$14		; 2 quarters plus an 8th
	.byte	$0a
                  ; C9-F#9 ($57-$5D)
song_data:  ;this data has two quarter rests in it.
    .byte half, C2, quarter, rest, eighth, D4, C4, quarter, B3, rest

palette:
  .db $2A,$0B,$2D,$30,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .db $2A,$02,$12,$0F,$00,$04,$14,$0F,$00,$17,$27,$0F,$15,$0B,$30,$0A

sprites:
  ;   vert tile attr horiz

  ; DINO
  .db $D8, $03, $03, $80
  .db $D8, $08, $03, $88
  .db $E0, $0E, $03, $80
  .db $E0, $13, $03, $88

 ;; Car 0
  ; car top
  .db $1C, $15, $02, $80
  .db $1C, $17, $02, $88
  .db $1C, $19, $02, $90
  .db $1C, $1B, $02, $98
  ; car bottom
  .db $24, $1D, $02, $80
  .db $24, $23, $02, $90
  ; car tires
  .db $24, $1F, $02, $88
  .db $24, $25, $02, $98


  ;; Car 1
  ; car top
  .db $2D, $1B, $41, $80
  .db $2D, $19, $41, $88
  .db $2D, $17, $41, $90
  .db $2D, $15, $41, $98
  ; car bottom
  .db $35, $23, $41, $88
  .db $35, $1D, $41, $98
  ; car tires
  .db $35, $25, $41, $80
  .db $35, $1F, $41, $90

  ;; Car 2
  ; car top
  .db $3D, $15, $00, $80
  .db $3D, $17, $00, $88
  .db $3D, $19, $00, $90
  .db $3D, $1B, $00, $98
  ; car bottom
  .db $45, $1D, $00, $80
  .db $45, $23, $00, $90
  ; car tires
  .db $45, $1F, $00, $88
  .db $45, $25, $00, $98

  ;; Car 3
  ; car top
  .db $6D, $1B, $42, $80
  .db $6D, $19, $42, $88
  .db $6D, $17, $42, $90
  .db $6D, $15, $42, $98
  ; car bottom
  .db $75, $23, $42, $88
  .db $75, $1D, $42, $98
  ; car tires
  .db $75, $25, $42, $80
  .db $75, $1F, $42, $90

  ;; Car 4
  ; car top
  .db $9D, $15, $01, $80
  .db $9D, $17, $01, $88
  .db $9D, $19, $01, $90
  .db $9D, $1B, $01, $98
  ; car bottom
  .db $A5, $1D, $01, $80
  .db $A5, $23, $01, $90
  ; car tires
  .db $A5, $1F, $01, $88
  .db $A5, $25, $01, $98

  ;; Car 5
  ; car top
  .db $BD, $1B, $40, $80
  .db $BD, $19, $40, $88
  .db $BD, $17, $40, $90
  .db $BD, $15, $40, $98
  ; car bottom
  .db $C5, $23, $40, $88
  .db $C5, $1D, $40, $98
  ; car tires
  .db $C5, $25, $40, $80
  .db $C5, $1F, $40, $90

  ;; Mortarboard
  .db $0C, $29, $00, $78
  .db $0C, $2A, $00, $80
  .db $14, $2B, $00, $78
  .db $14, $2C, $00, $80

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

   .org $fffa

   .dw NMI
   .dw RESET
   .dw IRQ

;----------------------------------------------------------------
; CHR-ROM bank
;----------------------------------------------------------------

.base $0000
.incbin "dino.chr"
.incbin "cars.chr"
.incbin "mortarboard.chr"
.pad $1000, #$00
.incbin "bg.chr"
.pad $6000, $FF
