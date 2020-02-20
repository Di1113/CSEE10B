;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                             TG_SWITCH_FUNC.inc                             ;
;                              Switch Routines                               ;
;                                Teaser Game                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the functions for debouncing the switches and getting the
; switch status.  The public functions included are:
;    DebounceSwitch - debounce the switch(es) pressed 
;    DebounceInit   - initialize switch debouncing
;    GetKey         - get the key code of the pressed switch
;    IsAKey         - check if have debounced switch available 
;
; Revision History:
;    5/21/19   Di Hu               initial revision
;    5/22/19   Di Hu               added GetKey function 
;    5/23/19   Di Hu               added NOP for DebounceSwitch function;
;                                  added DebounceInit, IsAKey functions
;    5/26/19   Di Hu               simplified isAKey function;
;                                  debugged the repeat debouncing issue in
;                                  DebounceSwitch by switching function 
;                                  orders 
;    6/5/19    Di Hu               - changed filename from TGSWITCH to 
;                                  TG_SWITCH_FUNC
;                                  - changed constant names from SWITCH_DD to
;                                    SWITCH_SCANNED_ROW, from SWITCH_PIN to 
;                                    SWITCH_STATES
;                                  - added pressedKey buffer and modified 
;                                    DebounceSwitch function to check if the 
;                                    switches being debounced are the same 
;                                    switches through out debouncing or new
;                                    key pattern is input in the middle of 
;                                    debouncing 



; local include files
;.include "TG_SWITCH_DEF.inc"



.cseg





; DebounceSwitch
;
; Description:       This procedure scans the switch array, and check if a key 
;                    is pressed. If there is, it debounces the key; if not, it 
;                    continues scanning the next row of switches. It is 
;                    expected to be called approximately once per 1 ms by 
;                    the time event handler. 
;
; Operation:         This function scans the 3 by 4 switch array row by row 
;                    through IO Port Port B and checks if any switch(es) in the 
;                    currently scanned row is pressed. The debounce counter is 
;                    reset if no switch is pressed or if a second switch is 
;                    pressed before the first one is released, and decremented
;                    if any new key is pressed or the same keyCode is detected. 
;                    When the counter reaches zero, the flag haveKey is set and  
;                    the key code of the pressed key is stored to keyCode. 
;                    When the counter goes below zero, it is set to zero.
;
; Arguments:         None.
;
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentRow - read and written - scanned for pressed keys
;                    debounceCounter - read and written 
;                                    - reset when no key pressed, 
;                                      decremented otherwise 
;                    haveKey - written - set when counter is 0 
;                    keyCode - written - set when counter is 0 
;                            - current row bit and column bit of the pressed 
;                              key(s) are set, other bits are cleared 
;                            - format: (r: row; c: column)
;                                  ----------------------------------- 
;                                 |Bit| 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
;                                  ----------------------------------- 
;                                 |r/c|c1 |c2 |c3 |c4 |r3 |r2 |r1 |N/A|
;                                  ----------------------------------- 
;                                 For example, Random Reset switch would
;                                 have key code of 0b10000100 because it's
;                                 in the first column and second row on the  
;                                 switch array.
;
; Input:             The state of the switches.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, R17, R18
; Stack Depth:       0 bytes
;
; Author:            Di Hu
; Last Modified:     Jun 5, 2019 

DebounceSwitch:

StartDebounceSwitch:                ;scan current switch row for pressed keys
    LDS     R16, currentRow         ;set DDR to have only the current row bit 
    OUT     SWITCH_SCANNED_ROW, R16 ;   as output 
    COM     R16                     ;set all the other bits as input with pull
    OUT     SWITCH_PORT, R16        ;   up resistor to prevent shortage 

    NOP                             ;wait for IN to update
    IN      R16,  SWITCH_STATES     ;check if any switch is pressed
    COM     R16
    ANDI    R16, PRESSED_MASK       ;mask over the switches in the scanned row 

    BREQ    SwitchUp                ;no switch is pressed
    ;BRNE    CheckSwitchPattern     ;else some switch is down - check if is(are) 
                                    ;   the same key(s) pressed last time

CheckSwitchPattern: 
    LDS     R18, pressedKey         ;get last pressed switch's keyCode
    LDS     R17, currentRow         ;generate new keyCode: 
    OR      R17, R16                ;   R16: column no.; R17: row no.
    STS     pressedKey, R17         ;store the pressed switch's keyCode 
    CP      R17, R18                ;compare new pressed switches with old ones
    BRNE    NewKeysNewCounter       ;different switches are pressed, reset cnt
    ;BREQ    SameKeys                ;if equal, continue debounce the switch(es)

SameKeys:                           ;debounce the same switches 
    LDS     R18, debounceCounter    ;decrement debounce counter
    DEC     R18                     
    BRNE    ContinueDebouncing      ;otherwise, needs to continue debouncing
    ;BREQ    IsDebounced            ;if counter reaches zero, set flags
    
IsDebounced:                        ;set haveKey flag and store key code
    STS     keyCode, R17            ;store the debounced switch's keyCode 
    LDI     R17, TRUE
    STS     haveKey, R17            ;set flag to be true
    RJMP    EndDebounceSwitch       ;debouncing finished

ContinueDebouncing:                 ;check if should clear counter before exit
    TST     R18                     ;check if counter is below 0 or above 
    BRGE    EndDebounceSwitch       ;counter is positive, debounced once, exit
    ;BRLT    ClearCounter           ;counter is negative, clear the counter 

ClearCounter:                       ;switch is pressed after debouncing
    LDI     R18, 0                  ;clear the debounce counter 
    RJMP    EndDebounceSwitch       ;exit

NewKeysNewCounter:                  ;start to debounce new switches pressed 
    LDI     R18, DEBOUNCE_COUNTER - 1 ;debounce for only once because 
                                    ;       it's just pressed
    RJMP    EndDebounceSwitch       ;exit

SwitchUp:                           ;reset counter, scan next row
    LDI     R18, DEBOUNCE_COUNTER   ;reset counter to initial counts
    LDS     R17, currentRow
    CPI     R17, THIRDROW           ;check if has reached the last row
    BRNE    ScanNextRow             ;if not, shift to next row
    ;BREQ   ResetRowCnt             ;if yes, start from the first row again

ResetRowCnt:                        ;reset row counter to the first row
    LDI     R17, FIRSTROW           ;next time scan the first row
    RJMP    NotDebounced            ;didn't debounce, exit

ScanNextRow:                        ;scan the second or third row of switches
    LSL     R17                     ;shift current row to next row
    RJMP    NotDebounced            ;didn't debounce, exit

NotDebounced:                       ;no switch pressed
    STS     currentRow, R17         ;scan next row in next debounce call 
    CLR     R16
    STS     pressedKey, R16         ;clear the key code of pressed key
    ;RJMP   EndDebounceSwitch       ;didn't debounce, exit

EndDebounceSwitch:                  ;debouncing finished
    STS     debounceCounter, R18    ;update debounce counter 
    RET                             ;return





; DebounceInit
;
; Description:       This procedure initializes shared variables for 
;                    DebounceSwitch function.
;
; Operation:         Set or reset currentRow, debounceCounter, haveKey and 
;                    keyCode to initial values. 
;
; Arguments:         None.
;
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentRow - written - set to first row of switch array
;                    debounceCounter - written - set to full counts
;                    haveKey - written - reset
;                    keyCode - written - reset
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
; Stack Depth:       0 bytes
;
; Author:            Di Hu
; Last Modified:     May 23, 2019 

DebounceInit:                       ;initialize buffers for DebounceSwitch 

    LDI     R16, DEBOUNCE_COUNTER   ;reset debounceCounter to full counts
    STS     debounceCounter, R16

    LDI     R16, FIRSTROW         ;set currentRow to first row of switch-array
    STS     currentRow, R16

    CLR     R16                     ;clear haveKey and keyCode
    STS     haveKey, R16
    STS     keyCode, R16

EndDebounceInit:                    ;done, so return 
    RET








; IsAKey
;
; Description:       This procedure checks if there is a debounced switch 
;                    available, if there is, clear the zero flag; otherwise, 
;                    set the zero flag. This function does not affect 
;                    whether or not a switch is available.
;
; Operation:         If haveKey is TRUE, clear the zero flag; 
;                    if haveKey is FALSE, set the zero flag.
;
; Arguments:         None.
;
; Return Value:      Zero Flag - set if no debounced switch is available, 
;                                clear if some debounced switch is available.
;
; Local Variables:   None.
; Shared Variables:  haveKey - read - checks if there is debounced switch.
;
; Input:             None.
; Output:            None.
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
; Last Modified:     May 25, 2019 

IsAKey: 

CheckIsDebounced:                   ;check haveKey flag 
    LDS     R16, haveKey

    CPI     R16, FALSE              ;reset zf if there is a debounced key
                                    ;set otherwise

EndCheckIsDebounced:                ;done, so return
    RET








; GetKey()
;
; Description:       This procedure first checks if there is a debounced key ,
;                    available. Then if there is, store the key code of the 
;                    debounced key in R16, clear the keyCode buffer; otherwise, 
;                    wait till there is a debounced key available. 
;
; Operation:         Call IsAKey to check the zero flag, if it is set, loop;
;                    if it is clear, return with the key code of the debounced 
;                    key in R16.
;
; Arguments:         None.
;
; Return Value:      R16 - debounced switch's keyCode 
;
; Local Variables:   None.
; Shared Variables:  keyCode - read - value stored in R16
;                    haveKey - written - to FALSE once finished reading 
;                                            the key code
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R0, R16, R17
; Stack Depth:       2 bytes
;
; Author:            Di Hu
; Last Modified:     May 23, 2019 

GetKey: 

CheckDebouncedSwitch:               ;check if has debounced switch available
    RCALL   IsAKey                  ;check zero flag
    BREQ    CheckDebouncedSwitch    ;if zf is set, no debounced key, loop
    ;BRNE    GetKeyCode             ;if zf is clear, get the key code

GetKeyCode:                         ;get key code from R16
    CLR     R17                     ;reset the haveKey flag and keyCode
    IN      R0, SREG                ;below is critical code, save flags
    CLI                             ;clear global interrupt flag

    LDS     R16, keyCode            ;store key code to buffer keyCode
    STS     haveKey, R17 

    OUT     SREG, R0                ;restore the flags 

GotKey:                             ;done updating key code and the flag
    RET                             ;return






; Shared Variables:  currentRow - for scanning pressed key(s) in a specific  
;                                 row in the switch array
;                    debounceCounter 
;                               - for debouncing the pressed key(s)
;                    haveKey    - indicates whether some debounced key(s) is 
;                                  available to use
;                    keyCode    - key code for debounced key(s)
;                               - current row bit and column bit of the  
;                                 pressed key(s) are set, other bits are 
;                                 cleared 
;                    pressedKey - key code for the last pressed key(s)


;the data segment

.dseg


currentRow:         .BYTE   1    ;current switch row being scanned
debounceCounter:    .BYTE   1    ;counter for debouncing the pressed switch
haveKey:            .BYTE   1    ;indicates if a debounced switch is available
keyCode:            .BYTE   1    ;key code of the debounced switch 
pressedKey:         .BYTE   1    ;key code of the last pressed switch 
