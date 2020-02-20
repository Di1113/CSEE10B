;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              TG_GAME_FUNC                                  ;
;                           Game Logic Routines                              ;
;                               Teaser Game                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the functions for running Teaser Game's main loop. 
; These functions each perform some action and return a game state flag to 
; main loop to go to next action.
; The public functions included are:
;    GameStart         - initialize Ver 1.x SD card
;    WaitToGetKeyState - read n bytes of data from the SD card
;    FindKeyState  - write n bytes of data to the SD card
;    MakeMove
;    FindNewKeyState
;    CheckGameOver
;    IllegalMoveWarning
;    RandomReset
;    ManualReset
;    GameOverWon
;    GameOverLost
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
;                            Seperated RandomNumberGenerator, Delay16 to TG_UTIL_FUNC.asm
;                            Modified stateFlag to a shared varaible, set R18 as stateFlag's return register 

; local include files
;.include  "TG_SDCARD_DEF.inc"



.cseg



; GameStart 
;
; Description:       This function initialize the game board.
;
; Operation:         This function clears moveCounter and assign an random inital
;                    value to randomBuffer. 
;
; Arguments:         None. 
; Return Value:      stateFlag - For main loop to compare with Compare Value
;                                and decide which entry to go to in the main 
;                                loop table. Possible flags to return: 
;                                   SuccessFlag
;
; Local Variables:   None.
; Shared Variables:  moveCounter - written - cleared. 
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
; Limitation:        None.
;
; Known Bugs:        None. 
;
; Registers Changed: flags, R16
; Stack Depth:       0 bytes.
;
; Author:            Di Hu
; Last Modified:     June 9, 2019

GameStart: 

    CLR     R16 
    LDI     YL, LOW(moveCounter)
    LDI     YH, HIGH(moveCounter) 
    ST      Y+, R16
    ST      Y, R16 
	STS     randomCounter, R16
    STS     stateFlag, R16              ; same as (LDI R16, SUCCESS_FLAG)

    RET 




; WaitToGetKeyState 
;
; Description:       This function waits till a switch is pressed and checks if 
;                    the switch pressed is a valid move or a reset switch and 
;                    returns flag accordingly in the stateFlag buffer.
;
; Operation:         This function calls GetKey function which waits in a loop
;                    till a switch is pressed, then compare the keyCode returned
;                    to the keyCode of "Manual Reset" and "Random Reset" 
;                    switches first and if matches, return with ManualResetFlag 
;                    or RandomRestFlag in the stateFlag buffer. If not a reset
;                    switch that is pressed, compare the returned keyCode to  
;                    the valid key values in the KeyCodeToKeyState table. If 
;                    found valid key value that matches the keyCode, store the
;                    following two bytes in keyState mask and check for legal
;                    move. If is a legal move, return LegalMoveFlag, pass the
;                    keyState mask to MakeMove function. If it is an illegal
;                    move or no key values in the table matches the returned
;                    keyCode, return with IllegalMoveFlag in stateFlag. 
;
; Arguments:         R16 - keyCode - returned from GetKey function in Display 
;                          functions file, used to check if the keyCode is valid.
;                                 
; Return Value:      stateFlag - For main loop to compare with Compare Value
;                                and decide which entry to go to in the main 
;                                loop table. Possible flags to return: 
;                                   IllegalMoveFlag
;                                   LegalMoveFlag
;                                   ManualResetFlag
;                                   RandomRestFlag
;                    R17|R16   - keyState mask - Passed to MakeMove function 
;                                to make a move or passed to Manual Reset when
;                                called to turn on the mask bit LED. Only 
;                                passed to MakeMove if the move is legal.
;
; Local Variables:   None.
; Shared Variables:  stateFlag - written - accessed by main loop  
; Global Variables:  keyCode   - read - to compare with the valid keyCode and 
;                                get keyState Mask if the keyCode is valid. 
;                    
; Input:             None.
; Output:            None.
;
; Error Handling:    keyCode that is invalid or represents an illegal move
;                    would cause the function to return with IllegalMoveFlag
;                    and has no effect on keyStates. 
;
; Algorithms:        None.
; Data Structures:   None.
;
; Limitation:        None.
;
; Known Bugs:        None. 
;
; Registers Changed: flags, R16, R17, R18, R19
; Stack Depth:       ---
;
; Author:            Di Hu
; Last Modified:     Jun 9, 2019

WaitToGetKeyState: 

    RCALL GetKey            ;keyCode is returned in R16 

CheckManualReset: 
    LDI     R17, MANUAL_RESET_SW
    CP      R16, R17 
    BREQ    ReturnManualResetFlag
    ;BRNE    CheckRandomReset

CheckRandomReset:
    LDI     R17, RANDOM_RESET_SW
    CP      R16, R17 
    BREQ    ReturnRandomResetFlag
    ;BRNE    LookUpCodeToStateTable 

CodeToStateTableLookUp:
    RCALL   FindKeyState
    BREQ    CheckLegalMove
    ;BRNE    ReturnIllegalMoveFlag

ReturnIllegalMoveFlag:
    LDI     R18, ILLEGAL_MOVE_FLAG
    RJMP    EndWaitToGetKeyState

ReturnManualResetFlag:
    LDI     R16, LOW(MANUAL_RESET_ON)
    LDI     R17, HIGH(MANUAL_RESET_ON)
    LDI     YL, LOW(keyState)
    LDI     YH, HIGH(keyState) 
    ST      Y+, R17 
    ST      Y, R16
    RCALL   DisplaySwitchLEDs           ;turn on manual reset switch 

    LDI     R18, MANUAL_RESET_FLAG
    RJMP    EndWaitToGetKeyState

ReturnRandomResetFlag:
    LDI     R18, RANDOM_RESET_FLAG
    RJMP    EndWaitToGetKeyState

CheckLegalMove:
    LDI     YL, LOW(keyState)
    LDI     YH, HIGH(keyState) 
    LD      R19, Y+
    LD      R18, Y
    AND     R19, R17
    AND     R18, R16
	OR 		R18, R19
    BREQ    ReturnIllegalMoveFlag
    ;BRNE    ReturnLegalMoveFlag

ReturnLegalMoveFlag:
    LDI     R18, LEGAL_MOVE_FLAG
    ;RJMP    EndWaitToGetKeyState
    
EndWaitToGetKeyState:
    STS     stateFlag, R18
    RET 



; FindKeyState 
;
; Description:       This function looks for a keyState code match for the 
;                    pressed keySwitch in the UpdateStateTable. 
;
; Operation:         --- 
;
; Arguments:         R16 - keyCode - returned from GetKey function in Display 
;                          functions file, used to check if the keyCode is valid.
;                                 
; Return Value:      Zero flag - set if found a match in the table; cleared otherwise. 
;                    R17|R16   - keyState mask - Passed to MakeMove function 
;                                to make a move or passed to Manual Reset when
;                                called to turn on the mask bit LED. Only 
;                                passed to MakeMove if the move is legal.
;
; Local Variables:   None.
; Shared Variables:  stateFlag - written - accessed by main loop  
; Global Variables:  keyCode   - read - to compare with the valid keyCode and 
;                                get keyState Mask if the keyCode is valid. 
;                    
; Input:             None.
; Output:            None.
;
; Error Handling:    keyCode that is invalid or represents an illegal move
;                    would cause the function to return with IllegalMoveFlag
;                    and has no effect on keyStates. 
;
; Algorithms:        None.
; Data Structures:   None.
;
; Limitation:        None.
;
; Known Bugs:        None. 
;
; Registers Changed: flags, R16, R17, R18, R19
; Stack Depth:       ---
;
; Author:            Di Hu
; Last Modified:     Jun 10, 2019

FindKeyState:

StartFindKeyState: 
    LDI     ZL, LOW(2 * KeyCodeToKeyState)    ;start at the beginning of the table
    LDI     ZH, HIGH(2 * KeyCodeToKeyState)

LookUpKeyCodeMatch:
    LPM     R17, Z+
    CP      R16, R17 
    BREQ    FoundKeyState
    ;BRNE    CheckNextKeyCode

CheckNextKeyCode:
    ADIW    Z, CTS_TAB_OFFSET
    LDI     R20, HIGH(2 * EndKeyCodeToKeyState) ;setup for end check
    CPI     ZL, LOW(2 * EndKeyCodeToKeyState) ;check if at end of table
    CPC     ZH, R20
    BRNE    LookUpKeyCodeMatch
    ;BREQ    KeyCodeNotFound

KeyCodeNotFound: 
    CLZ
    RJMP    EndFindKeyState

FoundKeyState: 
    LPM     R17, Z+ 
    LPM     R16, Z+ 
    SEZ 
    RJMP    EndFindKeyState

EndFindKeyState:
    RET


;KeyCodeToKeyState table
; 

KeyCodeToKeyState:
;       keyCode keyState Mask               padding     switch #
;       0x82    Manual Reset                             SW11
;       0x84    Random Reset                             SW12 
.DB     0x42,   HIGH(0x0010), LOW(0x0010),  0           ;SW2    
.DB     0x22,   HIGH(0x0080), LOW(0x0080),  0           ;SW3 
.DB     0x12,   HIGH(0x0008), LOW(0x0008),  0           ;SW4    
.DB     0x44,   HIGH(0x0001), LOW(0x0001),  0           ;SW5   
.DB     0x24,   HIGH(0x0002), LOW(0x0002),  0           ;SW6   
.DB     0x14,   HIGH(0x0004), LOW(0x0004),  0           ;SW7   
.DB     0x48,   HIGH(0x0100), LOW(0x0100),  0           ;SW8   
.DB     0x28,   HIGH(0x0200), LOW(0x0200),  0           ;SW9   
.DB     0x18,   HIGH(0x0400), LOW(0x0400),  0           ;SW10  

EndKeyCodeToKeyState: 






; MakeMove 
;
; Description:       Update the keyState buffer by table look up.  
;
; Operation:         Compare the passed in keyState mask which represent the 
;                    switch pressed to the first column in the UpdateStateTable,
;                    when found a match, update the keyState buffer by XOR  
;                    current keyState value with the next word in the matched
;                    row.  
;
; Arguments:         R17|R16 - keyState mask - to search for a match row in 
;                    the UpdateStateTable.
; Return Value:      stateFlag - For main loop to compare with Compare Value
;                                and decide which entry to go to in the main 
;                                loop table. Possible flags to return: 
;                                   SuccessFlag
;                                   FailFlag
;                    R17|R16   - current keyState - Passed to CheckGameOver function 
;
; Local Variables:   None.
; Shared Variables:  stateFlag - written - SuccessFlag if found a match in the
;                                table; FailFlag if didn't. 
;                    MoveCounter - written - incremented by one. 
;                    
; Global Variables:  None.
;
; Input:             None.
; Output:            keyState is updated and displayed on the board 
;                    (indirectly via LED Mux).
;
; Error Handling:    If didn't find a match in the table, return FailFlag.   
;
; Algorithms:        None.
; Data Structures:   None.
;
; Limitation:        None.
;
; Known Bugs:        None. 
;
; Registers Changed: flags, R16, R17, R18, R19
; Stack Depth:       2 bytes. 
;
; Author:            Di Hu
; Last Modified:     June 8, 2019

MakeMove:

    RCALL   FindNewKeyState
    BREQ    FoundMove
    ;BRNE    MoveNotFound  

MoveNotFound: 
    LDI     R18, FAIL_FLAG          ;should never happen, but if does, 
    RJMP    EndMakeMove             ;return error flag 

FoundMove:
    LDI     YL, LOW(keyState)
    LDI     YH, HIGH(keyState) 
    LD      R19, Y+
    LD      R18, Y
    EOR     R17, R19 
    EOR     R16, R18

    SBIW    Y, 1
    ST      Y+, R17 
    ST      Y, R16
    
    PUSH    R16
    PUSH    R17
    
    RCALL   DisplaySwitchLEDs 

    LDI     YL, LOW(moveCounter)
    LDI     YH, HIGH(moveCounter) 
    LD      R17, Y+
    LD      R16, Y

	LDI 	R18, 1
    ADD		R16, R18
	CLR 	R18
	ADC 	R17, R18
    SBIW    Y, 1
    ST      Y+, R17 
    ST      Y, R16

    RCALL   DisplayHex

    POP     R17
    POP     R16 

    LDI     R18, SUCCESS_FLAG
    ;RJMP    EndMakeMove 

EndMakeMove:
    STS     stateFlag, R18
    RET 




; FindNewKeyState 
;
; Description:       This function looks for a keyState code match for the 
;                    pressed keySwitch in the UpdateStateTable. 
;
; Operation:         --- 
;
; Arguments:         R16 - keyCode - returned from GetKey function in Display 
;                          functions file, used to check if the keyCode is valid.
;                                 
; Return Value:      Zero flag - set if found a match in the table; cleared otherwise. 
;                    R17|R16   - keyState mask - Passed to MakeMove function 
;                                to make a move or passed to Manual Reset when
;                                called to turn on the mask bit LED. Only 
;                                passed to MakeMove if the move is legal.
;
; Local Variables:   None.
; Shared Variables:  stateFlag - written - accessed by main loop  
; Global Variables:  keyCode   - read - to compare with the valid keyCode and 
;                                get keyState Mask if the keyCode is valid. 
;                    
; Input:             None.
; Output:            None.
;
; Error Handling:    keyCode that is invalid or represents an illegal move
;                    would cause the function to return with IllegalMoveFlag
;                    and has no effect on keyStates. 
;
; Algorithms:        None.
; Data Structures:   None.
;
; Limitation:        None.
;
; Known Bugs:        None. 
;
; Registers Changed: flags, R16, R17, R18, R19
; Stack Depth:       ---
;
; Author:            Di Hu
; Last Modified:     Jun 10, 2019
FindNewKeyState:

StartFindNewKeyState:

    LDI     ZL, LOW(2 * UpdateStateTable)    ;start at the beginning of the table
    LDI     ZH, HIGH(2 * UpdateStateTable)

LookUpKeyStateMatch:
    LPM     R18, Z+    ;load first two bytes of keyState 
    LPM     R19, Z+ 
    CP      R16, R18   ;compare to the keyState of the pressed switch 
    CPC     R17, R19 
    BREQ    FoundNewKeyState
    ;BRNE    CheckNextKeyState

CheckNextKeyState:
    ADIW    Z, HALF_UST_TAB_RSIZE
    LDI     R20, HIGH(2 * EndUpdateStateTable) ;setup for end check
    CPI     ZL, LOW(2 * EndUpdateStateTable) ;check if at end of table
    CPC     ZH, R20
    BRNE    LookUpKeyStateMatch
    ;BREQ    KeyStateNotFound  

KeyStateNotFound: 
    CLZ
    RJMP    EndFindNewKeyState             ;return error flag 

FoundNewKeyState:
    LPM     R16, Z+
    LPM     R17, Z 
    SEZ 
    ;RJMP    EndFindNewKeyState 

EndFindNewKeyState:
    RET



; UpdateStateTable 
;
;   Switch  State      Pressed
;   Pressed Mask        Sw # 
UpdateStateTable:

.DW 0x0010, 0x0093      ;SW2    
.DW 0x0080, 0x0098      ;SW3    
.DW 0x0008, 0x008E      ;SW4    
.DW 0x0001, 0x0111      ;SW5   
.DW 0x0002, 0x0287      ;SW6   
.DW 0x0004, 0x040C      ;SW7   
.DW 0x0100, 0x0303      ;SW8   
.DW 0x0200, 0x0700      ;SW9   
.DW 0x0400, 0x0606      ;SW10 

EndUpdateStateTable:






; CheckGameOver 
;
; Description:       Called after MakeMove function. Check if game is over.      
;
; Operation:         Check if game is over by comparing current game state in 
;                    keyState to constants LostState and WonState and return 
;                    flag accordingly.  
;
; Arguments:         R17|R16 - current keyState's value 
; Return Value:      stateFlag - clear the buffer(i.e. return value 0).
;
; Local Variables:   None.
; Shared Variables:  stateFlag - For main loop to compare with Compare Value
;                                and decide which entry to go to in the main 
;                                loop table. Possible flags to return: 
;                                   GameLostFlag
;                                   GameWonFlag
;                                   InGameFlag
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
; Limitation:        None.
;
; Known Bugs:        None. 
;
; Registers Changed: flags, R18, R19
; Stack Depth:       0 byte. 
;
; Author:            Di Hu
; Last Modified:     June 8, 2019

CheckGameOver: 

CheckGameLost:
    LDI     R18, LOW(LOST_STATE)
    LDI     R19, HIGH(LOST_STATE)
    CP      R16, R18
    CPC     R17, R19
    BREQ    ReturnGameLostFlag
    ;BRNE    CheckGameWon

CheckGameWon:
    LDI     R18, LOW(WON_STATE)
    LDI     R19, HIGH(WON_STATE)
    CP      R16, R18
    CPC     R17, R19
    BRNE    ReturnInGameFlag
    ;BREQ    ReturnGameWonFlag

ReturnGameWonFlag: 
    LDI     R16, GAME_WON_FLAG
    RJMP    EndCheckGameOver

ReturnGameLostFlag:
    LDI     R16, GAME_LOST_FLAG
    RJMP    EndCheckGameOver

ReturnInGameFlag: 
    LDI     R16, IN_GAME_FLAG
    ;RJMP    EndCheckGameOver
    
EndCheckGameOver: 
    STS     stateFlag, R16 
    RET 




; IllegalMoveWarning 
;
; Description:       This function plays an tune to warn users that an illegal
;                    move was made. 
;
; Operation:         Load IllegalMoveSound to R17|R16, then call PlayNote. 
;
; Arguments:         None.
; Return Value:      stateFlag - For main loop to compare with Compare Value
;                                and decide which entry to go to in the main 
;                                loop table. Possible flags to return: 
;                                   SuccessFlag
;
; Local Variables:   None.
; Shared Variables:  None.
;
; Global Variables:  None.
;
; Input:             None.
; Output:            Output sound through speaker(indirectly via Timer 1).   
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
; Registers Changed: R16, R17
; Stack Depth:       2 bytes. 
;
; Author:            Di Hu
; Last Modified:     June 8, 2019

IllegalMoveWarning: 

    LDI     R17, HIGH(ILLEGAL_MOVE_SOUND)
    LDI     R16, LOW(ILLEGAL_MOVE_SOUND)
    RCALL   PlayNote

    LDI     R16, ONE_SECOND_NOTE
    RCALL   Delay16

    CLR     R16
    CLR     R17
    RCALL   PlayNote

    LDI     R16, SUCCESS_FLAG

    STS     stateFlag, R16 
    RET 







; RandomReset 
;
; Description:       This function randomly initialize switch states for users
;                    to start playing with, and updates the switch display.  
;
; Operation:         This function gets the randomBuffer value which is  
;                    constanly being updated on 1 ms time interval(in Timer 0  
;                    interrupt handler) and masks it over to get states for the
;                    9 switches in the 3x3 grid, and updates the value to 
;                    keyState.  
;
; Arguments:         None.
; Return Value:      stateFlag - For main loop to compare with Compare Value
;                                and decide which entry to go to in the main 
;                                loop table. Possible flags to return: 
;                                   SuccessFlag
;                    keyState  - Initalized randomly and passed to GameStart. 
;
; Local Variables:   None.
; Shared Variables:  stateFlag - written - SuccessFlag. 
;                    keyState - written - a pseudo random value. 
;                    randomBuffer - read - a pseudo random value generated by RandomNumberGenerator.
; Global Variables:  None.
;
; Input:             None.
; Output:            Switch LEDs are displayed by the updated keyState.  
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
; Registers Changed: flags, R16, R17
; Stack Depth:       2 byte.
;
; Author:            Di Hu
; Last Modified:     June 8, 2019

RandomReset: 

    RCALL   ClearDisplay

	LDI     YL, LOW(randomBuffer)
    LDI     YH, HIGH(randomBuffer) 
    LD      R17, Y+
	LD      R16, Y 
    ANDI    R16, LOW(SWITCH_MASK)
    ANDI    R17, HIGH(SWITCH_MASK)

    LDI     YL, LOW(keyState)
    LDI     YH, HIGH(keyState) 
    ST      Y+, R17
    ST      Y, R16 

 
    RCALL   DisplaySwitchLEDs

    LDI     R16, SUCCESS_FLAG
    CLR     R17
    RCALL   DisplayHex

    STS     stateFlag, R16 
    RET  









; ManualReset 
;
; Description:       This function is called when user presses the "Manual 
;                    Reset" switch and allows user to manually initialize switch 
;                    states by toggling the switches on the 3x3 grid. User can
;                    finish resetting by pressing "Manual Reset" switch again.   
;
; Operation:         This function doesn't return till user press the "Manual 
;                    Reset" switch again. When user is not done resetting, they
;                    can toggle any one of 9 switches state in the grid. 
;
; Arguments:         None.
; Return Value:      stateFlag - For main loop to compare with Compare Value
;                                and decide which entry to go to in the main 
;                                loop table. Possible flags to return: 
;                                   RandomRestFlag
;                                   SuccessFlag
;                    keyState  - Initalized randomly and passed to GameStart. 
;
; Local Variables:   R20 - loop counter to check for user input. 
; Shared Variables:  stateFlag - written - RandomRestFlag or SuccessFlag. 
;                    keyState - written - user defined value. 
; Global Variables:  None.
;
; Input:             None.
; Output:            Switch LEDs are displayed as keyState updates.  
;
; Error Handling:    If user press "Manual Reset" switch before toggling any
;                    switch on the grid, RandomRestFlag is returned and main
;                    loop of the game would initalize the game board randomly.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Limitation:        None.
;
; Known Bugs:        None. 
;
; Registers Changed: flags, R16, R17, R18, R19, R20 
; Stack Depth:       2 byte.
;
; Author:            Di Hu
; Last Modified:     June 8, 2019

ManualReset: 
    CLR     R16
    STS     resetMoveCounter, R16
    CLR     R17
    RCALL   DisplayHex

LoopManualReset:
    RCALL   GetKey

CheckManualResetFlag: 
    LDI     R17, MANUAL_RESET_SW
    CP      R16, R17 
    BREQ    CheckEmptyState
    ;BRNE    CheckRandomResetFlag

CheckRandomResetFlag:
    LDI     R17, RANDOM_RESET_SW
    CP      R16, R17 
    BREQ    SetRandomResetFlag
    ;BRNE    StartUpdateState

StartUpdateState:
    RCALL   FindKeyState
    BRNE    IllegalKeyCode 
    ;BREQ    FinishUpdateState

FinishUpdateState: 
    LDI     YL, LOW(keyState)
    LDI     YH, HIGH(keyState) 
    LD      R19, Y+
    LD      R18, Y
    EOR     R17, R19 
    EOR     R16, R18

    SBIW    Y, 1
    ST      Y+, R17 
    ST      Y, R16

    RCALL   DisplaySwitchLEDs 
    LDS     R20, resetMoveCounter
    INC     R20
    STS     resetMoveCounter, R20 
    RJMP    LoopManualReset

CheckEmptyState:
    LDI     YL, LOW(keyState)
    LDI     YH, HIGH(keyState) 
    LD      R19, Y+
    LD      R18, Y
    LDI     R20, LOW(MANUAL_RESET_ON)
    LDI     R21, HIGH(MANUAL_RESET_ON)
    CP      R18, R20
    CPC     R19, R21

    BREQ    SetResetNotDoneWarning   
    BRNE    CheckWinState


CheckWinState:
    LDI     YL, LOW(keyState)
    LDI     YH, HIGH(keyState) 
    LD      R19, Y+
    LD      R18, Y

    
    LDI     R16, LOW(WON_STATE)
    LDI     R17, HIGH(WON_STATE)
    OR      R16, R20
    OR      R17, R21

    CP      R18, R16
    CPC     R19, R17
    BRNE    ManualResetDone 
    ;BREQ    SetResetNotDoneWarning

SetResetNotDoneWarning:


IllegalKeyCode:
    LDI     R17, HIGH(RESET_WARN_SOUND)
    LDI     R16, LOW(RESET_WARN_SOUND)
    RCALL   PlayNote

    LDI     R16, ONE_SECOND_NOTE
    RCALL   Delay16

    CLR     R16
    CLR     R17
    RCALL   PlayNote
    RJMP    LoopManualReset

SetRandomResetFlag:
    LDI     R18, RANDOM_RESET_FLAG
    RJMP    EndManualReset

ManualResetDone: 
    LDI     YL, LOW(keyState)
    LDI     YH, HIGH(keyState) 
    LD      R17, Y+
    LD      R16, Y
    ANDI    R17, ~HIGH(MANUAL_RESET_ON)
    ANDI    R16, ~LOW(MANUAL_RESET_ON)
    RCALL   DisplaySwitchLEDs           ;turn off manual reset switch

    SBIW    Y, 1
    ST      Y+, R17 
    ST      Y, R16

    LDI     R18, SUCCESS_FLAG
    ;RJMP    EndManualReset


EndManualReset: 
    STS     stateFlag, R18 
    RET  
 




; GameOverWon 
;
; Description:       This function shows users that the game is won. 
;
; Operation:         Turn on the Win LED by calling DisplayWin. 
;
; Arguments:         None.
; Return Value:      stateFlag - For main loop to compare with Compare Value
;                                and decide which entry to go to in the main 
;                                loop table. Possible flags to return: 
;                                   SuccessFlag
;
; Local Variables:   None.
; Shared Variables:  stateFlag - written - SuccessFlag. 
;                     
; Global Variables:  None.
;
; Input:             None.
; Output:            Win LED is turned on(indirectly via LED Mux).  
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
; Stack Depth:       2 bytes. 
;
; Author:            Di Hu
; Last Modified:     June 8, 2019
 
GameOverWon:
    LDI     R16, TRUE
    RCALL   DisplayWin

    LDI     R16, ONE_SECOND_NOTE
    RCALL   Delay16
    
    LDI     R16, SUCCESS_FLAG
    STS     stateFlag, R16 
    RET  




; GameOverLost 
;
; Description:       This function shows users that the game is lost. 
;
; Operation:         Turn on the Lose LED by calling DisplayLose. 
;
; Arguments:         None.
; Return Value:      stateFlag - For main loop to compare with Compare Value
;                                and decide which entry to go to in the main 
;                                loop table. Possible flags to return: 
;                                   SuccessFlag
;
; Local Variables:   None.
; Shared Variables:  stateFlag - written - SuccessFlag. 
;                     
; Global Variables:  None.
;
; Input:             None.
; Output:            Lose LED is turned on(indirectly via LED Mux).  
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
; Stack Depth:       2 bytes. 
;
; Author:            Di Hu
; Last Modified:     June 8, 2019

GameOverLost: 
    LDI     R16, TRUE
    RCALL   DisplayLose

    LDI     R16, ONE_SECOND_NOTE
    RCALL   Delay16
    
    LDI     R16, SUCCESS_FLAG
    STS     stateFlag, R16 
    RET  


 




;the data segment

.dseg

randomCounter:        .BYTE   1            ;---
stateFlag:            .BYTE   1            ;---
moveCounter:          .BYTE   2            ;---
resetMoveCounter:     .BYTE   1            ;---
randomBuffer:         .BYTE   2            ;---
keyState:             .BYTE   2            ;---
; -----------------------------------------------------------------------
;| Digit |                               Bit                             | 
;|(Buffer|----------------------------------------------------------------
;| Byte) |   7   |   6   |   5   |   4   |   3   |   2   |   1   |   0   |
; -----------------------------------------------------------------------
;|   1   | SW11  | Lose  |**N/A**| SW12  |**N/A**| SW10  | SW9   | SW8   |
;|       | LED   | LED   |*******| LED   |*******| LED   | LED   | LED   | 
; -----------------------------------------------------------------------
;|   0   | SW3   | Win   |**N/A**| SW2   | SW4   | SW7   | SW6   | SW5   |
;|       | LED   | LED   |*******| LED   | LED   | LED   | LED   | LED   | 
; -----------------------------------------------------------------------
