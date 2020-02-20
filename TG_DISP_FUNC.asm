;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                TG_DISP_FUNC                                ;
;                              Display Routines                              ;
;                                Teaser Game                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the functions for displaying Win, Lose LEDs, 4-digit 
; display LED and 11 Switch LEDs on the Teaser Game board.
; The public functions included are:
;    ClearDisplay       - reset all the display
;    DisplayHex(n)      - display the passed hex value on 4-digits LED display
;    DisplayLose(b)     - display the passed status of Lose LED
;    DisplayWin(b)      - display the passed status of Win LED
;    DisplaySwitchLEDs(m)    - display the passed status of 11 switch LEDs
;    LEDMux             - multiplex the LED display
;
; The local function included is:
;    InitLEDMux         - initialize variables for LED multiplexing
;
; Revision History:
;     5/15/19   Di Hu     initial revision
;     5/17/19   Di Hu     added DisplayHex(n) functions and more 
;     6/5/19    Di Hu     - changed several Digit/LED definition names, and 
;                           modified comments with more specific descriptions;
;                         - added ClearDisplay to the end of InitLEDMux;
;                         - updated DisplaySwitchLEDs function to have the 
;                           Win, Lose LEDs remain the same;    
;                         - added format and content description for 
;                           currentDigits 
;                         - changed filename from TGDISP to TG_DISP_FUNC 



; local include files
;.include  "TG_DISP_DEF.inc"




.cseg




; ClearDisplay
; 
; Description:          This function clears the display.
; 
; Operation:            This function turns off 4-Digit LED, LEDs for Win and 
;                       Lose, LEDs for 11 switches.
;
; Arguments:            None.
; Return Value:         None.
;
; Global Variables:     None.
;
; Local Variables:      R16 - digit counter.
;                       Y   - pointer to display buffer.
; Shared Variables:     currentDigits - written - filled with LED_BLANK.
;
; Inputs:               None.
; Outputs:              Turn off the LEDs(indirectly via LEDmux and Timer0). 
;
; Error Handling:       None.
;
; Algorithms:           None.
; Data Structures:      None.
;
; Limitation:           None.
;
; Known Bugs:           None. 
;
; Registers Changed:    flags, R16, R17, Y (YH | YL)
; Stack Depth:          0 bytes
;
; Author:               Di Hu
; Last Modified:        May 15, 2019 

ClearDisplay:


StartClearDisplay:                      ;start clearing the display
    LDI     R16, NUM_LED_DIGITS         ;number of digits to clear
    LDI	    YL, LOW(currentDigits)      ;point to the digits
    LDI	    YH, HIGH(currentDigits)
    LDI     R17, LED_BLANK              ;get the blank digit pattern

InitBuffLoop:				            ;loop clearing the digits
    ST	    Y+, R17			            ;clear the digit
    DEC	    R16			                ;update loop counter
    BRNE	InitBuffLoop		        ;and loop until done
    ;BREQ   EndClearDisplay             ;then initialization finished

EndClearDisplay:                        ;done clearing the display - return
    RET




; DisplayHex(n)
;
; Description:       This function displays a 16-bit unsigned value in 
;                    hexadecimal in the 4-digit LED display. There will be  
;                    leading 0s if only some lower digits are used.
;
; Operation:         This function reads the 16-bit unsigned value from the  
;                    register one nibble at a time and display the nibble's  
;                    value in hexadecimal in its corresponding digit location on 
;                    the 4-digit LED display.
;
; Arguments:         R17|R16 - a 16-bit unsigned value to be translated into 
;                    hexadecimal and displayed.
;                    
; Return Value:      None.
;
; Local Variables:   R0  - table loop up result value
;                    R18 - digit counter    
;                    R19 - digit value for digit pattern table look up
;                    Y   - pointer to digit (display) buffer.
;                    Z   - pointer to digit pattern table.
;
; Shared Variables:  currentDigits - written - buffer is filled with passed 
;                    value in hexadecimal.
; Global Variables:  None.
;
; Input:             None.
; Output:            The passed value is output to the LED display 
;                    (indirectly via LEDMux amd Timer 0).
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R0, R16, R17, R18, R19, R20, R21, Y (YH | YL),
;                    Z (ZH | ZL)
; Stack Depth:       0 bytes
;
; Author:            Di Hu
; Last Modified:     Jun 5, 2019 

DisplayHex:


StartDisplayHex:                        ;start displaying the hexadecimal number
    LDI     R18, NUM_NUM_DIGITS         ;number of digits to display
    LDI     R20, 0                      ;for propagating carries
    LDI     YL, LOW(currentDigits) + FIRST_DIGIT     ;setup for storing digit
    LDI     YH, HIGH(currentDigits)     ;point to the first digit number's buffer
    ;RJMP   DisplayDigitLoop            ;now display the digits

DisplayDigitLoop:                       ;loop displaying the digits
    LDI     R19, BIN_TO_HEX_NIBBLE_MASK ;always load the right-most 4 bits
    AND     R19, R16                    ;load the low 4 bits of R16
    LDI     ZL, LOW(2 * DigitSegTable)  ;get start of segment pattern table
    LDI     ZH, HIGH(2 * DigitSegTable) ;times 2 to do byte addressing
    ADD     ZL, R19                     ;nibble value is the offset for 
    ADC     ZH, R20                     ;  getting seg. pattern in DigitSegTable
    LPM                                 ;lookup the segment pattern, load to R0
    ;RJMP   DisplayDigit              ;store the segment pattern to digit buffer

DisplayDigit:                          ;store the segment pattern for this digit
    ST      Y+, R0 

EndDisplayDigitLoop:
    LSR     R17                         ;move the next digit into place
    ROR     R16                         ;each HEX digit is 4 bits
    LSR     R17
    ROR     R16
    LSR     R17
    ROR     R16
    LSR     R17
    ROR     R16

    DEC     R18                         ;update digit count
    
CheckDigitLoopEnd:
    BRNE    DisplayDigitLoop            ;loop until do all the digits
    ;BREQ   EndDisplayHex               ;done with displaying hex 

EndDisplayHex:                          ;done with displaying hex 
    RET




; DisplayLose(b)
;
; Description:       This function displays the passed Lose LED status on the
;                    Lose LED.  A non-zero (TRUE) value turns on the Lose
;                    LED, a zero (FALSE) value turns it off.  The actual
;                    outputting of the Lose LED is done by the LEDMux
;                    routine.
;
; Operation:         The Lose bit in the LOSE_DIGIT is set or reset based
;                    on the passed value in R16.
;
; Arguments:         R16 - Lose LED status to which to set the Lose LED 
;                          If R16 is TRUE, turn on the LED; else, turn off.
;
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentDigits - LOSE_DIGIT element has a bit changed.
; Global Variables:  None.
;
; Input:             None.
; Output:            The Lose LED is turned on or off as indicated by passed 
;                    argument(indirectly via LEDMux and Timer 0).
;                    
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, R17
; Stack Depth:       0 bytes
;
; Author:            Di Hu
; Last Modified:     May 17, 2019

DisplayLose:


    LDS	    R17, currentDigits + LOSE_DIGIT ;get current LED state

TestR16:
    TST     R16
    BREQ    LoseLEDOff                     ;passed status is FALSE, turn off LED
    ;BRNE   LoseLEDOn               ;else the passed status is True, turn on LED

LoseLEDOn:
    ORI     R17, LOSE_LED_MASK                ;turn on the Lose LED
    RJMP    EndDisplayLose

LoseLEDOff:
    ANDI    R17, ~LOSE_LED_MASK               ;turn off the Lose LED
    ;RJMP   EndDisplayLose                    ;done turning on the Lose bit

EndDisplayLose:                               ;done so return
    STS     currentDigits + LOSE_DIGIT, R17   ;store the new Lose bit
    RET





; DisplayWin(b)
;
; Description:       This function displays the passed Win LED status on the
;                    Win LED.  A non-zero (TRUE) value turns on the Win
;                    LED, a zero (FALSE) value turns it off.  The actual
;                    outputting of the Win LED is done by the LEDMux
;                    routine.
;
; Operation:         The Win bit in the WIN_DIGIT is set or reset based
;                    on the passed value in R16.
;
; Arguments:         R16 - Win LED status to which to set the Win LED.
;                          If R16 is TRUE, turn on the LED; else, turn off.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentDigits - WIN_DIGIT element has a bit changed.
; Global Variables:  None.
;
; Input:             None.
; Output:            The Win LED is turned on or off (indirectly via LEDMux)
;                    as indicated by passed argument.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, R17
; Stack Depth:       0 bytes
;
; Author:            Di Hu
; Last Modified:     May 17, 2019

DisplayWin:


    LDS     R17, currentDigits + WIN_DIGIT   ;get current LED state

TestArg:
    TST     R16 
    BREQ    WinLEDOff                      ;passed status is FALSE, turn off LED
    ;BRNE   WinLEDOn                ;else the passed status is True, turn on LED

WinLEDOn:
    ORI     R17, WIN_LED_MASK                 ;turn on the Win bit
    RJMP    EndDisplayWin

WinLEDOff:
    ANDI    R17, ~WIN_LED_MASK                ;turn off the Win bit
    ;RJMP   EndDisplayWin                     ;done turning on the Win bit

EndDisplayWin:                                ;done so return
    STS     currentDigits + WIN_DIGIT, R17    ;store the new Win bit
    RET





; DisplaySwitchLEDs(m)
;
; Description:       This function turns on or off the switch LEDs based on the 
;                    passed 16-bit mask(m). If a bit in the mask is set(one), 
;                    the corresponding switch is turned on; if it is reset(zero) 
;                    the LED is turned off. 
;
; Operation:         The segment pattern of SWITCH_DIGIT_ONE, SWITCH_DIGIT_ZERO 
;                    are changed based on the passed value in R17|R16. Win, Lose
;                    LEDs remain the same, and SWITCHLED_MASK is used to mask 
;                    over the changed bits. 
;
; Arguments:         R17|R16 - an 16-bit switch status pattern with 14th, 13th, 
;                    11th, 6th, 5th as unused bits. If a bit is 1, its 
;                    corresponding switch LED will be turned on:
;                          -------------------------------------------------
;                    Bits: |15|14|13|12|11|10| 9| 8| 7| 6| 5| 4| 3| 2| 1| 0|
;                          -------------------------------------------------
;                  Switch: |11|NA|NA|12|NA|10| 9| 8| 3|NA|NA| 2| 4| 7| 6| 5|
;                          -------------------------------------------------
;                    
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentDigits - SWITCH_DIGIT_ONE, SWITCH_DIGIT_ZERO 
;                                    elements are changed.
; Global Variables:  None.
;
; Input:             None.
; Output:            Turns on or off the switch LEDs (indirectly via LEDMux)
;                    as indicated by passed argument.
;
; Error Handling:    Unused bits in the pattern(NA switches) are ignored. 
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, R17, R18
; Stack Depth:       0 bytes
;
; Author:            Di Hu
; Last Modified:     Jun 9, 2019

DisplaySwitchLEDs:

    LDS      R18, currentDigits + SWITCH_DIGIT_ZERO   ;get current LED pattern
    ANDI     R18, ~LOW(SWITCHLED_MASK)                ;store unchanged LEDs
    ANDI     R16, LOW(SWITCHLED_MASK)                 ;get passed-in pattern
    OR       R16, R18                                 ;update switch LEDs with
                                                      ;  Win LED unchanged
    STS      currentDigits + SWITCH_DIGIT_ZERO, R16   ;store the new patterns
                                                      
    LDS      R18, currentDigits + SWITCH_DIGIT_ONE    ;get current LED pattern
    ANDI     R18, ~HIGH(SWITCHLED_MASK)               ;store unchanged LEDs
    ANDI     R17, HIGH(SWITCHLED_MASK)                ;get passed-in pattern
    OR       R17, R18                                 ;update switch LEDs with
                                                      ;  Lose LED unchanged  
    STS      currentDigits + SWITCH_DIGIT_ONE, R17

    RET                                               ;done so return   





; LEDMux
;
; Description:       This procedure multiplexes the LED display under
;                    interrupt control.  It should be called at a regular
;                    interval of about 1 ms.
;
; Operation:         This procedure outputs the next digit (from the
;                    currentDigits buffer) to the memory mapped LEDs each time
;                    it is called.  To do this it outputs the segment pattern 
;                    that the current digit should have.  The segment to
;                    output is determined by curMuxDigit and curMuxDigitPatt 
;                    which are also updated by this function.  One digit is 
;                    output each time the function is called.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R18 - current digit number.
;                    R19 - current digit pattern.
;                    Z   - pointer to digit patterns to output.
; Shared Variables:  currentDigits - an element of the buffer is written to
;                                    the LEDs and the buffer is not changed.
;                    curMuxDigit   - used to determine which buffer element to
;                                    output and updated to the next buffer
;                                    element.
;                    curMuxDigitPatt - digit drive pattern to output and
;                                    and updated to the next drive pattern.
; Global Variables:  None.
;
; Input:             None.
; Output:            The next digit is output to the LED display.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R0, R18, R19, Z (ZH | ZL)
; Stack Depth:       0 bytes
;
; Author:            Di Hu
; Last Modified:     Jun 5, 2019

LEDMux:


StartLEDMux:                          ;first turn off the LEDs
    LDI	   R18, DIGITS_OFF		      ;turn off the LED digit drives
    OUT	   DIGIT_PORT, R18

    CLR	   R19			              ;zero constant for calculations
    LDS	   R18, curMuxDigit           ;get current digit to output

GetMUXDigit:     			          ;get the digit pattern
    LDI	   ZL, LOW(currentDigits)     ;get the start of the buffer
    LDI	   ZH, HIGH(currentDigits)
    ADD	   ZL, R18                    ;move to the current muxed digit
    ADC	   ZH, R19

OutPutPattern:
    LD	   R0, Z                      ;get the digit pattern from buffer
    OUT	   SEGMENT_PORT, R0           ;and output it to the display
 
    LDS	   R19, curMuxDigitPatt	      ;get the current drive pattern
    OUT	   DIGIT_PORT, R19            ;and output it

GetNextMUXDIgit:
    LSL	   R19			              ;get the next digit pattern
    INC    R18                        ;and next digit number
    CPI	   R18, NUM_LED_DIGITS	      ;check if have done all the Digits
    BRLO   UpdateDigitCnt             ;if not, update with the new values
	;BRSH	ResetDigitCnt		      ;otherwise need to reset digits

ResetDigitCnt:			              ;reset segment count and pattern
    CLR    R18                        ;on last segment, reset to first
    LDI	   R19, INIT_DIG_PATT         ;and the first pattern too
    ;RJMP  UpdateDigitCnt

UpdateDigitCnt:			             ;store new segment count and pattern values
	STS	   curMuxDigit, R18		      ;store the new digit count
	STS	   curMuxDigitPatt, R19	      ;store the new digit pattern
	;RJMP  EndLEDMux                  ;and all done


EndLEDMux:                            ;done multiplexing LEDs - return
    RET




; InitLEDMux
;
; Description:       This procedure initializes the variables used by the code
;                    that multiplexes the LED display, and turns off all LEDs.
;
; Operation:         The digit number to be multiplexed next is reset. Start 
;                    displaying LEDs from the first row. Calls the function 
;                    ClearDisplay.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  curMuxDigit     - set to 0.
;                    curMuxDigitPatt - set to INIT_DIG_PATT.
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
; Registers Changed: R16
; Stack Depth:       2 bytes
;
; Author:            Di Hu
; Last Modified:     May 17, 2019

InitLEDMux:


    LDI     R16, 0                   ;initialize the digit to multiplex
    STS     curMuxDigit, R16

    LDI     R16, INIT_DIG_PATT       ;initialize digit drive pattern too
    STS     curMuxDigitPatt, R16

    RCALL   ClearDisplay             ;turn off all LEDs

    ;RJMP   EndInitLEDMux            ;only thing to do - done


EndInitLEDMux:                       ;done initializing multiplex operation
    RET                              ;just return




;the data segment

.dseg


currentDigits:      .BYTE	NUM_LED_DIGITS	
                              ;buffer holding currently displayed digit patterns
;currentDigits Buffer Content:
; -----------------------------------------------------------------------
;| Digit |                               Bit                             | 
;|(Buffer|----------------------------------------------------------------
;| Byte) |   7   |   6   |   5   |   4   |   3   |   2   |   1   |   0   |
; -----------------------------------------------------------------------
;|   6   |Digit 1|Digit 1|Digit 1|Digit 1|Digit 1|Digit 1|Digit 1|Digit 1|
;|       | Seg e | Seg a | Seg e | Seg c | Seg g | Seg f | Seg d | Seg b | 
; -----------------------------------------------------------------------
;|   5   |Digit 2|Digit 2|Digit 2|Digit 2|Digit 2|Digit 2|Digit 2|Digit 2|
;|       | Seg e | Seg a | Seg e | Seg c | Seg g | Seg f | Seg d | Seg b | 
; -----------------------------------------------------------------------
;|   4   |Digit 3|Digit 3|Digit 3|Digit 3|Digit 3|Digit 3|Digit 3|Digit 3|
;|       | Seg e | Seg a | Seg e | Seg c | Seg g | Seg f | Seg d | Seg b | 
; -----------------------------------------------------------------------
;|   3   |Digit 4|Digit 4|Digit 4|Digit 4|Digit 4|Digit 4|Digit 4|Digit 4|
;|       | Seg e | Seg a | Seg e | Seg c | Seg g | Seg f | Seg d | Seg b | 
; -----------------------------------------------------------------------
;|   2   |Digit 4| Left  |**N/A**| Left  | Colon | Right |Digit 3| Left  |
;|       |   DP  |Top In+|*******|Bot.In+|       |Top In+|  DP   |Mid.In+| 
; -----------------------------------------------------------------------
;|   1   | SW11  | Lose  |**N/A**| SW12  |**N/A**| SW10  | SW9   | SW8   |
;|       | LED   | LED   |*******| LED   |*******| LED   | LED   | LED   | 
; -----------------------------------------------------------------------
;|   0   | SW3   | Win   |**N/A**| SW2   | SW4   | SW7   | SW6   | SW5   |
;|       | LED   | LED   |*******| LED   | LED   | LED   | LED   | LED   | 
; -----------------------------------------------------------------------
; In+: Indicator  
; currentDigits address starts at Byte(Digit) 0. 


curMuxDigit:        .BYTE	1            ;current digit number being multiplexed
curMuxDigitPatt:    .BYTE	1		     ;current digit output pattern
