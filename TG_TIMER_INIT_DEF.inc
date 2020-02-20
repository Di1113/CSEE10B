;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                            TG_TIMER_INIT_DEF.inc                           ;
;                            Hardware Include File                           ;
;                                Teaser Game                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the hardware definitions for Teaser Game's Timer 0 and 
; Timer 1 initialization:
;   TIMER0_ON  -> Timer 0 Timer Control Register
;   TIMER0RATE -> Timer 0 Output Compare Register
;   TIMER1_CA  -> Timer1 Control Register A
;   TIMER1_CB  -> Timer1 Control Register B
;
; Revision History of TGINIT.inc:
;     5/15/19  Di Hu      initial revision
;     5/17/19  Di Hu      modified prescaling option for TIMER0_ON
;     5/26/19  Di Hu      modified Timer0's control register
;     5/31/19  Di Hu      added PortB and Timer1's configuration for speaker

; Revision History:
;     6/5/19   Di Hu      - seperated out from initial TGINIT.inc file
;                         - changed filename from TGTimerInit to 
;                           TG_TIMER_INIT_DEF 

; setup values for Timer 0
.EQU    TIMER0_ON  = 0b00001100      ;turn on timer 1
                    ;  0-------      CM is not forced immediately
                    ;  -0--1---      CTC mode
                    ;  --00----      OC0 is disconnected
                    ;  -----100      clkT0S/64 

.EQU    TIMER0RATE = 124        ;  With prescaling, 8 mhz / 64 = 125 khz
                                ;  1 ms assuming 125 kHz clock
                                ;  note that the timer resets on the clock
                                ;  after the compare match so this count
                                ;  needs to be one less than clocks/ms

; setup values for Timer 1  
.EQU    TIMER1_CA = 0b01000000      ;configure Timer1's OCR in channel A 
                   ;  01------      Toggle OC1A on Compare Match
                   ;  --00----      Compare Output Mode for Channel B is off
                   ;  ----00--      Compare Output Mode for Channel C is off
                   ;  ------00      Waveform Gerneration Mode 4 - CTC 
.EQU    TIMER1_CB = 0b00001001
                   ;  0-------      Input Capture Noise Canceler deactivated
                   ;  -0------      Falling edge will trigger event capturing 
                   ;  --------      - 
                   ;  ---01---      Waveform Gerneration Mode 4 - CTC
                   ;  -----001      clkT0S/1, no prescaling