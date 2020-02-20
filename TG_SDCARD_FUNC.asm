;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                             TG_SDCARD_FUNC                                 ;
;                            SD Card Routines                                ;
;                               Teaser Game                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the functions for initializing the Ver 2.x SDHC card and 
; reading/writing data from/to the SD card. The public functions included are:
;    InitSDCard         - initialize Ver 1.x SD card
;    ReadSDCard(b, p, n)- read n bytes of data from the SD card
;    WriteSDCard(b, p, n) - write n bytes of data to the SD card
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
;     6/1/19   Di Hu              initial revision
;     6/2/19   Di Hu              finished all functions' first revison
;	  6/3/19   Di Hu			  changed CMD8's CRC;
;								  fixed the last row in the init table;
;                                 fixed pointer conflict when reading data
;     6/5/19   Di Hu              - changed CPI with 0 to TST;
;                                 - changed filename from TGSDCARD to 
;                                   TG_SDCARD_FUNC


; local include files
;.include  "TG_SDCARD_DEF.inc"



.cseg



; WriteByte(byte) 
;
; Description:       This function writes a byte to the SD card. After sending 
;                    the byte, checks if SPIF in SPI status register is
;                    set, and returns the function when SPIF is set.
;
; Operation:         This function initializes Data Direction register and SPI
;                    control register for writing out data from Master to 
;                    Slave. Data is passed into SPI Data Register from R22. 
;                    The procedure is completed when SPIF is set. 
;
; Arguments:         R22 - byte to be sent to the SD card via SPI.
; Return Value:      None.
; 
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            A byte is written to the SD card.  
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
; Registers Changed: flags 
; Stack Depth:       0 bytes
;
; Author:            Di Hu
; Last Modified:     June 1, 2019

WriteByte: 

TransmitByte:
    OUT     SPDR, R22
    ;RJMP    WaitTransmission

WaitTransmission:
    SBIS    SPSR, SPIF
    RJMP    WaitTransmission    ;if SPIF is not set, keep waiting
    ;RJMP    EndTransmitByte

EndTransmitByte:                ;if SPIF is set, a byte is sent
    IN      R22, SPDR           ;reset SPIF flag

EndWriteByte:
    RET






; ReadByte
;
; Description:       This function is called after calling WriteByte function.
;                    This function reads the value returned by SD card in SPDR.
;
; Operation:         This function reads a byte from the SD card after calling 
;                    WriteByte function and stores the byte read in R22 when 
;                    SPIF in SPI status register is set. When SPIF is not set,
;                    waits for data transmission to finish. 
;
; Arguments:         None.
; Return Value:      R22 - byte read from the SD card via SPI.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            A byte is read from the SD card.  
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
; Registers Changed: flags, R22
; Stack Depth:       2 bytes
;
; Author:            Di Hu
; Last Modified:     June 1, 2019

ReadByte: 

SendToRead:
    LDI     R22, FF_BYTE        ;send 0xFF byte to read a byte
    RCALL   WriteByte
    ;RJMP    WaitReceiveByte

WaitReceiveByte:
    SBIS    SPSR, SPIF          
    RJMP    ReceivedByte        ;if SPIF is not set, keep waiting

ReceivedByte:
    IN      R22, SPDR           ;if SPIF is set, a byte is received, read in 
    ;RJMP    EndReadByte        

EndReadByte:
    RET







; SendCommand(c) 
; 
; Description:       Send 6-bytes command to SD card and wait for response. 
;
; Operation:         Load command bytes in currCommand to R22, and call
;                    WriteByte 6 times to send the command.
;
; Arguments:         currCommand - command sent to SD card for response 
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currCommand - read - command sent to SD card
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
; Registers Changed: flags, R17, R22, X(XH|XL)
; Stack Depth:       2 bytes
;
; Author:            Di Hu
; Last Modified:     June 1, 2019

SendCommand: 

StartSendCommand:
    LDI     R17, COMMAND_BYTES
    LDI     XL, LOW(currCommand)            ;point to the current command
    LDI     XH, HIGH(currCommand)

WriteAByte: 
    TST     R17                             ;see if all command bytes are sent
    BREQ    EndSendCommand                  ;if all sent, finished, return
    ;BRNE    SendAByte                      ;if not, keep sending

SendAByte: 
    LD      R22, X+                         ;load current byte to R22, point
                                            ;   to next byte
    RCALL   WriteByte
    DEC     R17                             ;decrement byte counter
    RJMP    WriteAByte

EndSendCommand:
    RET






; WaitToGetResponse(n)
; 
; Description:       This function waits for SD card to return a response and 
;                    raises timeout error after 64 clocks if no response is 
;                    returned.  
;
; Operation:         This function waits for response by sending 0xFF bytes, 
;                    and checks if the returned byte from SD card has zero
;                    MSB. If does, store response and wait for another 8 clocks
;                    before return; otherwise, keep waiting. This function also 
;                    checks for timeout error. If still receives 0xFF bytes 
;                    after sending 8 0xFF bytes, report timeout error. 
;
; Arguments:         R18 - number of bytes of the response expected to return 
; Return Value:      response - R1(and 4 bytes of 0xFF), or R3 or R7 returned 
;                               from SD card; MSB are all 0
;                    zero flag - set if receives 0xFF after 8 clocks, 
;                                clear if receives response 
;
; Local Variables:   None.
; Shared Variables:  response - written - total 5 bytes 
; 
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    zf set if timeout(8 clocks) occured, clear otherwise.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Limitation:        None.
;
; Known Bugs:        None. 
;
; Registers Changed: flags, R17, R18, R21, R22, X(XH|XL)
; Stack Depth:       4 bytes
;
; Author:            Di Hu
; Last Modified:     Jun 2, 2019

WaitToGetResponse:

StartWaiting:
    LDI     R21, NINE_BYTES_COUNTER         ;count 9 clocks of waiting

WaitingResponse:
    TST     R21                         
    BRNE    CheckResponseReceived           ;check response for 9 clocks
    ;BREQ    WaitingTimeOut                 ;timeout after received 9th 0xFF
    
WaitingTimeOut:
    SEZ                                     ;set zero flag to inidcate timeout
                                            ;   get response failed
    RJMP    EndWaitToGetResponse            ;exit

CheckResponseReceived:                      ;within 9 clocks, wait response
    DEC     R21                             ;decrement timeout counter
    RCALL   ReadByte                        ;new byte read into R22
	MOV 	R17, R22 						;copy read byte into R17 
    ANDI    R17, MSB_MASK                   ;check if recieved response
    BRNE    WaitingResponse                 ;not a response, keep waiting
    ;BREQ    PreStoreResponse               ;got response, store into data

PreStoreResponse:                           ;store 5 bytes received R1 or R3R7
    LDI     R21, RESP_SIZE                  ;set up byte counter
    LDI     XL, LOW(response)               ;point to response
    LDI     XH, HIGH(response)
    ;RJMP    StoreResponse 

StoreResponse:
    CPI     R18, R3R7_SIZE                  ;check if is expecting R3 or R7
    BRNE    StartStoreR1                    ;if not match, is expecting R1
    ;BREQ    PreStoreR3R7                   ;if yes, store R3 or R7

StartStoreR3R7:
    TST     R21                             ;check if stored all bytes
    BREQ    GotResponse                     ;stored all 5 bytes
    ;BRNE    StoreR3R7                      ;keep storing

StoreR3R7:
    ST      X+, R22                         ;store and point to next byte
    RCALL   ReadByte                        ;new byte read into R22
    DEC     R21                             ;decrement byte counter
    RJMP    StartStoreR3R7                  ;check if stored all bytes

StartStoreR1:
    ST      X+, R22                         ;store R1 and point to next byte
    DEC     R21                             ;decrement byte counter
    ;RJMP    CheckR1Full

CheckR1Full:                                ;check if stored 4 0xFF for R1
    TST     R21                             ;check if stored all bytes
    BREQ    GotResponse                     ;stored all 5 bytes
    ;BRNE    StoreFFForR1                   ;keep storing

StoreFFForR1:
    LDI     R22, FF_BYTE
    ST      X+, R22                         ;store 0xFF byte to fill 5 bytes
    DEC     R21                             ;decrement byte counter
    RJMP    CheckR1Full                     ;check if has sent 4 bytes of 0xFF

GotResponse:
    LDI     R22, FF_BYTE
    RCALL   WriteByte                       ;wait 8 clocks before pull SS high
    CLZ                                     ;received response, clear zf 

EndWaitToGetResponse:
    RET






; InitSDCard
;
; Description:       This function initializes Ver 2.x SDHC card(Ver 1.x and 
;                    Ver 2.x SD card not supported). After the function is 
;                    called, the SD card will be ready for read and write
;                    operations. The function returns 0 in R16 if SD     
;                    card is successfully initialized and returns 1 otherwise. 
;
; Operation:         This function initializes the Version 2.x SDHC card by 
;                    going through the following procedure:
;                       1. Wait for 1 ms
;                       2. Send 8 bytes (>75 clocks) 
;                       3. Send Command 0 with CRC 0x95
;                       4. Send Command 8 with CRC 0x87
;                       5. Check Illegal Command Bit in Response 1 is not set
;                       6. Check voltage accepted code and check pattern in R7
;                       7. Send Command 58 
;                       8. Check compatible voltage in R3
;                       9. Send Command 55
;                       10. Check Illegal Command Bit in Response 1 is not set
;                       11. Send Command 41, check idle state bit 
;                       12. Loop sending CMD58 and CMD41 till idle state bit
;                           is clear in response.
;                       13. Send Command 58
;                       14. Check CCS bit is set in OCR
;                    If any of the check in the above steps fails, set 
;                    R16 to ERROR_TRUE.
;                    This procedure is table driven. 
;
; Arguments:         None.
; Return Value:      R16 - clear(0) if SD card initialization is
;                    successful , set(1) if SD card initialization failed.
;
; Local Variables:   None.
; Shared Variables:  currCommand - written - passed to SendCommand function
; Global Variables:  None.
;
; Input:             None.
; Output:            The SD card is initialized. 
;
; Error Handling:    When initialization fails, return error true in R16. 
;
; Algorithms:        None.
; Data Structures:   None.
;
; Limitation:        Only V2.x SDHC cards are supported;
;                    V1.x SD card and V2.x SD card are not supported. 
;
; Known Bugs:        None. 
;
; Registers Changed: flags, R0, R1, R16, R17, R18, R19, R20, R21, R22, R23, 
;                    Z(ZH|ZL), Y(YH|YL)
; Stack Depth:       At least 6 bytes.
;
; Author:            Di Hu
; Last Modified:     Jun 4, 2019

InitSDCard:

StartInitSDCard: 
    LDI     R17, WAIT_FOR_ONEMS         ;set up 1 ms counter in R17

WaitOneMs: 
    DEC     R17
    TST     R17 
    BRNE    WaitOneMs                   ;not 1 ms yet, keep waiting 
    ;BREQ    PreSendManyClocks 

PreSendManyClocks:
	LDI     R17, BYTES_FOR_MANY         ;waited 1 ms, wait for 80 clocks
	;BREQ    SendManyClocks 	

StartSendManyClocks:
    TST     R17 
    BREQ    StartSDInitTable            ;waited 80 clocks, start sending cmds
    ;BRNE    SendManyClocks

SendManyClocks:                         ;not 80 clocks yet, keep waiting
    LDI     R22, FF_BYTE
    RCALL   WriteByte
    DEC     R17
    RJMP    StartSendManyClocks

StartSDInitTable:                       ;start sending cmds and cmp responses
    LDI     ZL, LOW(2 * SDInitTable)    ;start at the beginning of the table
    LDI     ZH, HIGH(2 * SDInitTable)
    ;RJMP    StartSendCmd

StartSendCmd:
    LDI     R17, COMMAND_BYTES          ;set byte counter
    LDI     YL, LOW(currCommand)        ;point to currCommand 
    LDI     YH, HIGH(currCommand)
    LPM     R18, Z+                     ;get a command byte from table
    ST      Y+, R18                     ;store the byte to currCommand
    DEC     R17                         ;decrement byte counter
    CPI     R18, CHK_RS          ;check if just needs to check response again
    BREQ    CheckResponseAgain          ;if is CHK_RS, check existing response
    ;BRNE    CheckCmdBytes               ;else, send normal command

CheckCmdBytes:
    TST     R17                        
    BREQ    CallSendCommand             ;all 6 bytes sent
    ;BRNE    SendMoreCMDByte            ;not all 6 bytes sent

SendMoreCMDByte:
    LPM     R18, Z+                     ;get a command byte from table
    ST      Y+, R18                     ;store the byte to currCommand
    DEC     R17                         ;decrement byte counter 
    RJMP    CheckCmdBytes               ;check if have sent 6 bytes 

CallSendCommand: 
    CBI     PORTB, SS_BIT               ;pull SS low, starts transmission
    RCALL   SendCommand 
    ;RJMP    StartWaitResponse

StartWaitResponse:
    LPM     R18, Z+                     ;get the expected response size 
    RCALL   WaitToGetResponse
    SBI     PORTB, SS_BIT               ;pull SS high, finishes transmission           
    BREQ    GetResponseFailed           ;if zf is set, timeout occured
    ;BRNE    GetResponseMask
    RJMP    GetResponseMask           

CheckResponseAgain:
    ADIW    Z, CHK_RS_OFFSET            ;skip command args and response len.
    ;RJMP    GetResponseMask

GetResponseMask:
    LPM     R19, Z+                     ;load 5 bytes of mask to R19..R23
    LPM     R20, Z+
    LPM     R21, Z+
    LPM     R22, Z+
    LPM     R23, Z+

MaskResponse:
    LDI     YL, LOW(response)           ;point to response
    LDI     YH, HIGH(response)
    LD      R17, Y+ 
    AND     R19, R17
    LD      R17, Y+ 
    AND     R20, R17
    LD      R17, Y+ 
    AND     R21, R17
    LD      R17, Y+ 
    AND     R22, R17
    LD      R17, Y+ 
    AND     R23, R17
    ;RJMP    CompareResponse

CompareResponse:
    LPM     R18, Z+                     ;get response compare value bytes
    CP      R18, R19
    LPM     R18, Z+
    CPC     R18, R20
    LPM     R18, Z+
    CPC     R18, R21
    LPM     R18, Z+
    CPC     R18, R22
    LPM     R18, Z+
    CPC     R18, R23
    BREQ    ResponseMatch
    ;BRNE    RespnseNonMatch

RespnseNonMatch:
    LPM     R16, Z+                     ;load error flag into R16
    LPM     R18, Z+                     ;get next step - offset to table addr
    RJMP    CheckError                  ;check for non-compatible card error 

ResponseMatch:
    ADIW    Z, MATCH_OFFSET
    LPM     R16, Z+                     ;load error flag into R16
    LPM     R18, Z+                     ;get next step - offset to table addr
    ;RJMP    CheckError                 ;check for non-compatible card error 

CheckError: 
    CPI     R16, ERROR_TRUE             ;check if error occured
    BREQ    GetResponseFailed           ;non-compatible card error, exit
    ;BRNE    CheckNextStep               ;didn't occur, check next step count

CheckNextStep:
    TST     R18                         ;check if step is < 0 
    BRLT    CheckReturnFlag             ;if < 0, it's a return flag, check it
    ;BRGE    PointToNewEntry             ;if > 0, calculate offset 

PointToNewEntry:
    LDI     R17, SD_TAB_RSIZE           ;load table row size for multiplication
    MUL     R17, R18                    ;get offset for random accessing
    LDI     ZL, LOW(2 * SDInitTable)    ;start at the beginning of the table
    LDI     ZH, HIGH(2 * SDInitTable)
    ADD     ZL, R0
    ADC     ZH, R1 
    RJMP    StartSendCmd                ;loop back to start a new command

;Finished with table accessing 
CheckReturnFlag:
    CPI     R18, V2_SDHC_RD             ;check if is Ver 2.x SDHC card ready
    BRNE    GetResponseFailed           ;if not, non-compatible card error
                                        ;  note again: this program does not 
                                        ;  support Ver 1.x and Ver 2.x SD card  
    ;BREQ    InitSucceeded

InitSucceeded:
    LDI     R16, ERROR_FALSE
    RJMP    EndInitSDCard

GetResponseFailed:
    LDI     R16, ERROR_TRUE
    ;RJMP    EndInitSDCard

EndInitSDCard:
    RET


; SDInitTable
;
; Description:      This table contains the values of arguments for 
;                   initializing Ver 1.x, Ver 2.x SD cards and Ver 2.x SDHC 
;                   cards. Each entry consists of 6-bytes command(including
;                   4-bytes Args and 1-byte CRC), expected response length, 
;                   AND-mask for response, compare value for validating the 
;                   response, error flag and next step for non-match or match
;                   response, which decide either quit table with exit flag or 
;                   what command to send next. There is also a padding byte at 
;                   the end of each test line.
;
; Author:           Di Hu
; Last Modified:    June 3, 2019

SDInitTable:
;                                                       Response                                                         Non-Match                   Match                       Padding
;           Cmd     Argument                  CRC       Len        Mask                     Compare Value                Error        Next Step      Error        Next Step
;
;step 0 - CMD0 
        .DB 0x40,   0, 0, 0, 0,               CMD0_CRC, R1_SIZE,   0, 0, 0, 0, 0,           0, 0, 0, 0, 0,               ERROR_FALSE, 1,             ERROR_FALSE, 1,             0

;step 1 - CMD8
        .DB 0x48,   0, 0, CMD8_VOL, CMD8_PAT, CMD8_CRC, R3R7_SIZE, ILL_CMD, 0, 0, 0, 0,     ILL_CMD, 0, 0, 0, 0,         ERROR_FALSE, 6,             ERROR_FALSE, 2,             0

;step 2 - CMD58
        .DB 0x7A,   0, 0, 0, 0,               0xFF,     R3R7_SIZE, 0, 0, OCR_VOL, 0, 0,     0, 0, 0, 0, 0,               ERROR_FALSE, 3,             ERROR_TRUE,  NON_COMP_CARD, 0

;step 3 - Check Response Again
        .DB CHK_RS, 0, 0, 0, 0,               0xFF,     0,         ILL_CMD, 0, 0, 0, 0,     ILL_CMD, 0, 0, 0, 0,         ERROR_FALSE, 4,             ERROR_TRUE,  NON_COMP_CARD, 0

;step 4 - CMD55
        .DB 0x77,   0, 0, 0, 0,               0xFF,     R1_SIZE,   ILL_CMD, 0, 0, 0, 0,     ILL_CMD, 0, 0, 0, 0,         ERROR_FALSE, 5,             ERROR_TRUE,  NON_COMP_CARD, 0

;step 5 - CMD41
        .DB 0x69,   0, 0, 0, 0,               0xFF,     R1_SIZE,   IDLE_ST, 0, 0, 0, 0,     IDLE_ST, 0, 0, 0, 0,         ERROR_FALSE, V1_RD,         ERROR_FALSE, 4,             0

;step 6 - Check Response Again
        .DB CHK_RS, 0, 0, 0, 0,               0xFF,     0,         0, 0, 0, CMD8_VOL, 0xFF, 0, 0, 0, CMD8_VOL, CMD8_PAT, ERROR_TRUE,  NON_COMP_CARD, ERROR_FALSE, 7,             0

;step 7 - CMD58
        .DB 0x7A,   0, 0, 0, 0,               0xFF,     R3R7_SIZE, 0, 0, OCR_VOL, 0, 0,     0, 0, 0, 0, 0,               ERROR_FALSE, 8,             ERROR_TRUE,  NON_COMP_CARD, 0

;step 8 - CMD55
        .DB 0x77,   0, 0, 0, 0,               0xFF,     R1_SIZE,   ILL_CMD, 0, 0, 0, 0,     ILL_CMD, 0, 0, 0, 0,         ERROR_FALSE, 9,             ERROR_TRUE,  NON_COMP_CARD, 0

;step 9 - CMD41
        .DB 0x69,   CMD41_HCS, 0, 0, 0,       0xFF,     R1_SIZE,   IDLE_ST, 0, 0, 0, 0,     IDLE_ST, 0, 0, 0, 0,         ERROR_FALSE, 10,            ERROR_FALSE, 8,             0

;step 10 - CMD58
        .DB 0x7A,   0, 0, 0, 0,               0xFF,     R3R7_SIZE,  0, CCS_R3, 0, 0, 0,     0, CCS_R3, 0, 0, 0,          ERROR_FALSE, V2_SD_RD,      ERROR_FALSE, V2_SDHC_RD,    0

EndSDInitTable:






; SendDataBlock(p, n)
; 
; Description:       This function sends a 515 byte data block to SD card:  
;                    a start block token, 512 byte user data, and 2 bytes CRC. 
;                    After sending the data block, checks the Data Write 
;                    Response see if any error is raised. 
;
; Operation:         This function takes user data(p) and its size(n) 
;                    as arguments. It send a 515-byte data block by calling
;                    WriteByte function. If n is less than 512, rest sent bytes 
;                    would be 0xFF. This function also Checks Data Write Response
;                    returned by SD card. If bit3, bit2, bit 1 is 010, data is
;                    accepted; otherewise, set ERROR_TRUE in R16.  
;
; Arguments:         p - passed in Y(R29|R28) by value - actual user data 
;                    n - in R16 - actual user data size  
; Return Value:      R16 - set ERROR_TRUE if found error in response
;
; Local Variables:   None.  
; Shared Variables:  None. 
; 
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    Set ERROR_TRUE True in R16 if data is not accepted.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Limitation:        None.
;
; Known Bugs:        None. 
;
; Registers Changed: flags, R16, R21, R22, R24, R25, Y(YH|YL)
; Stack Depth:       4 bytes
;
; Author:            Di Hu
; Last Modified:     Jun 1, 2019

SendDataBlock: 

StartSendDataBlock:
    LDI     R24, BLOCK_BYTES_L      ;set 512 bytes of total user data counter
    LDI     R25, BLOCK_BYTES_H
                                    ;R16 is actual user data counter 
    ;RJMP    SendStartToken

SendStartToken:                     ;first byte always send 0xFE
    LDI     R22, START_BLOCK_TOKEN
    RCALL   WriteByte 
    ;RJMP    StartSendUserData

StartSendUserData:
    TST     R16                     ;check if sent n bytes 
    BREQ    StartSendFFdata         ;if sent, check if need to send 0xFF
    ;BRNE    SendUserData           ;if not, send more bytes   

SendUserData:
    LD      R22, Y+                 ;data is passed by reference via Y
    RCALL   WriteByte               ;send data 
    DEC     R16                     ;decrement real user data counter 
    SBIW    R25:R24, 1              ;decrement 512 total user data counter
    RJMP    StartSendUserData       ;while do loop 

StartSendFFdata: 
    CLR     R21                     ;check if sent 512 bytes
    CP      R24, R21
    CPC     R25, R21                    
    BREQ    SendCRC                 ;if sent, send 2 bytes of CRC
    ;BRNE    SendFFdata             ;if not, send more bytes     

SendFFdata:
    LDI     R22, FF_BYTE
    RCALL   WriteByte               ;send a 0xFF byte
    SBIW    R25:R24, 1              ;decrement 512 total user data counter 
    RJMP    StartSendFFdata         ;while do loop 

SendCRC:
    LDI     R22, FF_BYTE            ;send two bytes of 0xFF as CRC
    RCALL   WriteByte
    LDI     R22, FF_BYTE
    RCALL   WriteByte
    ;RJMP    CheckWriteResponse      ;has sent all user data, check response

CheckWriteResponse: 
    RCALL   ReadByte                ;read response returned by SD card
    ANDI    R22, WRITE_RESPONSE_MASK;check bit3..bit1
    CPI     R22, WRITE_DATA_ACCEPTED;check if is accepted 
    BRNE    SendBlockFailed         ;not accepted, sending failed, set error
    ;BREQ    DataBlockSent           ;if accepted, sending succeeded

DataBlockSent:
    LDI     R16, ERROR_FALSE        ;data sent, clear error flag
    RJMP    EndSendDataBlock 

SendBlockFailed:
    LDI     R16, ERROR_TRUE         ;data not accepted, report error 
    ;RJMP    EndSendDataBlock

EndSendDataBlock:
    RET





; WaitForBusyToEndOnWrite
; 
; Description:       This function waits for busy state to end when after
;                    writing a data block.    
;
; Operation:         This function waits for busy state to end by continuously
;                    sending 0xFF bytes till an 0xFF byte is received. Then
;                    send a final 0xFF byte before toggle the Slave Select 
;                    high. This function also checks for timeout error. If an
;                    0xFF byte is not received after 250 ms, return timeout
;                    error in R17.
;
; Arguments:         None.  
; Return Value:      R17 - Set ERROR_TRUE if timeout occured. 
;
; Local Variables:   None.
; Shared Variables:  None.  
; 
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    Set ERROR_TRUE in R17 if timeout occured(after 250 ms). 
;
; Algorithms:        None.
; Data Structures:   None.
;
; Limitation:        None.
;
; Known Bugs:        None. 
;
; Registers Changed: flags, R17, R22, R24, R25 
; Stack Depth:       4 bytes
;
; Author:            Di Hu
; Last Modified:     Jun 1, 2019

WaitForBusyToEndOnWrite:

StartWaitForBusy: 
    LDI     R25, WAIT_BUSY_CNT_H
    LDI     R24, WAIT_BUSY_CNT_L
    ;RJMP    WaitBusyLoop

StartWaitBusyLoop:                      ;check if have waited for 250 ms
    CLR     R17
    CP      R24, R17
    CPC     R25, R17
    BRNE    KeepWaitBusy                ;not 250 ms yet, keep waiting 
    ;BREQ    BusyTimeOut                 ;have exceeded 250 ms, timeout occured

BusyTimeOut:
    LDI     R17, ERROR_TRUE             ;set timeout error in R17
    RJMP    EndWaitForBusy              ;return

KeepWaitBusy:
    SBIW    R25:R24, 1                  ;decrement time counter 
    RCALL   ReadByte                    ;read in byte to check busy status
    CPI     R22, FF_BYTE                ;busy end if R22 is 0xFF
    BRNE    StartWaitBusyLoop           ;keep waiting when busy not end 
    ;BREQ    BusyEnded 

BusyEnded:
    LDI     R17, ERROR_FALSE            ;busy state ended in 250 ms
                                        ;   clear error flag
    ;RJMP    EndWaitForBusy
       
EndWaitForBusy: 
    LDI     R22, FF_BYTE                ;wait another 8 clocks before pull
    RCALL   WriteByte                   ;   SS high by sending a byte 
    RET                                 








; WriteSDCard(b, p, n)
; 
; Description:       This function writes (n) bytes of data to the SD card at
;                    the passed block number (b). The data to write is stored
;                    at the passed data address (p). The number of bytes (n)
;                    is passed in R16 by value, the SD card block number (b)
;                    is passed in R20..R17 by value, and the address at which
;                    the data to write is stored (p) is passed in Y(R29|R28)
;                    by value (in orther words the buffer is passed by
;                    reference). If the number of bytes is less than the block
;                    size (512 bytes) the remaining bytes are filled with 0xFF
;                    so the function always writes 512 bytes. The function
;                    returns 0 in R16 if it successfully writes the bytes and 1  
;                    in R16 if any error occured. 
;
; Operation:         This function passes the block number in CMD24's arguments. 
;                    Then calls the SendCommand, WaitForResponse functions and 
;                    checks for timeout error from zero flag. And checks error 
;                    in R1. If error occured,  set ERROR_TRUE in R16; if no 
;                    error, calls SendDataBlock, and checks for writing error
;                    in R16. If no error returned, calls 
;                    WaitForBusyToEndOnWrite and check for timeout error in R17. 
;                    Set ERROR_TRUE flag in R16 if any error returned in the
;                    procedure, clear R16 otherwise. 
;                    
;
; Arguments:         b - in R20..R17 - block # of data to be written on SD card
;                    n - in R16 - number of user data bytes to be sent out 
;                    p - passed in Y(R29|R28) by value - data to write to SD   
; Return Value:      R16 - set ERROR_TRUE if found error, clear if not
;
; Local Variables:   None.
; Shared Variables:  currCommand - written - passed into SendCommand
;                    response - read - returned from WaitToGetResponse
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    ERROR_TRUE written into R16 if WriteSDCard failed. 
; Algorithms:        None.
; Data Structures:   None.
;
; Limitation:        None.
;
; Known Bugs:        None. 
;
; Registers Changed: flags, R16, R17, R18, R21, X(XH|XL)
; Stack Depth:       At least 6 bytes.
;
; Author:            Di Hu
; Last Modified:     Jun 2, 2019

WriteSDCard: 

PrepareCMD24:
    LDI     R21, CMD24
    LDI     XL, LOW(currCommand)            ;point to the current command
    LDI     XH, HIGH(currCommand)
    ST      X+, R21                         ;load command bytes to currCommand
    ST      X+, R20 
    ST      X+, R19 
    ST      X+, R18 
    ST      X+, R17
    LDI     R21, FF_BYTE
    ST      X+, R21                         ;send 0xFF as CRC  
    ;RJMP    StartWriteTransmission

StartWriteTransmission: 
    CBI     PORTB, SS_BIT                   ;pull SS low, transmission starts
    RCALL   SendCommand
    LDI     R18, R1_SIZE                    ;expecting R1, pass size to rcall
    RCALL   WaitToGetResponse               ;sent command, wait for response
    BREQ    WriteSDCardFailed               ;didn't get a response 
    ;BRNE    CheckResponseError              ;got response check for error 

CheckResponseError: 
    LDS     R17, response                   ;load R1 response into R17
    ANDI    R17, R1_ERROR_MASK              ;check error in R1 
    TST     R17 
    BRNE    WriteSDCardFailed               ;error occured, exit 
    ;BREQ    SendUserDataBlock               ;no error, start sending data 

SendUserDataBlock:
    RCALL   SendDataBlock                   ;send 515 bytes of data
                                            ;   error is returned in R16
    ;RJMP    WaitBusyToEnd

WaitBusyToEnd: 
    RCALL   WaitForBusyToEndOnWrite         ;wait for busy state to end
                                            ;   error is returned in R17 
    SBI     PORTB, SS_BIT                   ;pull SS high, transmission done
    ;RJMP    CheckWriteAndWaitError      

CheckWriteAndWaitError:
    OR      R16, R17                        ;check if has error in writing or
                                            ;   when waiting busy
    BREQ    EndWriteSDCard                  ;writing data succeeded                                      
    ;BRNE    WriteSDCardFailed               ;error occured

WriteSDCardFailed:                          ;R16 = ERROR_TRUE

EndWriteSDCard:                             ;R16 = ERROR_FALSE
    RET 






; WaitToReceiveData(p, n)
; 
; Description:       This function waits data to be ready to read by sending
;                    0xFF bytes and continuously check for MSB of the 
;                    received byte till it is zero. Then start to read in the 
;                    returned byte(s). 
;
; Operation:         This function waits for data to be prepared by keeping 
;                    sending 0xFF bytes to SD card till MSB of the received 
;                    byte is zero, if it exceeds 100 ms and no such byte is 
;                    recieved, report timeout error. After recieved a byte 
;                    with MSB being zero, checks if the byte received is 0xFE, 
;                    if is, calls ReadByte function to read 512 bytes of user 
;                    data and stores the fisrt n bytes in p; if it is not    
;                    0xFE, the received byte is a Data Read Error Token, sets
;                    ERROR_TRUE in R16. 
;
; Arguments:         n - in R16 - number of bytes to be read in 
;                    p - passed in Y(R29|R28) by value - data read from SD card  
; Return Value:      R16 - set ERROR_TRUE if found error in response
;
; Local Variables:   None.
; Shared Variables:  p - written - user data read from SD card
;                    n - read - size of user data in bytes 
; 
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    Set R16 ERROR_TRUE if Data Read Error Token is received or 
;                    timeout occured.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Limitation:        None.
;
; Known Bugs:        None. 
;
; Registers Changed: flags, R16, R17, R22, R24, R25, R26, R27, Y(YH|YL)
; Stack Depth:       4 bytes
;
; Author:            Di Hu
; Last Modified:     Jun 1, 2019

WaitToReceiveData: 

StartWaitToReceiveData: 
    LDI     R24, WAIT_DATA_COUNTER_L        ;set up 100 ms time counter 
    LDI     R25, WAIT_DATA_COUNTER_H

WaitToRecUserData:
    CLR     R17
    CP      R24, R17                        ;check if has passed 100 ms
    CPC     R25, R17 
    BREQ    ReceiveDataFailed               ;if passed, is timeout error 
    ;BRNE    KeepWaitUserData               ;if not, check read-in data 

KeepWaitUserData:   
    SBIW    R25:R24, 1                      ;decrement time counter 
    RCALL   ReadByte                        ;read in one byte in R22
    CPI     R22, FF_BYTE                    ;check if is user data 
    BREQ    WaitToRecUserData               ;if not, keep waiting 
    ;BRNE    CheckUserDataReceived          ;if is, check if is error 

CheckUserDataReceived:
    CPI     R22, START_BLOCK_TOKEN          ;check if is start token 
    BRNE    ReceivedErrorToken              ;if not, received error token 
    ;BREQ    StartStoreUserData             ;if is, store n bytes of data in p

StartStoreUserData:
    LDI     R26, BLOCK_BYTES_L              ;set up block size counter
    LDI     R27, BLOCK_BYTES_H
    TST     R16                             ;check if stored n bytes data 
    BREQ    StartReadMoreBytes              ;if stored, check if needs to read 
                                            ;   more byte from this block 
    ;BRNE    StoreUserData                  ;if not, keep store n bytes data 

StoreUserData:  
    DEC     R16                             ;decrement user data counter 
    SBIW    R27:R26, 1                      ;decrement block size counter 
    RCALL   ReadByte                        ;read in data in R22
    ST      Y+, R22                         ;store in p via Y 
    RJMP    StartStoreUserData              ;check if needs to store more data

StartReadMoreBytes:             
    CP      R26, R17                        ;check if whole block is read 
    CPC     R27, R17
    BREQ    ReceiveDataSucceed              ;if read, read in 2 bytes CRC 
    ;BRNE    ReadMoreBytes                  ;if not, read more but not storing

ReadMoreBytes:
    RCALL   ReadByte                        ;read rest byte in the block 
    SBIW    R27:R26, 1                      ;decrement block size counter 
    RJMP    StartReadMoreBytes              ;check if read the whole block 
    
ReceiveDataFailed:                          ;timeout occured 
    ;RJMP    ReceivedErrorToken

ReceivedErrorToken:                         
    LDI     R16, ERROR_TRUE                 ;set error flag in R16
    RJMP    EndWaitToReceiveData

ReceiveDataSucceed:
    RCALL   ReadByte                        ;read two bytes of CRC 
    RCALL   ReadByte
    LDI     R22, FF_BYTE                
    RCALL   WriteByte                       ;wait for another 8 clocks 
    LDI     R16, ERROR_FALSE                ;clear error flag in R16

EndWaitToReceiveData:
    RET






; ReadSDCard(b, p, n)
; 
; Description:       This function reads (n) bytes of data from the SD card at
;                    the passed block number (b). The data is stored at the
;                    passed address (p). The number of bytes (n) is passed in
;                    R16 by value, the SD card block number (b) is passed in
;                    R20..R17 by value, and the address at which to store the
;                    data (p) is passed in Y(R29|R28) by value (in other words
;                    the buffer is passed by reference). It is assumed that
;                    there is enough free memory at the passed address to
;                    store the bytes read by the procedure, If the number of
;                    bytes is less than the block size (512 bytes) the
;                    remaining bytes are read by the function, but not stored.
;                    The function returns 0(ERROR_FALSE) in R16 if it  
;                    successfully reads the bytes, and 1(ERROR_TRUE) in R16 
;                    otherwise.  
;
; Operation:         This function passes block number b into CMD17's 
;                    arguments. Then calls the SendCommand, WaitForResponse  
;                    functions and checks for timeout error from zero flag.
;                    And checks error in R1 returned from SD card.
;                    If error occured, set ERROR_TRUE flag in R16;
;                    if no error, calls WaitToReceiveData, and checks if any
;                    error is returned, if no, clear R16, set the ERROR_TRUE
;                    flag in R16 otherwise. 
;
; Arguments:         b - in R20..R17 - block # of data to be read in on SD card
;                    n - in R16 - number of bytes to be read in 
;                    p - passed in Y(R29|R28) by value - data read from SD card  
; Return Value:      R16 - set ERROR_TRUE if found error; else set ERROR_FALSE
;
; Local Variables:   None.
; Shared Variables:  currCommand - written - passed into SendCommand
;                    response - read - returned from WaitToGetResponse
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    ERROR_TRUE written into R16 if ReadSDCard failed.
; Algorithms:        None.
; Data Structures:   None.
;
; Limitation:        None.
;
; Known Bugs:        None. 
;
; Registers Changed: flags, R16, R17, R18, R21, X(XH|XL)
; Stack Depth:       At least 6 bytes.
;
; Author:            Di Hu
; Last Modified:     Jun 2, 2019

ReadSDCard: 

PrepareCMD17:
    LDI     R21, CMD17
    LDI     XL, LOW(currCommand)            ;point to the current command
    LDI     XH, HIGH(currCommand)
    ST      X+, R21                         ;load command bytes to currCommand
    ST      X+, R20 
    ST      X+, R19 
    ST      X+, R18 
    ST      X+, R17
    LDI     R21, FF_BYTE
    ST      X+, R21                         ;send 0xFF as CRC  
    ;RJMP    StartReadTransmission

StartReadTransmission: 
    CBI     PORTB, SS_BIT                   ;pull SS low, start transmission
    RCALL   SendCommand
    LDI     R18, R1_SIZE                    ;expecting R1, pass size to rcall
    RCALL   WaitToGetResponse               ;sent command, wait for response
    BREQ    ReadSDCardFailed                ;didn't get a response 
    ;BRNE    CheckReadResponseError          ;got response check for error 

CheckReadResponseError: 
    LDS     R17, response                   ;load R1 response into R17
    ANDI    R17, R1_ERROR_MASK              ;check error in R1 
    TST     R17 
    BRNE    ReadSDCardFailed                ;error occured, exit 
    ;BREQ    WaitDataPacket                  ;no error, waiting user data

WaitDataPacket: 
    RCALL   WaitToReceiveData               ;error flag is set in R16
    SBI     PORTB, SS_BIT                   ;pull SS high, transmission done 
    RJMP    EndReadSDCard                   ;done so return 

ReadSDCardFailed:
    LDI     R16, ERROR_TRUE                 ;read failed, set error flag true
    ;RJMP    EndReadSDCard                   ;done so return

EndReadSDCard:
    RET 






;the data segment

.dseg

response:       .BYTE   5   ;response returned from SendCommand 
currCommand:    .BYTE   6   ;command to be sent to SD card 

