;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                             TG_TIMER_INIT_FUNC                             ;
;                        Timer Initialization Functions                      ;
;                                Teaser Game                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the functions for initializing the Teaser Game board's
; Timer 0 and Timer 1 by configuring Timer 0's Output Compare Register, Timer
; Counter Register, Timer Control Register, Timer Interrupt Mask Register and
; Timer 1's Timer1 Control Register A, Timer1 Control Register B.
; The public function(s) included are:
;    InitTimer0 - initialize timer 0 for interrupts for displaying LEDs and 
;                 deboucing pressed switches 
;    InitTimer1 - initialize timer 1 for playing sound from speaker
;
; Revision History of TGINIT.asm:
;     5/17/19   Di Hu      initial revision
;     5/31/19   Di Hu      added Port B and Timer1's configuration for speaker
;     6/5/19    Di Hu      initalized ports other than Port B, Port C, Port D
;
; Revision History:
;     6/5/19    Di Hu      - seperated out from initial TGINIT.asm file;
;                          - changed filename from TGTimerInit to 
;                            TG_TIMER_INIT_FUNC 

; local include files
;.include  "TG_TIMER_INIT_DEF.inc"



.cseg


; InitTimer0
;
; Description:       This function initializes timer 0 for one millisecond
;                    interrupts assuming 125 kHz clock, with prescaling clk/64: 
;                    8 mhz / 64 = 125 khz.
;
; Operation:         This function sets up timer 0 for one millisecond
;                    interrupts.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            Timer 0 is initialized.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16
; Stack Depth:       0 bytes
;
; Author:            Di Hu
; Last Modified:     May 17, 2019

InitTimer0:
                                        ;setup timer 0
        LDI     R16, TIMER0RATE         ;set the rate for timer 0
        OUT     OCR0, R16             

        CLR     R16                     ;clear the count register
        OUT     TCNT0, R16             
                                        ;now setup the control registers
        LDI     R16, TIMER0_ON
        OUT     TCCR0, R16

        IN      R16, TIMSK              ;get current timer interrupt masks
        ORI     R16, 1 << OCIE0         ;turn on timer 0 compare interrupts
        OUT     TIMSK, R16
        ;RJMP   EndInitTimer0           ;done setting up the timer


EndInitTimer0:                          ;done initializing the timer - return
        RET




; InitTimer1
;
; Description:       This function initializes Timer1 for outputting sound.
;
; Operation:         This function sets up Timer1 for making pure tunes 
;                    through OC1A register. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            Timer 1 is initialized.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Limitation:        None.
;
; Known Bugs:        None. 
;
; Registers Changed: R16
; Stack Depth:       0 bytes
;
; Author:            Di Hu
; Last Modified:     May 31, 2019

InitTimer1:
                                        ;setup timer 1
        LDI     R16, TIMER1_CA          ;set the rate for Control Register A
        OUT     TCCR1A, R16

        LDI     R16, TIMER1_CB          ;set the rate for Control Register B
        OUT     TCCR1B, R16 

        ;LDI     R16, TIMER1_CC          ;set the rate for Control Register C
        ;OUT     TCCR1C, R16              
        ;RJMP   EndInitTimer0            ;done setting up the timer


EndInitTimer1:                          ;done initializing the timer - return
        RET
