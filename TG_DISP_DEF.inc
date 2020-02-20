;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                               TG_DISP_DEF.inc                              ;
;                            Hardware Include File                           ;
;                                Teaser Game                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the hardware and assembly language definitions for the 
; Teaser Game's display functions.
;
; Revision History:
;     5/17/19  Di Hu      initial revision;
;                         fixed DIGIT_PORT and SEGMENT_PORT's wrong IO port
;                         connections
;     6/5/19   Di Hu      - changed several Digit/LED definition names, and 
;                           modified comments with more specific descriptions;
;                         - changed filename from TGDISP to TG_DISP_DEF 

; Display Definitions


; General Hardware Definitions

.EQU	NUM_LED_DIGITS = 7              ;number of LED digits
.EQU	NUM_NUM_DIGITS = 4              ;number of numerical digits
.EQU	FIRST_DIGIT = 3		            ;first numerical digit on the buffer
.EQU 	LOSE_DIGIT = 1					;digit contains Lose LED on the buffer
.EQU 	WIN_DIGIT = 0					;digit contains Win LED on the buffer
.EQU 	SWITCH_DIGIT_ONE = 1			;digit contains Switch8 to Switch12
.EQU 	SWITCH_DIGIT_ZERO = 0			;digit contains Switch2 to Switch7

; Specific Digit/LED Definitions

.EQU	LED_BLANK       = 0b00000000    ;blank LEDs
.EQU    DIGITS_OFF      = 0b00000000    ;turn off all LEDs
.EQU	BIN_TO_HEX_NIBBLE_MASK = 0b00001111  ;used in DisplayHex(n)
.EQU	SWITCHLED_MASK  = 0b1001011110011111 ;LED pattern for 11 switches 
.EQU	LOSE_LED_MASK	= 0b01000000	;turns on Lose LED bit
.EQU	WIN_LED_MASK    = 0b01000000	;turns on Win LED bit
.EQU	INIT_DIG_PATT   = 0b00000001	;initial digit drive pattern

; Port Definitions

.EQU	DIGIT_PORT = PORTD				;LED digits are on port C
.EQU	SEGMENT_PORT = PORTC			;LED segments are on port D
