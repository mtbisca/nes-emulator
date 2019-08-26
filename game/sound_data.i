song0_header:
    .byte $06           ;6 streams
    
    .byte MUSIC_SQ1     ;which stream
    .byte $00           ;status byte (stream disabled)
    
    .byte MUSIC_SQ2     ;which stream
    .byte $00           ;status byte (stream disabled)
    
    .byte MUSIC_TRI     ;which stream
    .byte $00           ;status byte (stream disabled)
    
    .byte MUSIC_NOI     ;which stream
    .byte $00           ;disabled.
    
    .byte SFX_1         ;which stream
    .byte $00           ;disabled

    .byte SFX_2         ;which stream
    .byte $00           ;disabled


song1_header:
    .byte $04           ;4 streams
    
    .byte MUSIC_SQ1     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_1      ;which channel
    .byte $70           ;initial duty (01)
    .byte ve_tgl_1      ;volume envelope
    .word song1_square1 ;pointer to stream
    .byte $53           ;tempo
    
    .byte MUSIC_SQ2     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2      ;which channel
    .byte $B0           ;initial duty (10)
    .byte ve_tgl_2      ;volume envelope
    .word song1_square2 ;pointer to stream
    .byte $53           ;tempo
    
    .byte MUSIC_TRI     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte TRIANGLE      ;which channel
    .byte $80           ;initial volume (on)
    .byte ve_tgl_2      ;volume envelope
    .word song1_tri     ;pointer to stream
    .byte $53           ;tempo
    
    .byte MUSIC_NOI     ;which stream
    .byte $00           ;disabled.  Our load routine will skip the
                        ;   rest of the reads if the status byte is 0.
                        ;   We are disabling Noise because we haven't covered it yet.
    
song1_square1:
    .byte eighth
    .byte A2, A2, A2, A3, A2, A3, A2, A3
    .byte F3, F3, F3, F4, F3, F4, F3, F4
    .byte A2, A2, A2, A3, A2, A3, A2, A3
    .byte F3, F3, F3, F4, F3, F4, F3, F4
    .byte E3, E3, E3, E4, E3, E4, E3, E4
    .byte E3, E3, E3, E4, E3, E4, E3, E4
    .byte Ds3, Ds3, Ds3, Ds4, Ds3, Ds4, Ds3, Ds4
    .byte D3, D3, D3, D4, D3, D4, D3, D4
    .byte C3, C3, C3, C4, C3, C4, C3, C4
    .byte B2, B2, B2, B3, B2, B3, B2, B3
    .byte As2, As2, As2, As3, As2, As3, As2, As3
    .byte A2, A2, A2, A3, A2, A3, A2, A3
    .byte Gs2, Gs2, Gs2, Gs3, Gs2, Gs3, Gs2, Gs3
    .byte G2, G2, G2, G3, G2, G3, G2, G3
    .byte loop
    .word song1_square1


    
song1_square2:
    .byte sixteenth
    .byte rest    ;offset for delay effect
    .byte eighth
@loop_point:
    .byte rest
    .byte A4, C5, B4, C5, A4, C5, B4, C5
    .byte A4, C5, B4, C5, A4, C5, B4, C5
    .byte A4, C5, B4, C5, A4, C5, B4, C5
    .byte A4, C5, B4, C5, A4, C5, B4, C5
    .byte Ab4, B4, A4, B4, Ab4, B4, A4, B4
    .byte B4, E5, D5, E5, B4, E5, D5, E5
    .byte A4, Eb5, C5, Eb5, A4, Eb5, C5, Eb5
    .byte A4, D5, Db5, D5, A4, D5, Db5, D5
    .byte A4, C5, F5, A5, C6, A5, F5, C5
    .byte Gb4, B4, Eb5, Gb5, B5, Gb5, Eb5, B4
    .byte F4, Bb4, D5, F5, Gs5, F5, D5, As4
    .byte E4, A4, Cs5, E5, A5, E5, sixteenth, Cs5, rest
    .byte eighth
    .byte Ds4, Gs4, C5, Ds5, Gs5, Ds5, C5, Gs4
    .byte sixteenth
    .byte G4, Fs4, G4, Fs4, G4, Fs4, G4, Fs4
    .byte eighth
    .byte G4, B4, D5, G5
    .byte loop
    .word @loop_point
    
song1_tri:
    .byte eighth
    .byte A5, C6, B5, C6, A5, C6, B5, C6 ;triangle data
    .byte A5, C6, B5, C6, A5, C6, B5, C6
    .byte A5, C6, B5, C6, A5, C6, B5, C6
    .byte A5, C6, B5, C6, A5, C6, B5, C6
    .byte Ab5, B5, A5, B5, Ab5, B5, A5, B5
    .byte B5, E6, D6, E6, B5, E6, D6, E6
    .byte A5, Eb6, C6, Eb6, A5, Eb6, C6, Eb6
    .byte A5, D6, Db6, D6, A5, D6, Db6, D6
    .byte A5, C6, F6, A6, C7, A6, F6, C6
    .byte Gb5, B5, Eb6, Gb6, B6, Gb6, Eb6, B5
    .byte F5, Bb5, D6, F6, Gs6, F6, D6, As5
    .byte E5, A5, Cs6, E6, A6, E6, Cs6, A5
    .byte Ds5, Gs5, C6, Ds6, Gs6, Ds6, C6, Gs5
    .byte sixteenth
    .byte G5, Fs5, G5, Fs5, G5, Fs5, G5, Fs5
    .byte G5, B5, D6, G6, B5, D6, B6, D7
    .byte loop
    .word song1_tri


song2_header:
    .byte $01          ;1 stream
    
    .byte SFX_1         ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2      ;which channel
    .byte $70           ;duty (01)
    .byte ve_battlekid_1b   ;volume envelope
    .word song2_square2 ;pointer to stream
    .byte $80           ;tempo


    
    
song2_square2:
    .byte eighth, D3, D2
    .byte endsound

	

song3_header:
    .byte $04           ;4 streams
    
    .byte MUSIC_SQ1     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_1      ;which channel
    .byte $B0           ;initial duty (10)
    .byte ve_tgl_1      ;volume envelope
    .word song3_square1 ;pointer to stream
    .byte $40           ;tempo
    
    .byte MUSIC_SQ2     ;which stream
    .byte $00           ;status byte (stream disabled)
    
    .byte MUSIC_TRI     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte TRIANGLE      ;which channel
    .byte $81           ;initial volume (on)
    .byte ve_tgl_2      ;volume envelope
    .word song3_tri     ;pointer to stream
    .byte $40           ;tempo
    
    .byte MUSIC_NOI     ;which stream
    .byte $00           ;disabled.  Our load routine will skip the
                        ;   rest of the reads if the status byte is 0.
                        ;   We are disabling Noise because we haven't covered it yet.
    
song3_square1:
    .byte eighth
    .byte D4, A4, F4, A4, D4, B4, G4, B4
    .byte D4, C5, A4, C5, D4, As4, F4, As4
    .byte E4, A4, E4, A4, D4, A4, Fs4, A4
    .byte D4, A4, Fs4, A4, G4, As4, A4, C5
    .byte D4, C5, A4, C5, D4, B4, G4, B4
    .byte D4, B4, G4, B4, D4, As4, Gs4, As4
    .byte Cs4, A4, E4, A4, D4, A4, E4, A4
    .byte Cs4, A4, E4, A4, B3, A4, Cs4, A4
    .byte loop
    .word song3_square1
        
song3_tri:
    .byte quarter, D6, A6, d_half, G6
    .byte eighth, F6, E6, quarter, D6
    .byte eighth, C6, As5, C6, A5
    .byte quarter, E6, d_whole, D6
    .byte quarter, A6, C7, d_half, B6
    .byte eighth, G6, F6, quarter, E6
    .byte eighth, F6, G6, whole, A6, A6
    .byte loop
    .word song3_tri



song4_header:
    .byte $04           ;4 streams
    
    .byte MUSIC_SQ1     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_1      ;which channel
    .byte $B0           ;initial duty (10)
    .byte ve_battlekid_2b  ;volume envelope
    .word song4_square1 ;pointer to stream
    .byte $B0         ;tempo
    
    .byte MUSIC_SQ2     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2      ;which channel
    .byte $30           ;initial duty (00)
    .byte ve_short_staccato ;volume envelope
    .word song4_square2 ;pointer to stream
    .byte $B0           ;tempo
    
    .byte MUSIC_TRI     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte TRIANGLE      ;which channel
    .byte $81           ;initial volume (on)
    .byte ve_battlekid_2b  ;volume envelope
    .word song4_tri     ;pointer to stream
    .byte $B0           ;tempo
    
    .byte MUSIC_NOI     ;which stream
    .byte $00           ;disabled.  Our load routine will skip the
                        ;   rest of the reads if the status byte is 0.
                        ;   We are disabling Noise because we haven't covered it yet.
                        
song4_square1:
    .byte half, E4, quarter, G4, eighth, Fs4, E4, d_sixteenth, Eb4, E4, Fs4, t_quarter, rest, half, rest
    .byte       Fs4, quarter, A4, eighth, G4, Fs4, d_sixteenth, E4, Fs4, G4, t_quarter, rest, half, rest
    .byte       G4, quarter, B4, eighth, A4, G4, quarter, A4, B4, C5, eighth, B4, A4
    .byte       B4, A4, G4, Fs4, Eb4, E4, Fs4, G4, Fs4, E4, d_half, rest
    .byte loop
    .word song4_square1
    
song4_square2:
    .byte quarter
    .byte E3, B3, B3, B3, B2, Fs3, Fs3, Fs3
    .byte Fs3, A3, A3, A3, B2, E3, E3, E3
    .byte E3, B3, B3, B3, B3, A3, G3, Fs3
    .byte E3, B3, A3, Fs3, E3, E3, E3, E3;d_half, rest
    .byte loop
    .word song4_square2
    
song4_tri:
    .byte half, E4, G4, B3, Eb4
    .byte Fs4, A4, B3, E4
    .byte G4, B4, quarter, A4, B4, half, C5
    .byte eighth, E4, Fs4, G4, A4, B3, C4, D4, Eb4, A3, E4, d_half, rest
    .byte loop
    .word song4_tri
    
    	
song5_header:
    .byte $01           ;1 stream
    
    .byte SFX_1         ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2      ;which channel
    .byte $70           ;initial duty (01)
    .byte ve_short_staccato ;volume envelope
    .word song5_square2 ;pointer to stream
    .byte $FF           ;tempo..very fast tempo
    
    
song5_square2:
    .byte thirtysecond, C4, D8, C5, D7, C6, D6, C7, D5, C8, D8 ;some random notes played very fast
    .byte endsound


song6_header:
    .byte $04           ;4 streams
    
    .byte MUSIC_SQ1     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_1      ;which channel
    .byte $30           ;initial duty (01)
    .byte ve_battlekid_1      ;volume envelope
    .word song6_square1 ;pointer to stream
    .byte $4C           ;tempo
    
    .byte MUSIC_SQ2     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2      ;which channel
    .byte $30           ;initial duty (10)
    .byte ve_battlekid_2      ;volume envelope
    .word song6_square2 ;pointer to stream
    .byte $4C           ;tempo
    
    .byte MUSIC_TRI     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte TRIANGLE      ;which channel
    .byte $80           ;initial volume (on)
    .byte ve_short_staccato    ;volume envelope
    .word song6_tri     ;pointer to stream
    .byte $4C           ;tempo
    
    .byte MUSIC_NOI     ;which stream
    .byte $00           ;disabled.  Our load routine will skip the
                        ;   rest of the reads if the status byte is 0.
                        ;   We are disabling Noise because we haven't covered it yet.
                        
song6_square1:
    .byte sixteenth
    .byte A3, C4, E4, A4, A3, C4, E4, A4, A3, C4, E4, A4, A3, C4, E4, A4
    .byte A3, C4, E4, A4, A3, C4, E4, A4, A3, C4, E4, A4, A3, C4, E4, A4
    .byte A3, C4, E4, A4, A3, C4, E4, A4, A3, C4, E4, A4, A3, C4, E4, A4
    .byte A3, C4, E4, A4, A3, E4, E3, E2
    
    .byte duty, $B0
    .byte volume_envelope, ve_battlekid_1b
    .byte quarter, E4, E3
    
    .byte duty, $70
    .byte five_eighths, A3
    .byte eighth, B3, C4, D4
    .byte sixteenth, Ds4
    .byte five_sixteenths, E4 ;original probably uses a slide effect.  I fake it here with odd note lengths
    .byte d_quarter, A3
    .byte quarter, D4
    .byte five_eighths, A3
    .byte eighth, B3, C4, D4, C4, B3, A3
    .byte quarter, G3, E3
    .byte eighth, B3
    
    .byte five_eighths, A3
    .byte eighth, B3, C4, D4
    .byte sixteenth, Ds4
    .byte five_sixteenths, E4
    .byte d_quarter, A3
    .byte quarter, D4
    .byte five_eighths, A3
    .byte eighth, B3, C4, D4, C4, B3, A3
    .byte quarter, E4, E3
    .byte eighth, E3
    
    .byte duty, $30
    .byte volume_envelope, ve_battlekid_1
    
    .byte loop
    .word song6_square1
    
song6_square2:
    .byte sixteenth
    .byte rest
@loop_point:
    .byte A3, C4, E4, A4, A3, C4, E4, A4, A3, C4, E4, A4, A3, C4, E4, A4
    .byte A3, C4, E4, A4, A3, C4, E4, A4, A3, C4, E4, A4, A3, C4, E4, A4
    .byte A3, C4, E4, A4, A3, C4, E4, A4, A3, C4, E4, A4, A3, C4, E4, A4
    .byte A3, C4, E4, A4, A3, E4, E3, E2
    
    .byte duty, $B0
    .byte volume_envelope, ve_battlekid_2b
    .byte quarter, E4, E3
    
    .byte duty, $70
    .byte five_eighths, A3
    .byte eighth, B3, C4, D4
    .byte sixteenth, Ds4
    .byte five_sixteenths, E4
    .byte d_quarter, A3
    .byte quarter, D4
    .byte five_eighths, A3
    .byte eighth, B3, C4, D4, C4, B3, A3
    .byte quarter, G3, E3
    .byte eighth, B3
    
    .byte five_eighths, A3
    .byte eighth, B3, C4, D4
    .byte sixteenth, Ds4
    .byte five_sixteenths, E4
    .byte d_quarter, A3
    .byte quarter, D4
    .byte five_eighths, A3
    .byte eighth, B3, C4, D4, C4, B3, A3
    .byte quarter, E4, E3
    .byte eighth, E3
    
    .byte duty, $30
    .byte volume_envelope, ve_battlekid_2
    .byte sixteenth
    .byte loop
    .word @loop_point
    
song6_tri:
    .byte eighth
    .byte A3, A3, A4, A4, A3, A3, A4, A4
    .byte G3, G3, G4, G4, G3, G3, G4, G4
    .byte F3, F3, F4, F4, F3, F3, F4, F4
    .byte Eb3, Eb3, Eb4, Eb4, Eb3, Eb3, Eb4, Eb4
    .byte loop
    .word song6_tri


song7_header:
    .byte $01           ;1 stream
    
    .byte SFX_1         ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2      ;which channel
    .byte $70           ;initial duty (01)
    .byte ve_short_staccato ;volume envelope
    .word song7_square2 ;pointer to stream
    .byte $FF           ;tempo..very fast tempo


song7_square2:
    .byte set_loop1_counter, $08    ;repeat 8 times
@loop:
    .byte thirtysecond, D7, D6, G6      ;play two D notes at different octaves
    .byte adjust_note_offset, -4     ;go down 2 steps
    .byte loop1
    .word @loop
    .byte endsound
           
song8_header:
    .byte $06           ;6 streams
    
    .byte SFX_1     ;which stream
    .byte $00           ;status byte (stream disabled)
    
    .byte MUSIC_SQ2     ;which stream
    .byte $00           ;status byte (stream disabled)
    
    .byte MUSIC_TRI     ;which stream
    .byte $00           ;status byte (stream disabled)
    
    .byte MUSIC_NOI     ;which stream
    .byte $00           ;disabled.

    .byte MUSIC_SQ1         ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_1      ;which channel
    .byte $B0           ;initial duty (10)
    .byte ve_battlekid_1b  ;volume envelope
    .word song8_square1 ;pointer to stream
    .byte $75          ;tempo
    
    .byte SFX_2         ;which stream
    .byte $00           ;disabled
                             
song8_square1:
    .byte eighth, C6,rest ,eighth, G5,rest, eighth, E5,sixteenth, E5, eighth, A5,eighth,B5,eighth, A5,sixteenth,A5, eighth,Gs5,sixteenth,Gs5,eighth,As5,sixteenth,As5
    .byte eighth,Gs5,sixteenth,Gs5,sixteenth, G5,thirtysecond, G5,eighth,F5,quarter, G5

        .byte endsound

     
song9_header:
    .byte $06           ;6 streams
    
    .byte MUSIC_SQ1     ;which stream
    .byte $00           ;status byte (stream disabled)
    
    .byte MUSIC_SQ2     ;which stream
    .byte $00           ;status byte (stream disabled)
    
    .byte MUSIC_TRI     ;which stream
    .byte $00           ;status byte (stream disabled)
    
    .byte MUSIC_NOI     ;which stream
    .byte $00           ;disabled.

    .byte MUSIC_SQ1         ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_1      ;which channel
    .byte $B0           ;initial duty (10)
    .byte ve_tgl_2  	  ;volume envelope
    .word song9_square1 ;pointer to stream
    .byte $70          ;tempo
    
    .byte SFX_2         ;which stream
    .byte $00           ;disabled
                             
song9_square1:

    .byte volume_envelope, ve_fade_in
    .byte sixteenth, E4,sixteenth, A4,sixteenth, Cs5,sixteenth, E5
    .byte sixteenth, A5 ,sixteenth, Cs6
    .byte quarter , E6, quarter , Cs6,sixteenth, Cs6, sixteenth,rest
    
    
    .byte volume_envelope, ve_fade_in
    .byte sixteenth, F4,sixteenth, A4,sixteenth, C5,sixteenth, F5
    .byte sixteenth, C6 ,sixteenth, Ds6
    .byte quarter , Gs6, quarter , Ds6, sixteenth , Ds6,sixteenth,rest

    .byte sixteenth, As4,sixteenth, D5,sixteenth, F5,sixteenth, As5
    .byte sixteenth, D6 ,sixteenth, F6
    .byte eighth , As6
    
    .byte volume_envelope, ve_battlekid_1b 
    .byte sixteenth, As6,rest,sixteenth, As6,rest,thirtysecond, As6,rest,thirtysecond, As6,rest,quarter, C7 

    .byte endsound