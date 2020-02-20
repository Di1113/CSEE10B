;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              TG_UTIL_FUNC                                  ;
;                            Utility Functions                               ;
;                               Teaser Game                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains utility functions for assisting the main loop of Teaser Game. 
; These functions each perform some action and return a game state flag to 
; main loop to go to next action.
; The public functions included are:
;    Delay16        - 
;    RandomNumberGenerator - 
;
;
; The local functions included are:
;    WriteByte(b)       - write a byte to the SD card
;    ReadByte           - read a byte from the SD card
;    CheckIllegalCommand(r) - check if the Illegal Command bit is set
;    SendCommand(c)     - send 6-bytes command to SD card and check responses
;    WaitToGetResponse  - wait for SD card to return a response
;    SendDataBlock(p, n)- send a data block to the SD card
;    WaitToReceiveData(p, n) - read a data block from the SD card
;    WaitForBusyToEndOnWrite - wait for busy state to end when writing
;
; Revision History:  
;    6/9/19      Di Hu       Initial Revision 
;    6/10/19     Di Hu       Seperated table look up process from WaitToGetKeyState and MakeMove to sub-functions. 
;                            Seperated RandomNumberGenerator, Delay16 to TG_UTIL.asm
;                            Modified stateFlag to a shared varaible, set R18 as stateFlag's return register 

; local include files
;.include  "TG_SDCARD_DEF.inc"



.cseg




; Delay16
;
; Description:       This procedure delays the number of clocks passed in R16
;                    times 80000.  Thus with a 8 MHz clock the passed delay is
;                    in 10 millisecond units.
;
; Operation:         The function just loops decrementing Y until it is 0.
;
; Arguments:         R16 - 1/80000 the number of CPU clocks to delay.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, Y (YH | YL)
; Stack Depth:       0 bytes
;
; Author:            Glen George
; Last Modified:     May 6, 2018

Delay16:

Delay16Loop:                ;outer loop runs R16 times
    LDI     YL, LOW(20000)      ;inner loop is 4 clocks
    LDI     YH, HIGH(20000)     ;so loop 20000 times to get 80000 clocks
Delay16InnerLoop:           ;do the delay
    SBIW    Y, 1
    BRNE    Delay16InnerLoop

    DEC     R16         ;count outer loop iterations
    BRNE    Delay16Loop


DoneDelay16:                ;done with the delay loop - return
    RET







; RandomNumberGenerator 
;
; Description:       This function generates a 16-bit pseudo random value in the 
;                    RandomBuffer for RandomReset to use. This function should be 
;                    called on 1 ms interval. 
;
; Operation:         This function generates a pseudo random value using 
;                    Galois LFSR algorithm by loading the old RandomBuffer value
;                    to R17|R16, update R17|R16 and store it back to 
;                    RandomBuffer.
;
; Arguments:         RandomBuffer - the old random value. 
; Return Value:      RandomBuffer - a new random value. 
;
; Local Variables:   None.
; Shared Variables:  RandomBuffer - read and written - update to new random 
;                               value by applying Galois LFSR to the old value.
;                     
; Global Variables:  None.
;
; Input:             None.
; Output:            None.  
;
; Error Handling:    None.  
;
; Algorithms:        Galois LFSR
; Data Structures:   None.
;
; Limitation:        None.
;
; Known Bugs:        None. 
;
; Registers Changed: flags, R16, R17
; Stack Depth:       0 bytes. 
;
; Author:            Di Hu
; Last Modified:     June 8, 2019


; called by interrupt handler 
RandomNumberGenerator:
    
    LDS     R17, randomCounter
    TST     R17
    BRNE    GeneratedOnce
    ;BREQ   FirstGeneration 

FirstGeneration:
    LDI     R16, 1
    LDI     YL, LOW(randomBuffer)
    LDI     YH, HIGH(randomBuffer) 
    ST      Y+, R17
    ST      Y, R16
    STS     randomCounter, R16 

GeneratedOnce:
    LDI     YL, LOW(randomBuffer)
    LDI     YH, HIGH(randomBuffer) 
    LD      R17, Y+
    LD      R16, Y 
    MOV     R18, R16
    MOV     R19, R17

    LSL     R17
    ROL     R16
    CLR     R18
    ADC     R17, R18

    ANDI    R18, LOW(TWO_BYTE_LSFR_AND_MASK)
    ANDI    R19, HIGH(TWO_BYTE_LSFR_AND_MASK)
    BREQ    EndGenRandomNumber 
    ;BRNE    ApplyLsfrXorMask

ApplyLsfrXorMask: 
    LDI     R18, LOW(TWO_BYTE_LSFR_XOR_MASK)
    LDI     R19, HIGH(TWO_BYTE_LSFR_XOR_MASK)
    EOR     R16, R18
    EOR     R17, R19 
    ;RJMP    EndGenRandomNumber

EndGenRandomNumber:
    LDI     YL, LOW(randomBuffer)
    LDI     YH, HIGH(randomBuffer) 
    ST      Y+, R17
    ST      Y, R16
    RET 