;----------------------------------------------------------------
; constants
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

;----------------------------------------------------------------
; variables
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

NMI:
pha     ;save registers
  txa
  pha
  tya
  pha

  lda #$00
  sta $2003  ; set the low byte (00) of the RAM address
  lda #$02
  sta $4014  ; set the high byte (02) of the RAM address, start the transfer
  jsr sound_play_frame
  lda #$00
  sta sleeping            ;wake up the main program

  
  pla     ;restore registers
  tay
  pla
  tax
  pla

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
  LDA $0301
  CMP #$00
  BEQ UPContinue
  JSR resetUP
  LDA #$00
  STA $0301
UPContinue:
  LDA DINO_Y   ; load sprite position
  CMP #$07    ; end of up side
  BEQ endlabel ; branch to ReadUPDone if position is end of up side
  LDX #$00
  LDA #$10
  STA $0302
  JSR MoveRestLow
  JSR animationRoutineB
  JMP endController

endlabel:
  lda #$09
  jsr sound_load
ReadUPDone:

ReadDown:
  LDA $4016     ; player 1 - Down
  AND #%00000001  ; erase everything but bit 0
  BEQ ReadDownDone   ; branch to ReadADone if button is NOT pressed (0)
  LDA $0301
  CMP #$02
  BEQ DownContinue
  JSR resetDown
  LDA #$02
  STA $0301
DownContinue:
  LDA DINO_Y   ; load sprite position
  CMP #$D7    ; end of down side
  BEQ ReadDownDone ; branch to ReadADone if position is end of down side
  LDX #$00
  LDA #$10
  STA $0302
  JSR MoveRestPlus
  JSR animationRoutineF
  JMP endController
ReadDownDone:

ReadLeft:
  LDA $4016     ; player 1 - Left
  AND #%00000001  ; erase everything but bit 0
  BEQ ReadLeftDone   ; branch to ReadADone if button is NOT pressed (0)
  LDA $0301
  CMP #$03
  BEQ LeftContiue
  CMP #$01
  BEQ FlipLeft
  JSR resetLeft
  JMP LeftContiue
FlipLeft:
  JSR flipDino
  LDA #$03
  STA $0301
LeftContiue:
  LDA DINO_X
  CMP #$07    ; end of left side
  BEQ ReadLeftDone ; branch to ReadADone if position is end of left side
  LDX #$03
  LDA #$13
  STA $0302
  JSR MoveRestLow
  JSR animationRoutineS
  JMP endController
ReadLeftDone:

ReadRigth:
  LDA $4016     ; player 1 - Right
  AND #%00000001  ; erase everything but bit 0
  BEQ ReadRigthDone   ; branch to ReadADone if button is NOT pressed (0)
  LDA $0301
  CMP #$01
  BEQ RigthContiue
  CMP #$03
  BEQ FlipRigth
  JSR resetRigth
  JMP RigthContiue
FlipRigth:
  JSR flipDino
  LDA #$01
  STA $0301
RigthContiue:
  LDA DINO_X   ; load sprite position
  CMP #$F1    ; end of rigth side
  BEQ ReadRigthDone ; branch to ReadADone if position is end of rigth side
  LDX #$03
  LDA #$13
  STA $0302
  JSR MoveRestPlus
  JSR animationRoutineS
  JMP endController
ReadRigthDone:

endController:
  
  jsr	sound_play_frame

	lda	#$00
	sta	sleeping	; Wake up the main program

  RTI        ; return from interrupt

resetLeft:
  LDY #03
  STY DINO1_TILE
  LDY #08
  STY DINO2_TILE
  LDY #14
  STY DINO3_TILE
  LDY #19
  STY DINO4_TILE
  LDA #%00000000
  STA DINO1_ATR
  STA DINO2_ATR
  STA DINO3_ATR
  STA DINO4_ATR
  LDA #$03
  STA $0301
  LDA #$00
  STA $0300
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
  LDA #%01000000
  STA DINO1_ATR
  STA DINO2_ATR
  STA DINO3_ATR
  STA DINO4_ATR
  LDA #$01
  STA $0301
  LDA #$00
  STA $0300
RTS

resetUP:
  LDY #00
  STY DINO1_TILE
  LDY #05
  STY DINO2_TILE
  LDY #10
  STY DINO3_TILE
  LDY #16
  STY DINO4_TILE
  LDA #%00000000
  STA DINO1_ATR
  STA DINO2_ATR
  STA DINO3_ATR
  STA DINO4_ATR
  LDA #$00
  STA $0301
  STA $0300
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
  LDA #%00000000
  STA DINO1_ATR
  STA DINO2_ATR
  STA DINO3_ATR
  STA DINO4_ATR
  LDA #$02
  STA $0301
  LDA #$00
  STA $0300
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
  CMP $0302
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
  CMP $0302
  BNE MoveRestLow
RTS

animationRoutineS:
  LDA $0300
  CMP #$0F
  BEQ addifS
  CMP #$1F
  BEQ subifS
  JMP doneifS
addifS:
  JSR add
  JMP doneifS
subifS:
  JSR sub
doneifS:
  LDA $0300
  ADC #$01
  AND #%00011111
  STA $0300
  RTS

animationRoutineB:
  LDA $0300
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
  LDA $0300
  CMP #28
BNE paceB
  LDA #00
  STA $0300
RTS
paceB:
  ADC #01
  STA $0300
RTS

animationRoutineF:
  LDA $0300
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
  LDA $0300
  CMP #28
BNE paceF
  LDA #00
  STA $0300
RTS
paceF:
  ADC #01
  STA $0300
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
  CMP #%01000000
  BEQ secondBit
  LDA #%01000000
  JMP doneBit
secondBit:
  LDA #%00000000
doneBit:
  STA DINO1_ATR
  STA DINO2_ATR
  STA DINO3_ATR
  STA DINO4_ATR
  
RTS

IRQ:

   ;NOTE: IRQ code goes here
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

.incbin "dino.chr"
.dsb $6000, $FF
