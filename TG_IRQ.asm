;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    TGIRQ                                   ;
;                         General Interrupt Handlers                         ;
;                                 Teaser Game                                ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the general interrupt handler for Timer 0.  The
; handler included is:
;    Timer0CompareHandler  - handler for timer 0 compare interrupts
;
; Revision History:
;     5/17/19   Di Hu      initial revision
;     5/23/19   Di Hu      added DebounceSwitch to time handler 
;     5/26/19   Di Hu      pushed and popped registers for 
;                          switch functions when debugging
;     6/2/19    Di Hu      pushed and popped registers for 
;                          SD card and sound functions
;     6/4/19    Di Hu      pushed and popped R1 
;     6/5/19    Di Hu      changed filename from TGIRQ to TG_IRQ

; local include files
;    none




.cseg




; Timer0CompareHandler
;
; Description:       This is the event handler for compare events on on timer
;                    0.  It calls LEDMux function.
;
; Operation:         The LED muxing function, switch debounce function, random 
;                    number generator are called.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            Turn on LEDs by calling LEDMux and debounce pressed 
;                    switches by calling DebounceSwitch. 
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R0, R1, R2, R3, R16, R17, R18, R19, R20, R21, R22, 
;                    R23, R24, R25, R26, R27, X(XH|XL), Y(YH|YL), Z(ZH|ZL)
; Stack Depth:       25 bytes
;
; Author:            Di Hu
; Last Modified:     Jun 5, 2019 

Timer0CompareHandler:

StartTimer0CompareHandler:              ;save all touched registers
        PUSH    ZH
        PUSH    ZL
        PUSH    YH
        PUSH    YL
        PUSH    XH
        PUSH    XL
        PUSH    R27
        PUSH    R26
        PUSH    R25
        PUSH    R24
        PUSH    R23
        PUSH    R22
        PUSH    R21
        PUSH    R20
        PUSH    R19
        PUSH    R18
        PUSH    R17
        PUSH    R16
        PUSH    R3
        PUSH    R2
        PUSH    R1
        PUSH    R0
        IN      R0, SREG                ;save the status register too
        PUSH    R0

DoLEDs:                                 ;handle LED muxing
        RCALL   LEDMux
        RCALL   DebounceSwitch
        RCALL   RandomNumberGenerator
        ;RJMP   DoneTimer0Compare       ;and done with the handler


DoneTimer0Compare:                      ;done with handler
        POP     R0                      ;restore flags
        OUT     SREG, R0
        POP     R0			            ;restore registers
		POP     R1
        POP     R2
        POP     R3
        POP     R16
        POP     R17
        POP     R18
        POP     R19
        POP     R20
        POP     R21
        POP     R22
        POP     R23
        POP     R24
        POP     R25
        POP     R26
        POP     R27
        POP     XL
        POP     XH
        POP     YL
        POP     YH
        POP     ZL
        POP     ZH
        RETI                            ;and return
