;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                TG_SOUND_FUNC                               ;
;                          	   Sound Functions                               ;
;                                Teaser Game              		             ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the Teaser Game board's sound function(s).
; The public function(s) included are:
;     PlayNote(f)    -   plays the note with the passed frequency (f, in Hz)
;
; Revision History:
;     5/31/19   Di Hu      initial revision
;     6/5/19    Di Hu      changed filename from TGSOUND to TG_SOUND_FUNC

; local include files
;.include  "TG_SOUND_DEF.inc"

.cseg

; PlayNote(f)
;
; Description:       This function plays the note with the passed frequency 
;                    (f, in Hz) on the speaker. This tone is output until a 
;                    new tone is output via this function. A frequency of 0 Hz
;                    (passed value is 0) turns off the speaker output. The 
;                    frequency (f) is a 16-bit value passed by value in 
;                    R17|R16 (R17 is the high byte). 
;
; Operation:         This function reads a 16-bit value from the register R17|
;                    R16, and pass the value to the frequeny calculation 
;                    function and pass the result to OCR1AH and OCR1AL.
;                    If the value read is 0, turn off the speaker by 
;                    disconnecting the clock. 
;
; Arguments:         R17|R16 - a 16-bit value to be passed into OCR1A for 
;                              producing frequency of the speaker's sound.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
;
; Input:             None. 
; Output:            Play the sound indirectly via Timer1.
;
; Error Handling:    None. Highest byte in the quotient is ignored. 
;
; Algorithms:        None.
; Data Structures:   None.
;
; Limitation:        Can play frequency from 1 Hz to 62499 Hz.
;
; Known Bugs:        None. 
;
; Registers Changed: flags, R2, R3, R16, R17, R18, R19, R20, R21, R22
; Stack Depth:       2 bytes.
;
; Author:            Di Hu
; Last Modified:     Jun 2, 2019

PlayNote:
    
CheckZeroFreq:
    MOV     R18, R16                    ;check if passed frequency is 0 
    OR      R18, R17 
    CPI     R18, 0
    BREQ    TurnOffSound                ;if is, turn off sound 
    ;BRNE    MakeSound                  ;if not, play sound

MakeSound:
    IN      R16, TCCR1B                 ;turn on the clock on timer1's control 
    ORI     R16, CLOCK_ON_MASK          ;   register to start producing sound 
    OUT     TCCR1B, R16 
    CLR     R19                         ;clear Timer1's Counter Register 
    OUT     TCNT1H, R19 
    OUT     TCNT1L, R19
    MOV     R21, R17                    ;move the frequency into divisor 
    MOV     R20, R16                    ;   for Div24by16 function
    LDI     R18, FOUR_MHZ_B2            ;set up divisor to calculate OCR1A
    LDI     R17, FOUR_MHZ_B1            ;   dividend is the passed frequency
    LDI     R16, FOUR_MHZ_L
    RCALL   Div24by16                   ;call the divison function
    OUT     OCR1AH, R17                 ;result quotient is R18|R17|1R16
    OUT     OCR1AL, R16                 ;  R18 is ignored, remainder is ignored 
	RJMP 	EndPlayNote

TurnOffSound:
    IN      R16, TCCR1B                 ;turn off the sound by turning off
    ANDI    R16, CLOCK_OFF_MASK         ;   the clock on timer's control 
                                        ;   register
    OUT     TCCR1B, R16 
    ;RJMP    EndPlayNote 

EndPlayNote:
    RET


; local include file 
;.include "div.asm"
