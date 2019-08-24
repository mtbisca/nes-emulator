
sound_init:
	;; Enable Square 1, Square 2, Triangle and Noise channels
	lda	#$0f
	sta	$4015

	lda	#$00
	sta	sound_disable_flag ; Clear disable flag
	;; Later, if we have other variables we want to initialize, we will do
	;; that here.

	;; Initializing these to $FF ensures that the first notes of these
	;; songs ins't skipped.
	lda	#$ff
	sta	sound_sq1_old
	sta	sound_sq2_old

se_silence:	
	lda	#$30
	sta	soft_apu_ports		; Set Square 1 volume to 0
	sta	soft_apu_ports+4 	; Set Square 2 volumne to 0
	sta	soft_apu_ports+12	; Set Noise volume to 0
	lda	#$80
	sta	soft_apu_ports+8 	; Silence Triangle
	
	rts

sound_disable:
	lda	#$00
	sta	$4015		; Disable all channels
	lda	#$01
	sta	sound_disable_flag ; Set disable flag
	rts

;;; 
;;; sound_load will preprate the sound engine to play a song or sfx.
;;; Inputs:
;;; 	A: song/sfx number to play
;;; 
sound_load:
	sta	sound_temp1	; Save song number
	asl	a		; Multiply by 2. Index into a table of pointers.
	tay
	lda	song_headers, y	; Setup the pointer to our song header
	sta	sound_ptr
	lda	song_headers+1, y
	sta	sound_ptr+1

	ldy	#$00
	lda	(sound_ptr), y	; Read the first byte: # streams
	;; Store in a temp variable. We will use this as a loop counter: how
	;; many streams to read stream headers for
	sta	sound_temp2
	iny
@loop:
	lda	(sound_ptr), y	; Stream number
	tax			; Stream number acts as our variable index
	iny

	lda	(sound_ptr), y	; Status byte. 1=enable, 0=disable
	sta	stream_status, x
	;; If status byte is 0, stream disable, so we are done
	beq	@next_stream
	iny

	lda	(sound_ptr), y	; Channel number
	sta	stream_channel, x
	iny

	lda	(sound_ptr), y	; Initial duty and volume settings
	sta	stream_vol_duty, x
	iny

	lda	(sound_ptr), y	; Initial envelope
	sta	stream_ve, x
	iny

	;; Pointer to stream data. Little endian, so low byte first
	lda	(sound_ptr), y
	sta	stream_ptr_lo, x
	iny

	lda	(sound_ptr), y
	sta	stream_ptr_hi, x
	iny

	lda	(sound_ptr), y
	sta	stream_tempo, x

	lda	#$ff
	sta	stream_ticker_total, x

	lda	#$01
	sta	stream_note_length_counter, x
	sta	stream_note_length, x

	lda	#$00
	sta	stream_ve_index, x
@next_stream:
	iny

	lda	sound_temp1	; Song number
	sta	stream_curr_sound, x

	dec	sound_temp2	; Our loop counter
	bne	@loop
	
	rts

sound_play_frame:
	lda	sound_disable_flag
	bne	@done		; If disable flag is set, dont' advance a frame

	;; Silence all channels. se_set_apu will set volumen later for all
	;; channels that are enabled. The purpose of this subroutine call is
	;; to silence all channels that aren't used by any streams
	jsr	se_silence

	ldx	#$00
@loop:
	lda	stream_status, x
	and	#$01		; Check whether the stream is active
	beq	@endloop	; If the channel isn't active, skip it

	;; Add the tempo to the ticker total.  If there is an $FF -> 0
	;; transition, there is a tick
	lda	stream_ticker_total, x
	clc
	adc	stream_tempo, x
	sta	stream_ticker_total, x
	;; Carry clear = no tick. If no tick, we are done with this stream.
	bcc	@set_buffer

	;; Else there is a tick. Decrement the note length counter
	dec	stream_note_length_counter, x
	;; If counter is non-zero, our note isn't finished playing yet
	bne	@set_buffer
	;; Else our note is finished. Reload the note length counter
	lda	stream_note_length, x
	sta	stream_note_length_counter, x
	
	jsr	se_fetch_byte
@set_buffer:
	;; Copy the current stream's sound data for the current from into our
	;; temporary APU vars (soft_apu_ports)
	jsr	se_set_temp_ports
@endloop:
	inx
	cpx	#$06
	bne	@loop
	;; Copy the temporary APU variables (soft_apu_ports) to the real
	;; APU ports ($4000, $4001, etc.)
	jsr	se_set_apu
@done:
	rts

;;;
;;; se_fetch_byte reads one byte from the sound data stream and handles it
;;; Inputs:
;;; 	X: stream number
;;; 
se_fetch_byte:
	lda	stream_ptr_lo, x
	sta	sound_ptr
	lda	stream_ptr_hi, x
	sta	sound_ptr+1

	ldy	#$00
@fetch:
	lda	(sound_ptr), y
	bpl	@note		; If < #$80, it's a Note
	cmp	#$A0
	bcc	@note_length	; Else if < #$A0, it's a Note Length
@opcode:			; Else it's an opcode
	;; Do Opcode stuff
	jsr	se_opcode_launcher
	iny			; Next position in data stream
	;; After our opcode is done, grab another byte unless the stream
	;; is disabled.
	lda	stream_status, x
	and	#%00000001
	bne	@fetch
	rts
@note_length:
	;; Do Note Length stuff
	and	#%01111111	; Chop off bit 7
	sty	sound_temp1	; Save Y because we are about to destroy it
	tay
	lda	note_length_table, y ; Get the note length count value
	sta	stream_note_length, x
	sta	stream_note_length_counter, x
	ldy	sound_temp1	; Restore Y
	iny
	jmp	@fetch		; Fetch another byte
@note:
	;; Do Note stuff
	sty	sound_temp1	; Save our index into the data stream
	asl	a
	tay
	lda	note_table, y
	sta	stream_note_lo, x
	lda	note_table+1, y
	sta	stream_note_hi, x
	ldy	sound_temp1	; Restore data stream index

	lda	#$00		; Start at beginning of envelope for new notes
	sta	stream_ve_index, x
	;; Check if it's a rest and modify the status flag appropriately
	jsr	se_check_rest
@update_pointer:
	iny
	tya
	clc
	adc	stream_ptr_lo, x
	sta	stream_ptr_lo, x
	bcc	@end
	inc	stream_ptr_hi, x
@end:
	rts


;;;
;;; se_check_rest will read a byte from the data stream and determine if
;;; it is a rest or not.  It will set our clear the current stream's
;;; rest flag accordingly.
;;; Inputs:
;;; 	X: stream number
;;; 	Y: data stream index
;;; 
se_check_rest:
	lda	(sound_ptr), y	; Read the note byte again
	cmp	#rest
	bne	@not_rest
@rest:
	lda	stream_status, x
	ora	#%00000010	; Set the rest bit in the status byte
	bne	@store		; This will always branch (cheaper than a jmp)
@not_rest:
	lda	stream_status, x
	and	#%11111101	; Clear the rest bit in the status byte
@store:
	sta	stream_status, x
	rts

;;; 
;;; se_opcode_launcher will read an address from the opcode jump table
;;; and indirect jump there.
;;; Inputs:
;;; 	A: opcode byte
;;; 	Y: data stream position
;;; 	X: stream number
;;;
se_opcode_launcher:
	sty	sound_temp1	; Save Y register
	sec
	sbc	#$A0		; Turn opcode into a table index
	asl	a		; Multiply by 2 because it's a table of words
	tay
	lda	sound_opcodes, y 	; Get the low byte
	sta	jmp_ptr
	lda	sound_opcodes+1, y 	; Get the high byte
	sta	jmp_ptr+1
	ldy	sound_temp1	; Restore Y register
	iny			; Set to next position in data stream
	jmp	(jmp_ptr)

;;;
;;; se_set_temp_ports will copy a stream's sound data to the temporary APU
;;; variables.
;;; Inputs:
;;; 	X: stream number
;;; 
se_set_temp_ports:
	lda	stream_channel, x
	;; Multiply by 4 so our index will point to the right set of registers
	asl	a
	asl	a
	tay

	;; Volume, using envelopes
	jsr	se_set_stream_volume
	
	;; Sweep
	lda	#$08
	sta	soft_apu_ports+1, y
	
	;; Period lo
	lda	stream_note_lo, x
	sta	soft_apu_ports+2, y
	
	;; Period high
	lda	stream_note_hi, x
	sta	soft_apu_ports+3, y
	
	rts

;;;
;;; se_set_stream_volume
;;; Inputs:
;;; 	X: Stream number
;;; 	Y: Index to channel in soft_apu_ports
;;;
se_set_stream_volume:
	sty	sound_temp1	; Save our index into soft_apu_ports
	
	lda	stream_ve, x	; Which volume envelope?
	asl	a		; Multiply by 2 for table of words
	tay
	lda	volume_envelopes, y ; Get the low byte of the address from table
	sta	sound_ptr
	lda	volume_envelopes+1, y ; Get the high byte of the address
	sta	sound_ptr+1

@read_ve:
	ldy	stream_ve_index, x ; Our current position within the envelope
	lda	(sound_ptr), y	   ; Grab the value
	cmp	#$ff
	bne	@set_vol	   ; Not $FF, set the volume
	dec	stream_ve_index, x ; It's $FF, go back and read last value again
	jmp	@read_ve

@set_vol:
	sta	sound_temp2	; Save our new volume value

	cpx	#TRIANGLE	; If not triangle channel, go ahead
	bne	@squares
	lda	sound_temp2	; Else if volume not zero, go ahead
	bne	@squares
	lda	#$80
	bmi	@store_vol	; Else silence the channel with #$80
@squares:
	lda	stream_vol_duty, x ; Get current vol/duty settings
	and	#$F0		   ; Zero out old volume
	ora	sound_temp2	   ; OR our new volume in

@store_vol:
	ldy	sound_temp1	; Get the index into soft_apu_ports
	sta	soft_apu_ports, y ; Store the volume in our temp port
	inc	stream_ve_index, x ; Move volume envelope index to next position

@rest_check:
	;; Check the rest flag. If set, overwrite volume with silence value.
	lda	stream_status, x
	and	#%00000010
	beq	@done		; If clear, no rest, so quit
	lda	stream_channel, x
	cmp	#TRIANGLE	; If Triangle, silence with #$80
	beq	@tri
	lda	#$30		; Square and Noise, silence with #$30
	bne	@store
@tri:
	lda	#$80
@store:
	sta	soft_apu_ports, y
@done:
	rts
	
;;; 
;;; se_set_apu copies the temporary APU variables to the real APU ports.
;;; 
se_set_apu:
@square1:
	lda	soft_apu_ports+0
	sta	$4000
	lda	soft_apu_ports+1
	sta	$4001
	lda	soft_apu_ports+2
	sta	$4002
	;; Conditionally write $4003
	lda	soft_apu_ports+3
	cmp	sound_sq1_old	; Compare to last write
	beq	@square2	; Don't write this frame if they were equal
	sta	$4003
	sta	sound_sq1_old	; Save the value we just wrote to $4003
@square2:
	lda	soft_apu_ports+4
	sta	$4004
	lda	soft_apu_ports+5
	sta	$4005
	lda	soft_apu_ports+6
	sta	$4006
	;; Conditionally write $4007, as above
	lda	soft_apu_ports+7
	cmp	sound_sq2_old
	beq	@triangle
	sta	$4007
	sta	sound_sq2_old
@triangle:
	lda	soft_apu_ports+8
	sta	$4008
	lda	soft_apu_ports+10 ; There is no $4009, so we skip it
	sta	$400a
	lda	soft_apu_ports+11
	sta	$400b
@noise:
	lda	soft_apu_ports+12
	sta	$400c
	lda	soft_apu_ports+14 ; There is no $400D, so we skip it
	sta	$400e
	lda	soft_apu_ports+15
	sta	$400f
	rts
