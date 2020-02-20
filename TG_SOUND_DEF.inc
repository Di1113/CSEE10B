;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                               TG_SOUND_DEF.inc      	                     ;
;                         Sound Function Include File                        ;
;                   			  Teaser Game       				         ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the software definitions for Teaser Game's sound functions.
;   CLOCK_ON_MASK, CLOCK_OFF_MASK -> Timer 1's Control Register B's clock config
;   FOUR_MHZ -> to calculate Timer 1's OCR1A for outputting sound on PWM mode
; 
; Revision History:
;     5/31/19  Di Hu      initial revision
;     6/5/19   Di Hu      changed filename from TGSOUND to TG_SOUND_DEF

; Software definitions 
.EQU    CLOCK_ON_MASK  = 0b00000001     ;turn on Timer1 clock 
.EQU    CLOCK_OFF_MASK = 0b11111000     ;turn off Timer1 clock 
; 4 mhz in decimal = FOUR_MHZ_B2|FOUR_MHZ_B1|FOUR_MHZ_L in binary
; 4 mhz = 8 mhz / 2, since no prescaling; -1 is ingnored in calculating OCR1A
.EQU    FOUR_MHZ_L     = 0b00000000
.EQU    FOUR_MHZ_B1    = 0b00001001
.EQU    FOUR_MHZ_B2    = 0b00111101
