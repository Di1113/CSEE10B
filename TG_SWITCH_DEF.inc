;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                             TG_SWITCH_DEF.inc                              ;
;                             Switch Functions                               ;
;                   			 Teaser Game       				             ;
;                                Include File                                ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the hardware and software definitions for Teaser Game's 
; switch routines.
;   FIRSTROW, THIRDROW -> boundary to traverse through the 3 rows of the 
;                         switch array 
;   SWITCH_PORT, SWITCH_SCANNED_ROW, SWITCH_STATES, PRESSED_MASK 
;                      -> read switch states input
;   DEBOUNCE_COUNTER   -> debouncing pressed switch 
;
; Revision History:
;     5/21/19  Di Hu      initial revision
;     5/26/19  Di Hu      added CNT_BOT_VALUE for debounce function 
;     6/5/19   Di Hu      - changed filename from TGKEY to TG_SWITCH_DEF
;                         - changed constant names from SWITCH_DD to
;                           SWITCH_SCANNED_ROW, from SWITCH_PIN to 
;                           SWITCH_STATES

; Hardware definitions
.EQU    FIRSTROW = 0b00000010       ;mask of first row of switch array 
.EQU    THIRDROW = 0b00001000       ;mask of first row of switch array 
.EQU    PRESSED_MASK = 0b11110000   ;scan pressed keys in 4 columns                
.EQU    SWITCH_PORT = PORTE          ;Switches are on Port E
.EQU    SWITCH_SCANNED_ROW = DDRE    ;bit of currently-being-scanned switch 
                                     ;   row is set as output in the Data 
                                     ;   Direction Register
.EQU    SWITCH_STATES = PINE         ;shows switches' states in each column in 
                                     ;   the current scanned row

; Software definitions 
.EQU    DEBOUNCE_COUNTER = 10       ;debounce for 10 ms, one count each
									; 	interrupt call, which occurs 
									;   about once every 1 ms 
.EQU    TRUE = 0b00000001  
.EQU    FALSE = 0b00000000 
