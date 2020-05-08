.include "m48def.inc"
//.include "m8def.inc"

/*
 * Sources written in Atmel AVR Studio 5.1
 *
 * upload using command: avrdude -p atmega8 -c USBasp -U flash:w:KBD_CORRCTED.hex -U lfuse:w:0xCF:m -U hfuse:w:0xC7:m
 */ 

;------------------------------------------------
; set MCU type
; 0 - ATMega8
; 1 - ATMega48/88/168/328
;------------------------------------------------
#define MCU_TYPE 1

#define HOTKEYS 1
/*
1:	Reset = F12
	Magic = Print Screen
	Pause = Pause/Break
	Turbo-7MHz = Scroll Lock
	Turbo-14MHz = Right Shift + Scroll Lock

2:	Reset = Print Screen
	Magic = F12
	Pause = Pause/Break
	Turbo-7MHz = Scroll Lock
	Turbo-14MHz = Right Shift + Scroll Lock
*/

///////////////////////////////////////////////
// Коэффициент таймингов PS2 клавиатуры, MAX=25
// чем выше частота кварца, тем больше коэффициент и наоборот
// не все контроллеры могут работать с кварцами более 20МГц, т.к. Atmega8-16PU, 16Мгц :-D
// но большинство может тянуть 24МГц, а редкие экземпляры могут и 40МГц
.equ TIMING_COEFF	= 15
; 24 for 32 MHz (60000ns/31ns/80 = 24) 31ns 1 cycle time for 32MHz
; 23 for 30 MHz (60000ns/33ns/80 = 23) 33ns 1 cycle time for 30MHz
; 21 for 28 MHz (60000ns/36ns/80 = 21) 36ns 1 cycle time for 28MHz
; 20 for 27 MHz (60000ns/37ns/80 = 20) 37ns 1 cycle time for 27MHz
; 19 for 25 MHz (60000ns/40ns/80 = 19) 40ns 1 cycle time for 25MHz
; 18 for 24 MHz (60000ns/42ns/80 = 18) 42ns 1 cycle time for 24MHz
; 15 for 20 MHz (60000ns/50ns/80 = 15) 50ns 1 cycle time for 20MHz
; 12 for 16 MHz (60000ns/62ns/80 = 12) 62ns 1 cycle time for 16MHz
///////////////////////////////////////////////
;r0 - used
;r1 - used
.def PARITY=r2
;r3 - used
.def CONST00=r4
.def KBD_BYTE_PREV=r5
.def KBD_E0_FLAG=r6
.def CONST80=r7
.def KA08_ROW=r8
.def KA09_ROW=r9
.def KA10_ROW=r10
.def KA11_ROW=r11
.def KA12_ROW=r12
.def KA13_ROW=r13
.def KA14_ROW=r14
.def KA15_ROW=r15
;r16 tmp (used)
.def CONST7F=r17
;r18 tmp (used)
.def KBD_LOOP_CNT=r19
;r20 - used in INT interrupt
.def CONSTFF=r21
.def TURBO_MODE=r22	//Northwood
;r22 - free (used by Northwood for Turbo Mode)
.def KBD_STATE=r23
.def KBD_IND=r24
.def KBD_BYTE=r25

; KBD_STATE  
;		bit 0 symbol shift key (CTRL) released
;		bit 1 indicates #F0 prefix
; 		bit 2 caps shift key (SHIFT) released
; 		bit 3 бит отключения проверки сброса SHIFT статусов
; 		bit 4 symbol shift flag
; 		bit 5 caps shift flag
; 		bit 6 -----
; 		bit 7 Ext Mode set

; KBD_E0_FLAG - bit 7 indicates #E0 prefix

; SRAM MAP
; 0x100-0x1FF - Port #FE data
; 0x200-0x207 - Key Buffer
; 0x208-0x20F - Prepared data for port #FE
; 0x210 - Right Shift pressed


.equ 	RSHIFT_STATUS	= 0x210
.equ	TEMP_SRAM		= 0x211


.CSEG
.ORG	0x0000

;-----------------------------------------------------
; SET PROGRAM INTERRUPT VECTORS
;-----------------------------------------------------
RESET:
rjmp	_RESET			;(1, Power-on/Reset)


///////////////////////////////////////////////////////////////////////////////////////////
// INT 0 Interrupt Handler 4+14 cycles
// 16MHz: 1 cycle = 62ns, 62*9=558ns from falling edge to data set on port B достаточно много получается, может не работать
// 20MHz: 1 cycle = 50ns, 50*9=450ns from falling edge to data set on port B
// 24MHz: 1 cycle = 42ns, 42*9=378ns from falling edge to data set on port B
// 25MHz: 1 cycle = 40ns, 40*9=360ns from falling edge to data set on port B
// 27MHz: 1 cycle = 37ns, 37*9=333ns from falling edge to data set on port B
// 28MHz: 1 cycle = 36ns, 36*9=324ns from falling edge to data set on port B
// 30MHz: 1 cycle = 33ns, 33*9=297ns from falling edge to data set on port B
// 32MHz: 1 cycle = 31ns, 31*9=279ns from falling edge to data set on port B
// Чем быстрее работает это прерывание, тем лучше, а для этого частота кварца должна быть выше!
///////////////////////////////////////////////////////////////////////////////////////////

INT0_Vector:

	in		YL, PinD		; PinD -> YL receive data from bus							; 1 cycle
	
	// ------- 2 cycle both -------------
	sbic	PinC,0x03	; if (PinC.3=0) skip next line (IF KA10=0)				; 1/2 cycle, 2 byte instruction
	bld 	YL, 2		; move bit 3 of port C to bit 2 of data from port D		; 1 cycle, 2 byte instruction
	// ----------------------------------

	ldd		r20, Y+0x00	; put data to r20 from SRAM key table at 0x100+YL			; 2 cycles, 4 byte instruction
	
	//4+5 cycles before set data on port FE
	out		DDRB, r20																; 1 cycle, 2 byte instruction
	rjmp 	INT0_Hander

#if MCU_TYPE == 0

TIMER1_MatchB_Vector:
	rjmp TIMER1_MatchB_Handler

#elif MCU_TYPE == 1

TIMER2_MatchA_Vector:
	nop

TIMER2_MatchB_Vector:
	nop

TIMER2_Ovf_Vector:
	nop

TIMER1_Capt_Vector:
	nop

TIMER1_MatchA_Vector:
	rjmp TIMER1_MatchA_Handler

#endif

INT0_Hander:
	// ------ 3 cycle, 6 bytes
HOLD_BUS: ; hold data on bus while /RDFE=0
	sbis	PinD, 0x02	;if PinD.2=1 skip rjmp
	rjmp	HOLD_BUS
	// --------------

	//out DDRB,CONST00	; turn data bus to HI-Z state								; 1 cycle, 2 byte instruction
	out		DDRB, TURBO_MODE	; turn data bus to HI-Z state, excluding TurboMode bits	; 1 cycle, 2 byte instruction
	reti																			; 4 cycles
///////////////////////////////////////////////////////////////////////////////////////////	14 cycles

#if MCU_TYPE == 0

TIMER1_MatchB_Handler:

#elif MCU_TYPE == 1

TIMER1_MatchA_Handler:

#endif

	sts		TEMP_SRAM, r18
	sts		TCCR1B, CONST00 ;останавливаем счётчик, чтобы больше не считал
	pop		r18			;Перемещаем указатель стека на два адреса возврата раньше,
	pop		r18			;чтобы по reti вернуться не в прерванную подпрограмму, а на 2 ret раньше
	pop		r18
	pop		r18
	lds		r18, TEMP_SRAM
	sec					;Устанавливаем флаг переноса - признак, что CLK от клавиатуры не дождались
	reti

/*	Помигать индикатором на клавиатуре оказалось плохой идеей.
TIMER1_MatchA_Handler:
	cli
	sts		TCNT1H, CONST00
	sts		TCNT1L, CONST00
	sbrc	TURBO_MODE, 0x07
	rcall	SCROLL_IND_FLASH
	sei
	reti
*/

///////////////////////////////////////////////////////////////////////////////////////////
// PROGRAM START
///////////////////////////////////////////////////////////////////////////////////////////

_RESET:

	clr r18
	sts RSHIFT_STATUS, r18
	// Port C setup first for not switching keys (turbo,magic)
	ldi	r18,0x08		; set LOW output on C0-C2,C4-C5 C3 Pull Up
	out	PortC,r18

	// Init constant
	ser CONSTFF			; 0xFF -> CONSTFF
	clr TURBO_MODE		; Turbo Mode Off

	// Port D
	out	PortD,CONSTFF	; all pins with pullup

	// Init constant
	clr	CONST00			; 0x00 -> CONST00

	; disable Analog Comparator ==============================
#if MCU_TYPE == 0
	sbi ACSR,ACD			; for atmega8
#elif MCU_TYPE == 1
	ldi r16,ACD				; for ATMEGA48/88/168/328
	rcall SET_BIT
	out ACSR,r18
#endif	
	;=========================================================

	// init stack pointer 0x45F
	ldi	r16,low(RAMEND)
	out	SPL,r16
	ldi	r16,high(RAMEND)
	out	SPH,r16


#if MCU_TYPE == 0
	; set INT0 ATMEGA8 =========================================
	ldi r16,ISC01		; falling edge int 0
	rcall SET_BIT
	out MCUCR,r18	
	ldi r16,INTF0		; clear int0 flag
	rcall SET_BIT
	out GIFR,r18
	ldi r16,INT0		; enable int0 interrupt
	rcall SET_BIT
	out GICR,r18
    ; ==========================================================
#elif MCU_TYPE == 1
	; set INT0 ATMEGA48/88/168/328 =============================

	ldi r16,ISC01		; falling edge
	rcall SET_BIT
	sts EICRA,r18
	ldi r16,INTF0		; clear int0 flag
	rcall SET_BIT
	out EIFR,r18
	ldi r16,INT0		; enable int0 interrupt
	rcall SET_BIT
	out EIMSK,r18

	; ==========================================================
#endif

//Прерывания для ограничения ожидания от клавиатуры CLK

#if MCU_TYPE == 0
	; set Timer1CounterB ATMEGA8 =========================================

	//ldi		r16, CS12		//предделитель счётчика = 256, сейчас устанавливать нельзя
	//rcall	SET_BIT
	//sts		TCCR1B, r18

	ldi		r18, high(79*TIMING_COEFF)
	sts		OCR1BH, r18
	ldi		r18, low(79*TIMING_COEFF)		//период прерываний = 15 мс
	sts		OCR1BL, r18
	ldi		r16, OCIE1B		//разрешить прерывание MatchB, но заработают они только после установки источника тактирования счётчика
	rcall	SET_BIT
	sts		TIMSK, r18

#elif MCU_TYPE == 1
	; set Timer1CounterA ATMEGA48/88/168 =========================================

	//ldi		r16, CS12		//предделитель счётчика = 256, сейчас устанавливать нельзя
	//rcall	SET_BIT
	//sts		TCCR1B, r18
	ldi		r18, high(79*TIMING_COEFF)
	sts		OCR1AH, r18
	ldi		r18, low(79*TIMING_COEFF)		//период прерываний = 15 мс
	sts		OCR1AL, r18
	ldi		r16, OCIE1A		//разрешить прерывание MatchA, но заработают они только после установки источника тактирования счётчика
	rcall	SET_BIT
	sts		TIMSK1, r18

#endif
/*
Идея мигать индикатором на клавиатуре оказалось плохой
	ldi		r18, 0x05		//предделитель счётчика = 1024
	sts		TCCR1B, r18
	ldi		r18, high(1953)
	sts		OCR1AH, r18
	ldi		r18, low(1953)		//частота прерываний = 10 Гц
	sts		OCR1AL, r18
	ldi		r18, 0x02		//разрешить прерывание MatchA
	sts		TIMSK1, r18
*/

	SET				; 1 -> T for fast bit set in interrupt

	// Init constants
	ldi		XH,0x02	; set XH for SRAM 0x200 addresses manipulation
	ldi		r16,0x80
	mov		CONST80,r16
	ldi		r16,0x7F
	mov		CONST7F,r16

INIT_KBD:
	rcall	LONG_WAIT_50		; вызов подпрограммы длинного цикла ожидания инициализации клавиатуры
	rcall	KBD_RESET
	brcs	KBD_MAIN		; в случае ошибки отправки RESET, игнорируем и идём в главный цикл
	brne	INIT_KBD		; если RESET отправился успешно, но получили неверный ответ от клавиатуры, тогда повторяем сброс

;---- Бесконечный цикл, если не инициализировалось -----------------------
//ENDLESS_LOOP:
//	rjmp	ENDLESS_LOOP
;-------------------------------------------------------------------------


// Обработчик клавиатуры
///-----------------------------------------------------------------------
KBD_MAIN:	//начало
	// set scan code 2
	ldi KBD_BYTE,0xF0
	rcall KBD_SEND
	ldi KBD_BYTE,2
	rcall KBD_SEND

	// enable scan
	ldi KBD_BYTE,0xF4
	rcall KBD_SEND

KBD_MAIN_R:
	// init indicators
	ldi KBD_IND,0x03				; bit0 - Scroll Lock (Turbo 7/14MHz), bit1 - Num Lock, bit2 - Caps Lock
	ldi TURBO_MODE, 0x20
	rcall	KBD_SEND_INDICATORS
	
K_REINIT:

; очистка и заполнение SRAM
	//ldi	XH,0x02		; load SRAM address 0x200 (keyboard buffer)
	clr	XL
; очистка клавиатурного буфера
CLEAR_BYTE:
	st	X+,CONST00		; fill byte with 0 and increase X
	sbrs	XL,0x03			; пока XL меньше 8 цикл
	//sbrs	XL,0x04			; пока XL меньше 8 цикл
	rjmp	CLEAR_BYTE
; заполнение памяти порта FE (0x7F,...,0xFE) значениями 0xFF
	ldi	ZH,0x01			; load SRAM address 0x100
	clr	ZL
CLEAR_BYTE_FE:
	st	Z+,CONST00		; fill byte 255 and increase X
	tst	ZL			; repeat while X < 0x200
	brne	CLEAR_BYTE_FE

	clr	KBD_STATE
	clr	KBD_BYTE_PREV
	clr	KBD_E0_FLAG
	ldi	YH,0x01			; port FE table at 0x17F,...,0x1FE

	sei					; 1->I разрешить прерывания

NEW_KBD_LOOP:

;------ чтение байта от клавиатуры -------------------------------------
	rcall	KBD_READ0		; read byte from keyboard
	brcs	K_REINIT		; if parity error do reinit SRAM tables
;-----------------------------------------------------------------------

	cpi	KBD_BYTE,0xF0		; check for prefix #F0
	brne	NOT_F0
	ori	KBD_STATE,0x02		; set bit 1, indicates that prefix #F0 set
	rjmp	NEW_KBD_LOOP

NOT_F0:
	cpi	KBD_BYTE,0xE0		; check for prefix #E0
	brne	NOT_E0
	mov	KBD_E0_FLAG,CONST80		; set flag indicates prefix #E0 and repeat
	rjmp	NEW_KBD_LOOP

NOT_E0:
	cpi	KBD_BYTE,0xE1		; check for E1 prefix (e.g. for "Pause" key)
	brne	NOT_PAUSE

	; if pause pressed - skip 7 bytes (scan code 8 bytes!) --------
	ldi	r18,0x07

PAUSE_PRESSED:
	sbic DDRC, 0x02
	rjmp PAUSE_OFF
	sbi DDRC, 0x02
	rjmp PAUSE_KEY_SKIP
PAUSE_OFF:
	cbi DDRC, 0x02
PAUSE_KEY_SKIP:
	rcall	KBD_READ0
	dec	r18
	brne	PAUSE_KEY_SKIP
	rjmp	NEW_KBD_LOOP
	; -------------------------------------------------------------

NOT_PAUSE:
	cpi	KBD_BYTE,0x83		; F7 keycode has bit 7 set... so replace it with keycode not defined in PS/2 scancode set 2
	brne	NOT_83
	ldi	KBD_BYTE,0x08		; replace 0x83 with 0x08 (not defined code) to not affect bit 7

NOT_83:
	or	KBD_BYTE,KBD_E0_FLAG	; add E0 flag to bit 7 of key code
	clr	KBD_E0_FLAG		; clear E0 prefix flag
	sbrc	KBD_STATE,0x01		; check KBD_STATE bit 1, if set then used prefix #F0
	rjmp	F0_SET			; jump to F0 keys set


; HERE IS Press key scan codes processing --------------------------------------------------------------------------

	; skip repeatable codes
	cp	KBD_BYTE_PREV,KBD_BYTE	; if KBD_BYTE = previous value repeat loop
	breq	NEW_KBD_LOOP
	mov	KBD_BYTE_PREV,KBD_BYTE

	cpi	KBD_BYTE,0x07		; check F12 pressed
	brne	CHECK_F11

#if HOTKEYS == 1
	; Reset button
	sbi		DDRC, 0		; set Reset - output LOW
#elif HOTKEYS == 2
	; Magic button
	sbi		DDRC, 1		; set Magic - output LOW
#endif
	rjmp	NEW_KBD_LOOP

CHECK_F11:
	cpi	KBD_BYTE,0x78		; check F11 pressed
	brne	CHECK_PRINT_SCREEN
	; Push BTN2
	//sbi	DDRC,0x02		; set BTN2 - output LOW

	rjmp	NEW_KBD_LOOP

CHECK_PRINT_SCREEN:
	cpi	KBD_BYTE,0xFC		; #E0, 0x7C print screen pressed second 2 bytes process Magic button
	brne	CHECK_SHIFTS
	
#if HOTKEYS == 1
	; magic button
	sbi		DDRC, 1	; Magic - output LOW
#elif HOTKEYS == 2
	; reset button
	sbi		DDRC, 0	; Reset - output LOW
#endif
	rjmp	NEW_KBD_LOOP

CHECK_SHIFTS:						; check SYMBOL SHIFT key pressed (Left and right CTRL keys)
	cpi		KBD_BYTE,0x94		; check RIGHT CTRL pressed
	breq	SET_SYMSHIFT_FLAG
	cpi		KBD_BYTE,0x14		; check LEFT CTRL pressed
	breq	SET_SYMSHIFT_FLAG
	cpi		KBD_BYTE,0x59		; check RIGHT SHIFT pressed
	breq	SET_CAPSSHIFT_FLAG
	cpi		KBD_BYTE,0x12		; check LEFT SHIFT pressed
	breq	SET_CAPSSHIFT_FLAG
	rjmp	CHECK_NUMLOCK

SET_CAPSSHIFT_FLAG:
	cpi		KBD_BYTE, 0x59
	brne	SET_CAPSSHIFT_FLAG0
	ldi r18, 0x01
	sts RSHIFT_STATUS, r18
SET_CAPSSHIFT_FLAG0:
	ori		KBD_STATE,0x20		; Set Caps Shift Flag Bit 5
	rjmp	UPDATE_KEY_BUFFER

SET_SYMSHIFT_FLAG:
	ori		KBD_STATE,0x10		; Set Symbol Shift Flag Bit 4
	rjmp	UPDATE_KEY_BUFFER


CHECK_NUMLOCK:
	cpi	KBD_BYTE,0x77		; check NUM_LOCK
	brne	CHECK_CAPSLOCK

	ldi		XL,0x02
	eor		KBD_IND,XL		; XOR with indicator value for NumLock
	rcall	KBD_SEND_INDICATORS

	rjmp	K_REINIT		; reinit keyboard keytables after numlock key pressed

CHECK_CAPSLOCK:
	cpi		KBD_BYTE,0x58		; check Caps Lock
	brne	CHECK_SCROLLOCK
	ldi		XL,0x04
	eor		KBD_IND,XL	; XOR with indicator value for CapsLock
	rcall	KBD_SEND_INDICATORS
	ldi		KBD_BYTE,0x58	; kestore key value
	rjmp	UPDATE_KEY_BUFFER

CHECK_SCROLLOCK:
	cpi		KBD_BYTE,0x7E		; check Scroll Lock
	brne	UPDATE_KEY_BUFFER

	lds		r18, RSHIFT_STATUS
	cpi		r18, 0x00
	brne	CHECK_TURBO14
CHECK_TURBO7:
	cpi		TURBO_MODE, 0x20
	brne	SET_TURBO7
	ldi		TURBO_MODE, 0x00
	rjmp	UPDATE_SCROLL_IND
SET_TURBO7:
	ldi		TURBO_MODE, 0x20
	rjmp	UPDATE_SCROLL_IND
	
CHECK_TURBO14:
	sbrs	TURBO_MODE, 0x07
	rjmp	SET_TURBO14
	ldi		TURBO_MODE, 0x00
	rjmp	UPDATE_SCROLL_IND
SET_TURBO14:
	ldi		TURBO_MODE, 0xA0

UPDATE_SCROLL_IND:
	andi	KBD_IND, 0x06
	and		TURBO_MODE, TURBO_MODE
	breq	SET_TURBO_IND
	ori		KBD_IND, 0x01

/*
	andi	KBD_IND, 0x04
	sbrc	TURBO_MODE, 5
	ori		KBD_IND, 0x01
	sbrc	TURBO_MODE, 7
	ori		KBD_IND, 0x02
*/
SET_TURBO_IND:
	rcall	KBD_SEND_INDICATORS

	rjmp	K_REINIT		; reinit keyboard keytables after Scrolllock key pressed

	; Process pressed key -----------------------------------------------------------------------

UPDATE_KEY_BUFFER:	
	//ldi	XH,0x02			; keybuffer for key sequencies 0x200
	ldi	XL,0x00

	; try to add key to end of buffer
KP_LOOP:
	ld	r18,X+			; read value from buffer
	cp	r18,KBD_BYTE		; check with scan code
	breq	RELOOP			; if key already in buffer - go to next "read key" loop cycle

	tst	r18			; check current value in buffer
	brne	KP_BUF_NOTZERO		; jump if not zero (repeat if not end of buffer)
	st	-X,KBD_BYTE		; store byte where zero value was found
	rjmp	PROCESS_KBD_BUFFER

KP_BUF_NOTZERO:
	sbrs	XL,0x03			; if XL < 8 repeat buffer loop, or exit from loop if buffer overflow
	rjmp	KP_LOOP

RELOOP:
	rjmp	NEW_KBD_LOOP


; process F0 prefixes, #E0 also may be set as 7 bit of KBD_BYTE
; F0 prefixe set when key release, so we need to remove key from the buffer
; HERE IS Release key scan codes processing ---------------------------------------------------------------------------

F0_SET:
	clr	KBD_BYTE_PREV   	; clear previous key value
	andi	KBD_STATE,0xFD		; clear F0 prefix flag

	cpi	KBD_BYTE,0xFC		; #E0, 0x7C print screen released second 2 bytes process RESET button
	brne	CHECK_RSHIFT_OFF

#if HOTKEYS == 1
	; Magic button
	cbi		DDRC, 1	; Magic inactive, HI-Z mode
#elif HOTKEYS == 2
	; Reset button
	cbi		DDRC, 0	; Reset inactive, HI-Z mode
#endif
	rjmp	NEW_KBD_LOOP
	//rjmp	KBD_MAIN_R

CHECK_RSHIFT_OFF:
	cpi KBD_BYTE, 0x59
	brne CHECK_F12_OFF
	ldi r18, 0x00
	sts RSHIFT_STATUS, r18

CHECK_F12_OFF:
	cpi	KBD_BYTE,0x07		; check F12 button released
	brne	CHECK_F11_OFF

#if HOTKEYS == 1
	; Release Reset
	cbi		DDRC, 0		; set Reset pin inactive, HI-Z mode
#elif HOTKEYS == 2
	; Release Magic
	cbi		DDRC, 1		; set Magic pin inactive, HI-Z mode
#endif
	rjmp	NEW_KBD_LOOP

CHECK_F11_OFF:
	cpi	KBD_BYTE,0x78		; check F11 button released
	brne	CHECK_SHIFTS_OFF
	; Release BTN2
	//cbi	DDRC,0x02		; set BTN2 pin inactive, HI-Z mode
	rjmp	NEW_KBD_LOOP

CHECK_SHIFTS_OFF:
	// CTRL check
	cpi		KBD_BYTE,0x94		; right ctrl released
	breq	K_REINIT2
	cpi		KBD_BYTE,0x14		; left ctrl released
	breq	K_REINIT2
	// SHIFT check
	cpi		KBD_BYTE,0x59			; right shift released
	breq	K_REINIT2
	cpi	KBD_BYTE,0x12			; left shift released
	breq	K_REINIT2

	; Process released key -----------------------------------------------------------------------

UPDATE_KEYBUFFER_OFF:
	//ldi	XH,0x02                 ; keybuffer for key sequencies 0x200
	ldi	XL,0x00
KR_LOOP:
	ld	r18,X+      		; read value from buffer
	cp	r18,KBD_BYTE		; check with scan code
	breq	KEY_FOUND0		; jump if key found
	sbrs	XL,0x03			; if XL >= 8 key not found in a buffer, jump to reinit keyboard
	rjmp	KR_LOOP			; check next value in a buffer
	rjmp	K_REINIT

	; Key found in a buffer
KEY_FOUND0:
	sbrs	XL,0x03
	rjmp	NOT_BUF_END

	st	-X,Const00		; set zero value at the end of the buffer
	rjmp	PROCESS_KBD_BUFFER
NOT_BUF_END:
	// берем следующее значение из буфера и сдвигаем его назад
	ld	r18,X
	st	-X,r18
	subi	XL,0xFE		; XL += 2,
	rjmp	KEY_FOUND0	

PROCESS_KBD_BUFFER:		; обработка буфера клавиатуры
////////////////////////////////////////////////////////////////////////////////////////////////////
	//ldi	XH,0x02			; 0x208 -> X, адреса рядов клавиатуры ZX порта FE
	ldi	XL,0x08

L018B: // loop заполняем значения для рядов (данные для KA8,..KA15) значением 0xFF
	st	X+,CONSTFF		; 0xFF -> [0x208+]
	sbrs	XL,0x04			; пока не станет равно 0x210 повторяем т.е. пока XL < 16
	rjmp	L018B
	
	andi	KBD_STATE,0xF7	; clear bit 3
	ldi	XL,0x00			; 0x200 -> X
	// ------------------------------------------------
L0192: //loop 
	ld	r18,X+
	tst	r18				; если нулевое значение в буфере, то на следующую итерацию
	breq	L019C

	; в r18 значение клавиши из буфера

	//KEYTABLE ////////////////////////////////////////
	// выборка значения из KEYTABLE'S
	ldi	ZH,high(KEYTABLE*2)
	ldi	ZL,low(KEYTABLE*2)
	add	ZL,r18
	brcc	L019A			; если смещение больше 255 увеличиваем ZH
	inc	ZH
L019A:
	lpm						; [Z] -> R0 выбрали значение для клавиши из KEYTABLE'S
	rcall	CHECK_ALT_KEY	; проверка битов алтьтернативной таблицы в коде клавиши

L019C:
	sbrs	XL,0x03
	rjmp	L0192			; если XL < 8 цикл    
	// ------------------------------------------------

	sbrc	KBD_STATE,0x03	; если бит 3 установлен не проверяем состояния SymbolShift, CapsShift, т.к. уже проверено в CHECK_ALT_KEY
	rjmp	L01A4
	
	// check symbolshift key released flag
	sbrc	KBD_STATE,0x00		; return if bit 0 is not set (reset SymbolShift flag)
	andi	KBD_STATE,0xEE		; сброс SymbolShift и Release SymbolShift флагов (0 и 4 биты)
	// check capsshift key released flag
	sbrc	KBD_STATE,0x02		; return if bit 2 is not set (reset CapsShift flag)
	andi	KBD_STATE,0xDB		; сброс CapsShift и Release CapsShift флагов (2 и 5 биты)

	sbrc	KBD_STATE,0x04	; проверка SymbolShift
	rjmp	SS_BIT_PROCESS

	sbrc	KBD_STATE,0x05	; проверка CapsShift
	rjmp	CS_BIT_PROCESS
K_REINIT2:
	rjmp	K_REINIT

SS_BIT_PROCESS:
	rcall	SET_SS_BIT

	sbrc	KBD_STATE,0x05	; проверка CapsShift	///////
	rjmp	CS_BIT_PROCESS					///////

	rjmp	L01A4

CS_BIT_PROCESS:
	rcall	SET_CS_BIT

L01A4:
	rcall	FILL_PORT_FE
	andi	KBD_STATE,0x7F	; clear bit 7

RELOOP2:
	rjmp	NEW_KBD_LOOP
//////////Конец обработчика клавиатуры



///////// Всякие подпрограммы

/*
Помигать индикатором на клавиатуре оказалось плохой идеей
SCROLL_IND_FLASH:	;Мерцание Scroll Lock индикатора
	push	r18
	ldi		r18, 0x01
	eor		KBD_IND, r18
	rcall	KBD_SEND_INDICATORS
	pop		r18
	ret
*/

//Процедуру сброса клавиатуры вынес в подпрограмму
KBD_RESET:
	rcall	LONG_WAIT_15		; вызов подпрограммы длинного цикла ожидания
	mov		KBD_BYTE, CONSTFF	; 0xFF->KBD_BYTE // Keyboard Command RESET
	rjmp	KBD_SEND			; отправить команду

; --- Заполнение адресов порта #FE данными о нажатых клавишах
FILL_PORT_FE:
	ldi XL,0x08
	clr	ZH
	ldi	ZL,0x08
L01AA:
	ld	r18,X+		; [X++]->r18
	com r18					; invert value for DDRB work
	st	Z+,r18		; r18->[Z++] помещаем значения непосредственно в регистровую память регистров KA08_ROW-KA15_ROW
	cpi	XL,0x10
	brne	L01AA  		; loop пока XL!=0x10

	ldi	ZH,0x01	
	mov	ZL,CONSTFF
	clr	r18
	st	Z,r18		; 0xFF -> [0x1FF]
CALC_ROW_VALUE:
	// вычисление адреса порта FE (т.е. где в памяти находятся байты для KA8,KA9,...,KA15)
	dec		ZL
	clr		r18
	sbrs	ZL,0x00
	or		r18,KA08_ROW
	sbrs	ZL,0x01
	or		r18,KA09_ROW
	sbrs	ZL,0x02
	or		r18,KA10_ROW
	sbrs	ZL,0x03
	or		r18,KA11_ROW
	sbrs	ZL,0x04
	or		r18,KA12_ROW
	sbrs	ZL,0x05
	or		r18,KA13_ROW
	sbrs	ZL,0x06
	or		r18,KA14_ROW
	sbrs	ZL,0x07
	or		r18,KA15_ROW
	or		r18,TURBO_MODE	//Nothwood
	st		Z,r18
	tst		ZL
	brne	CALC_ROW_VALUE	; пока XL больше 0
	
	ret


;----------------------------------------------------
CHECK_ALT_KEY:
	tst	r0
	brne	L0222
	; если клавиша с нулевым значением нет признака отпускания Caps/Symbol Shift то выходим
	sbrc	KBD_STATE,0x00
	rjmp	L0222
	sbrc	KBD_STATE,0x02
	rjmp	L0222
	ret
L0222:
	sbrs	r0,0x07
	rjmp	NO_ALT
	sbrc	r0,0x06
	rjmp	USE_ALT_KEYTABLE
NO_ALT:
	// check symbolshift key released flag
	sbrc	KBD_STATE,0x00		; return if bit 0 is not set (reset SymbolShift flag)
	andi	KBD_STATE,0xEE		; сброс SymbolShift и Release SymbolShift флагов (0 и 4 биты)
	// check capsshift key released flag
	sbrc	KBD_STATE,0x02		; return if bit 2 is not set (reset CapsShift flag)
	andi	KBD_STATE,0xDB		; сброс CapsShift и Release CapsShift флагов (2 и 5 биты)

	sbrc	KBD_STATE,0x04
	rcall	SET_SS_BIT
	
	sbrc	KBD_STATE,0x05
	rcall	SET_CS_BIT

PROCESS_KEYCODE:
	ori	KBD_STATE,0x08
	sbrc	r0,0x06
	rcall	SET_SS_BIT
	
	sbrc	r0,0x07
	rcall	SET_CS_BIT
	

	mov	r18,r0
	andi	r18,0x07		; remove shift bits from keycode
	mov	r1,r18				; move data bits value to r1
	ldi	r18,0xFE			; Set default bits value for bit 0

L023B:	// check bit loop
	dec	r1
	breq	L0240			; break loop if r1=0
	sec
	rol	r18					; move to next bit and set bit 0
	rjmp	L023B

L0240: // find value in keybuffer 0x200 using address bits
	ldi	ZH,0x02
	mov	ZL,r0
	lsl	ZL
	swap	ZL
	andi	ZL,0x07
	subi	ZL,0xF8

L0246:
	ld	r1,Z
	and	r1,r18
	st	Z,r1
	ret

L0247:
	ld	r1,Z
	or	r1,r18
	st	Z,r1
	ret


;----------------------------------------------------
SET_CS_BIT:
	ldi	ZH,0x02
	ldi	ZL,0x08				; KA08
	ldi	r18,0xFE
	rjmp	L0246

SET_SS_BIT:
	ldi	ZH,0x02
	ldi	ZL,0x0F				; KA15
	ldi	r18,0xFD
	rjmp	L0246

RESET_CS_BIT:
	ldi	ZH,0x02
	ldi	ZL,0x08				; KA08
	ldi	r18,1
	rjmp	L0247

RESET_SS_BIT:
	ldi	ZH,0x02
	ldi	ZL,0x0F				; KA15
	ldi	r18,2
	rjmp	L0247




SET_E_MODE:				; Переключение в режим E
	sbrc	KBD_STATE,0x07	; skip if already set E mode
	ret
	mov r3,XL
	rcall	SET_CS_BIT
	rcall	SET_SS_BIT	
	rcall	FILL_PORT_FE
	rcall LONG_WAIT
	rcall LONG_WAIT
	rcall LONG_WAIT
	rcall LONG_WAIT
	rcall	RESET_CS_BIT
	rcall	RESET_SS_BIT
	rcall	FILL_PORT_FE
	mov XL,r3
	ori KBD_STATE,0x80
	ret

;----------------------------------------------------
USE_ALT_KEYTABLE:
	mov	r18,r0
	andi	r18,0x1F		; clear alternate bits and get alternate key number in table
	lsl	r18					; r18 = r18 * 2
	sbrc	r0,0x05			; check ALT2 table bit
	rjmp	USE_ALT2

	ldi	ZH,high(KEYTABLE_ALT*2)
	ldi	ZL,low(KEYTABLE_ALT*2)
	add	ZL,r18
	brcc	GET_ALT_KEYS
	inc	ZH			; if ZL overflow -> increase ZH
GET_ALT_KEYS:
	sbrs	KBD_STATE,0x05 // проверка CapsSHIFT
	rjmp	NO_CAPSSHIFT
	// выборка второго значения из таблицы KEYTABLE_ALT
	inc	ZL
	lpm				; [Z] -> r0, выборка второго значения (с CapsShift)
	rcall	RESET_CS_BIT
	sbrs	r0,0x07			; check EXT MODE bit
	rjmp	NO_E1
	and	r0,CONST7F
	rcall	SET_E_MODE
NO_E1:
	rjmp	PROCESS_KEYCODE // обработка, если не нажат CapsShift
NO_CAPSSHIFT:	
	// выборка первого значения из таблицы KEYTABLE_ALT
	lpm				; [Z] -> r0, выборка первого значения (без CapsShift)
	sbrs	r0,0x07			; check EXT MODE bit
	rjmp	NO_E2
	and	r0,CONST7F
	rcall	SET_E_MODE
NO_E2:
	rjmp	PROCESS_KEYCODE // обработка

USE_ALT2:
	ldi	ZH,high(KEYTABLE_ALT2*2)
	ldi	ZL,low(KEYTABLE_ALT2*2)
	add	ZL,r18
	brcc	GET_ALT2_KEYS
	inc	ZH			; if ZL overflow -> increase ZH
GET_ALT2_KEYS:
	sbrs	KBD_IND,0x01 // проверка NumLock
	rjmp	NO_NUMLOCK
	// выборка второго значения из таблицы KEYTABLE_ALT2
	inc	ZL
	lpm				; [Z] -> r0, выборка второго значения (с NumLock)
	rjmp	PROCESS_KEYCODE // обработка, если не нажат CapsShift
NO_NUMLOCK:	
	// выборка первого значения из таблицы KEYTABLE_ALT
	lpm				; [Z] -> r0, выборка первого значения (без NumLock)
	rjmp	PROCESS_KEYCODE // обработка

;----------------------------------------------------
// Set keyboard staus indicators
KBD_SEND_INDICATORS:
	ldi	KBD_BYTE,0xED		; keyboard command Set status indicators
	rcall	KBD_SEND		; subroutine send command to keyboard
	mov	KBD_BYTE,KBD_IND	; indicatoes value
/////---------------------------------------------------------------------------------------
///// Запись байта в клавиатуру
/////---------------------------------------------------------------------------------------
KBD_SEND:
	rcall	KBD_SEND_BYTE
	brcs	KBD_SEND_EXIT
	rcall	KBD_READ0
	brcs	KBD_SEND_EXIT
	//brcs	PARITY_ERROR

	cpi	KBD_BYTE,0xFA		; проверка корректности кода ответа клавиатуры выставление флага для дальнейшей обработки где требуется
	clc						//В случае неверного ответа должен быть сброшен флаг нуля и не выставлен флаг переноса (если код ответа будет меньше FA)
KBD_SEND_EXIT:
	ret

//PARITY_ERROR:
//	ret
;-------------------------------------------------------------------------------------------
KBD_SEND_BYTE:

	ldi	KBD_LOOP_CNT,0x08
	clr	PARITY

	sbi	DDRC,0x05		; set CLK pin as output (=0)
	rcall	WAIT_LOOP		; Wait 100ms
	sbi	DDRC,0x04		; 1->DDC.4 DATA (=0)
	rcall	WAIT_LOOP2		; 5ms	
	cbi	DDRC,0x05		; set CLK pin as input (=1)
	rcall	SMALL_WAIT
	// начинается тактирование CLK от клавиатуры

	// цикл отправки 8 бит данных -------------------------------

SEND_LOOP:
	rcall	WAIT_CLK0
	ror		KBD_BYTE 		; KBD_BYTE>> (сдвиг вправо, выдвинутый бит помещается в C)
	brcs	SEND_1			; если C=1

	// Отправка бита = 0
	sbi		DDRC,0x04		; 1->DDRC.4 (в режим записи, на пине 0, т.к. PortC.4 = 0)
	rjmp	SEND_BIT

SEND_1:	// Отправка бита = 1
	cbi		DDRC,0x04		; 0->DDRC.4 (в режим чтения) вроде как отправляется 1
	inc		PARITY			; вычисление бита четности

SEND_BIT:
	rcall	WAIT_CLK1

	dec		KBD_LOOP_CNT
	brne	SEND_LOOP
	// конец цикла отправки ---------------------------------------

	// отправка бита четности
	rcall	WAIT_CLK0
	cbi		DDRC,0x04
	sbrc	PARITY,0x00
	sbi		DDRC,0x04
	rcall	WAIT_CLK1

	// стоповый бит 
	rcall	WAIT_CLK0
	cbi		DDRC,0x04
	rcall	WAIT_CLK1

	// ACK
	rcall	WAIT_CLK0
	rcall	WAIT_CLK1
	ret
/////---------------------------------------------------------------------------------------


//READ FROM KEYBOARD -----------------------------------------------------------------

KBD_READ0:
	rcall	SMALL_WAIT
KBD_READ:
	cbi	DDRC,0x05		; CLK на чтение

//цикл ожидания пока на DATA пине не станет 0 (т.е. начало приема данных от клавиатуры)
DATA_1_LOOP:
	sbic	PinC,0x04
	rjmp	DATA_1_LOOP		; Loop if DATA KBD PIN=1

KBD_READ1:
	rcall	SMALL_WAIT
	// читаем стартовый бит
	rcall	WAIT_CLK0	; после этого CLK=0 и C=0
	rcall	WAIT_CLK1	; после этого CLK=1 и C=0

	//цикл чтения 8 бит данных------------------------------------
	ldi	KBD_LOOP_CNT,0x08				
	clr	PARITY
KBD_DATA_LOOP:
	rcall	WAIT_CLK0

	// read bit to carry flag
	clc				; clear Carry flag
	sbis	PinC,0x04		; if DATA pin = 1 skip jmp
	rjmp	KBD_DATA_BIT
	inc	PARITY			; if bit is set - increase parity
	sec				; set Carry flag

KBD_DATA_BIT:
	ror	KBD_BYTE		; >KBD_BYTE>> (rotate through Carry)

	rcall	WAIT_CLK1	; ждем пока CLK не станет равно 1
	dec	KBD_LOOP_CNT			; KBD_LOOP_CNT--
	brne	KBD_DATA_LOOP
	//конец цикла чтения-------------------------------------------

	// чтение бита четности
	rcall	WAIT_CLK0
	sbic	PinC,0x04		; if DATA pin = 0 skip inc
	inc	PARITY			; расчет бита четности
	rcall	WAIT_CLK1

	// чтение стоп бита
	rcall	WAIT_CLK0
	rcall	WAIT_CLK1

	// проверка бита четности
	sbrs	PARITY,0x00
	rjmp	READ_ERROR		; ошибка если бит не установлен
	clc					; 0 -> C
	sbi	DDRC,0x05		; CLK to output (ACK)
	ret

READ_ERROR:
	clr	KBD_BYTE		; ^KBD_BYTE
	sec					; 1->C
	sbi	DDRC,0x05		; CLK to output (ACK)
	ret

/*
;Test Start
;------------------
;Тестовое включение светодиодов

TEST_LED_OFF:
	cbi DDRB, 3
	cbi DDRB, 4
	cbi DDRB, 5
	cbi DDRB, 7
	ret

TEST_LED_B:
	cbi DDRB, 3
	sbi DDRB, 4
	cbi DDRB, 5
	cbi DDRB, 7
	ret

TEST_LED_R:
	cbi DDRB, 3
	cbi DDRB, 4
	cbi DDRB, 5
	sbi DDRB, 7
	ret

TEST_LED_BR:
	cbi DDRB, 3
	sbi DDRB, 4
	cbi DDRB, 5
	sbi DDRB, 7
	ret

TEST_LED_G:
	cbi DDRB, 3
	cbi DDRB, 4
	sbi DDRB, 5
	cbi DDRB, 7
	ret

TEST_LED_BG:
	cbi DDRB, 3
	sbi DDRB, 4
	sbi DDRB, 5
	cbi DDRB, 7
	ret

TEST_LED_RG:
	cbi DDRB, 3
	cbi DDRB, 4
	sbi DDRB, 5
	sbi DDRB, 7
	ret

TEST_LED_BRG:
	cbi DDRB, 3
	sbi DDRB, 4
	sbi DDRB, 5
	sbi DDRB, 7
	ret

TEST_LED_Y:
	sbi DDRB, 3
	cbi DDRB, 4
	cbi DDRB, 5
	cbi DDRB, 7
	ret

TEST_LED_BY:
	sbi DDRB, 3
	sbi DDRB, 4
	cbi DDRB, 5
	cbi DDRB, 7
	ret

TEST_LED_RY:
	sbi DDRB, 3
	cbi DDRB, 4
	cbi DDRB, 5
	sbi DDRB, 7
	ret

TEST_LED_BRY:
	sbi DDRB, 3
	sbi DDRB, 4
	cbi DDRB, 5
	sbi DDRB, 7
	ret

TEST_LED_GY:
	sbi DDRB, 3
	cbi DDRB, 4
	sbi DDRB, 5
	cbi DDRB, 7
	ret

TEST_LED_BGY:
	sbi DDRB, 3
	sbi DDRB, 4
	sbi DDRB, 5
	cbi DDRB, 7
	ret

TEST_LED_RGY:
	sbi DDRB, 3
	cbi DDRB, 4
	sbi DDRB, 5
	sbi DDRB, 7
	ret

TEST_LED_BRGY:
	sbi DDRB, 3
	sbi DDRB, 4
	sbi DDRB, 5
	sbi DDRB, 7
	ret

;------------------
;Test End
*/

;----------------------------------------------------------------------------------------
; Подпрограммы ожидания смены уровня CLK
;
; Проверка переполнения таймера и CLK: цикл пока таймер не переполнится или CLK не станет равно 1
; Если таймер переполнился, значит таймаут и бит не принят


WAIT_CLK1:
	push	r18
	sts		TCNT1H, CONST00
	sts		TCNT1L, CONST00
	ldi		r18, 0x04		//Значение одинаковое для ATmega48 и для ATmega8, тратить такты на SET_BIT нельзя
	sts		TCCR1B, r18		//предделитель счётчика прерываний = 256, с этого момента начинается счёт
	pop		r18
WAIT_CLK1_LOOP:
	sbis	PinC, 5
	rjmp	WAIT_CLK1_LOOP
	sts		TCCR1B, CONST00
	clc
	ret

/*
WAIT_CLK1:
	push	r16
	push	r18
	ser		r16
	ser		r18
WAIT_CLK1_LOOP1:
	sbis	PinC,5				; CLK=1 пропускаем jmp
	rjmp	WAIT_CLK1_LOOP
	clc
WAIT_CLK1_EXIT:
	pop		r18
	pop		r16
	ret
WAIT_CLK1_LOOP:
	subi	r18, 1
	brcc	WAIT_CLK1_LOOP1
	subi	r16, 1
	brcc	WAIT_CLK1_LOOP1
	rjmp	WAIT_CLK1_EXIT
*/

WAIT_CLK0:
	push	r18
	sts		TCNT1H, CONST00
	sts		TCNT1L, CONST00
	ldi		r18, 0x04		//Значение одинаковое для ATmega48 и для ATmega8, тратить такты на SET_BIT нельзя
	sts		TCCR1B, r18		//предделитель счётчика прерываний = 256, с этого момента начинается счёт
	pop		r18
WAIT_CLK0_LOOP:
	sbic	PinC, 5
	rjmp	WAIT_CLK0_LOOP
	sts		TCCR1B, CONST00
	clc
	ret

/*
; Проверка переполнения таймера и CLK: цикл пока таймер не переполнится или CLK не станет равно 0
WAIT_CLK0:
	push	r16
	push	r18
	ser		r16
	ser		r18
WAIT_CLK0_LOOP1:
	sbic	PinC,5				; CLK=0 пропускаем jmp
	rjmp	WAIT_CLK0_LOOP
	clc
WAIT_CLK0_EXIT:
	pop		r18
	pop		r16
	ret
WAIT_CLK0_LOOP:
	subi	r18, 1
	brcc	WAIT_CLK0_LOOP1
	subi	r16, 1
	brcc	WAIT_CLK0_LOOP1
	rjmp	WAIT_CLK0_EXIT
*/

;----------------------------------------------------------------------------------------
; in value - bit number in r16, out value in r18
SET_BIT:
	ldi r18,0x01
SET_BIT_LOOP:
	tst r16
	breq SET_BIT_END
	lsl r18
	dec r16
	rjmp SET_BIT_LOOP
SET_BIT_END:
	ret

; Подпрограммы таймингов

// задержка 50 циклов LONG_WAIT
LONG_WAIT_50:
	ldi	KBD_LOOP_CNT,0x32
	rjmp	L02FD

// задержка 15 циклов LONG_WAIT
LONG_WAIT_15:
	ldi	KBD_LOOP_CNT,0x0F
L02FD:
	rcall	LONG_WAIT
	dec	KBD_LOOP_CNT
	brne	L02FD
	ret

// задержка 100 циклов WAIT_LOOP
LONG_WAIT:
	ldi	r18,0x64
	mov	r1,r18
L0308:
	rcall	WAIT_LOOP
	dec	r1
	brne	L0308
	ret

// Цикл ожидания CLK Low при записи
WAIT_LOOP:
	ldi	r18,TIMING_COEFF*10
L0310:
	nop
	nop
	nop
	nop
	nop
	dec	r18
	brne	L0310
	ret
// Цикл ожидания Data Low при записи
WAIT_LOOP2:
	ldi	r18,TIMING_COEFF
L0311:
	nop
	dec	r18
	brne	L0311
	ret

// короткая задержка
SMALL_WAIT:
	nop
	nop
	nop
	nop
	nop
	nop
	ret


;----------------------------------------------------------------------------------------------------------
; Таблицы раскладки клавиатуры для работы в режиме Scan Code 2 
;----------------------------------------------------------------------------------------------------------
; Основная таблица состоит из двух половин, первая соответствует клавишам, которые при нажатии выдают
; однобайтный скан-код, вторая половина клавишам, которые при нажатии выдают дополнительно префикс 0xE0.
; В этой таблице каждому скан-коду IBM-клавиатуры соответствует один байт, который содержит информацию
; о номере колонки и номере строки, в которой будет имитироватся замыкание контакта клавиатуры Спектрума.
; Дополнительно каждому коду можно добавить признак нажатия функциональной клавиши:
;   - d6 сигнализирует о дополнительном нажатии Symbol Shift;
;   - d7 о нажатии Caps Shift.
; Для клавиш IBM клавиатуры, которые в зависимости от нажатия Shift имеют разные коды, предусмотрено перек-
; лючение таблицы на дополнительную, признаком этого является d7 и d6=1.
; Пропущенные скан-коды можно забить любым кодом. Незадействованные скан-коды заполняются кодом 0.
; Поскольку таблица жестко связана со скан-кодами, нельзя ни пропускать, ни добавлять в нее строки.
; Дополнительную таблицу можно расширять в сторону увеличения практически до 63 строк. Но начало
; этой таблицы тоже жестко определено.
;----------------------------------------------------------------------------------------------------------

; биты данных сканирования (d2..d0) [номер строки +1]
.equ D0=0x01
.equ D1=0x02
.equ D2=0x03
.equ D3=0x04
.equ D4=0x05

; биты адреса сканирования (d5..d3) [номер колонки *8]
.equ A08=0x00
.equ A09=0x08
.equ A10=0x10
.equ A11=0x18
.equ A12=0x20
.equ A13=0x28
.equ A14=0x30
.equ A15=0x38

; скан-коды основных клавиш ZX --------------------------
.equ KEY_1=A11+D0
.equ KEY_2=A11+D1
.equ KEY_3=A11+D2
.equ KEY_4=A11+D3
.equ KEY_5=A11+D4
;
.equ KEY_6=A12+D4
.equ KEY_7=A12+D3
.equ KEY_8=A12+D2
.equ KEY_9=A12+D1
.equ KEY_0=A12+D0
;
.equ KEY_Q=A10+D0
.equ KEY_W=A10+D1
.equ KEY_E=A10+D2
.equ KEY_R=A10+D3
.equ KEY_T=A10+D4
;
.equ KEY_Y=A13+D4
.equ KEY_U=A13+D3
.equ KEY_I=A13+D2
.equ KEY_O=A13+D1
.equ KEY_P=A13+D0
;
.equ KEY_A=A09+D0
.equ KEY_S=A09+D1
.equ KEY_D=A09+D2
.equ KEY_F=A09+D3
.equ KEY_G=A09+D4
;
.equ KEY_H	= A14+D4
.equ KEY_J	= A14+D3
.equ KEY_K	= A14+D2
.equ KEY_L	= A14+D1
.equ KEY_EN	= A14+D0	; Enter
;
.equ KEY_CS	= A08+D0	; Caps Shift
.equ KEY_Z	= A08+D1
.equ KEY_X	= A08+D2
.equ KEY_C	= A08+D3
.equ KEY_V	= A08+D4
;
.equ KEY_B	= A15+D4
.equ KEY_N	= A15+D3
.equ KEY_M	= A15+D2
.equ KEY_SS	= A15+D1	; Symbol Shift
.equ KEY_SP	= A15+D0	; Space

; Префиксные биты (d7..d6)
.equ SS=0x40	;флаг Symbol Shift
.equ CS=0x80	;флаг Caps Shift
.equ EM=0x80	;флаг Ext Mode для ALT1
.equ ALT1=0xC0	;флаг доп.таблицы 1
.equ ALT2=0xE0	;флаг доп.таблицы 2


; Сканкоды клавиш, по две из-за выравнивания до границы слова
;-----------------------------------------------------------------------------
; ИНФОРМАЦИЯ В ОПИСАНИИ:
;  N/A - означает, что для данного кода не задана клавиша на клавиатуре PS/2 (так что данный код менять не стоит)
;  ------- - означает, что для данного кода не генерируется значение на ZX клавиатуре
;  * - означает, что данная клавиша обрабатывается в коде и её значение в таблице не влияет на обработку
;  kp - означает, что клавиша находится на цифровой части клавиатуры
;
; Информация в поле данных:
;  Значение 0x00 означает, что клавиша игнорируется за исколючение программно обрабатываемых (Shift, Ctrl, Reset и т.д.)
;
; Клавиша F7 с кодом 0x83 в таблице имеет значение 0x08
;
; Информация по комбинациям клавиш
; 1) http://slady.net/Sinclair-ZX-Spectrum-keyboard/
; 2) http://zxpress.ru/book_articles.php?id=1429
;
; Информация по сканкодам
; 1) http://wiki.osdev.org/PS/2_Keyboard#Key_Codes.2C_Key_States_and_Key_Mappings
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Scan Code 2 без префикса 0E0h
;-----------------------------------------------------------------------------
;		
KEYTABLE:                      ; KeyCode        PC   ZX             KeyCode        PC   ZX

.db 0x00,       SS+KEY_D       ; 0x00 -        N/A - -------      ; 0x01 -      [ F9] - STEP
.db 0x00,       SS+KEY_U       ; 0x02 -        N/A - -------      ; 0x03 -      [ F5] - OR
.db SS+KEY_E,   SS+KEY_Q       ; 0x04 -      [ F3] - >=           ; 0x05 -      [ F1] - ASN
.db SS+KEY_W,   0x00           ; 0x06 -      [ F2] - <>           ;*0x07 -      [F12] - [ExtBtn2]
.db SS+KEY_A,   SS+KEY_F       ; 0x08 -      [ F7] - STOP         ; 0x09 -      [F10] - TO
.db SS+KEY_S,   SS+KEY_I       ; 0x0A -      [ F8] - NOT          ; 0x0B -      [ F6] - IN
.db SS+KEY_Y,   CS+KEY_1       ; 0x0C -      [ F4] - AND          ; 0x0D -      [Tab] - [Edit]
.db ALT1+0,     0x00           ; 0x0E -        [`] - {ALT-0}      ; 0x0F -        N/A - -------
.db 0x00,       CS+KEY_3       ; 0x10 -        N/A - -------      ; 0x11 -    [L.Alt] - [TRUE VID] 
.db 0x00,       0x00           ;*0x12 -  [L.Shift] - [CapsShift]  ; 0x13 -        N/A - -------
.db 0x00,       KEY_Q          ;*0x14 -   [L.Ctrl] - [SymbShift]  ; 0x15 -        [Q] - [Q]
.db ALT1+16,    0x00           ; 0x16 -        [1] - {ALT-16}     ; 0x17 -        N/A - -------
.db 0x00,       0x00           ; 0x18 -        N/A - -------      ; 0x19 -        N/A - -------
.db KEY_Z,      KEY_S          ; 0x1A -        [Z] - [Z]          ; 0x1B -        [S] - [S]
.db KEY_A,      KEY_W          ; 0x1C -        [A] - [A]          ; 0x1D -        [W] - [W]
.db ALT1+17,    0x00           ; 0x1E -        [2] - {ALT-17}     ; 0x1F -        N/A - -------
.db 0x00,       KEY_C          ; 0x20 -        N/A - -------      ; 0x21 -        [C] - [C]
.db KEY_X,      KEY_D          ; 0x22 -        [X] - [X]          ; 0x23 -        [D] - [D]
.db KEY_E,      ALT1+19        ; 0x24 -        [E] - [E]          ; 0x25 -        [4] - {ALT-19}
.db ALT1+18,    0x00           ; 0x26 -        [3] - {ALT-18}     ; 0x27 -        N/A - -------
.db 0x00,       ALT2+4         ; 0x28 -        N/A - -------      ; 0x29 -    [SPACE] - {ALT2-4}
.db KEY_V,      KEY_F          ; 0x2A -        [V] - [V]          ; 0x2B -        [F] - [F]
.db KEY_T,      KEY_R          ; 0x2C -        [T] - [T]          ; 0x2D -        [R] - [R]
.db ALT1+20,    0x00           ; 0x2E -        [5] - {ALT-20}     ; 0x2F -        N/A - -------
.db 0x00,       KEY_N          ; 0x30 -        N/A - -------      ; 0x31 -        [N] - [N]
.db KEY_B,      KEY_H          ; 0x32 -        [B] - [B]          ; 0x33 -        [H] - [H]
.db KEY_G,      KEY_Y          ; 0x34 -        [G] - [G]          ; 0x35 -        [Y] - [Y]
.db ALT1+11,    0x00           ; 0x36 -        [6] - {ALT-11}     ; 0x37 -        N/A - -------
.db 0x00,       0x00           ; 0x38 -        N/A - -------      ; 0x39 -        N/A - -------
.db KEY_M,      KEY_J          ; 0x3A -        [M] - [M]          ; 0x3B -        [J] - [J]
.db KEY_U,      ALT1+12        ; 0x3C -        [U] - [U]          ; 0x3D -        [7] - {ALT-12}
.db ALT1+13,    0x00           ; 0x3E -        [8] - {ALT-13}     ; 0x3F -        N/A - -------
.db 0x00,       ALT1+1         ; 0x40 -        N/A - -------      ; 0x41 -        [,] - {ALT-1}
.db KEY_K,      KEY_I          ; 0x42 -        [K] - [K]          ; 0x43 -        [I] - [I]
.db KEY_O,      ALT1+15        ; 0x44 -        [O] - [O]          ; 0x45 -        [0] - {ALT-15}
.db ALT1+14,    SS+KEY_D       ; 0x46 -        [9] - {ALT-14}     ; 0x47 -        N/A - -------
.db 0x00,       ALT1+2         ; 0x48 -        N/A - -------      ; 0x49 -        [.] - {ALT-2}
.db ALT1+3,     KEY_L          ; 0x4A -        [/] - {ALT-3}      ; 0x4B -        [L] - [L]
.db ALT1+4,     KEY_P          ; 0x4C -        [;] - {ALT-4}      ; 0x4D -        [P] - [P]
.db ALT1+5,     0x00           ; 0x4E -        [-] - {ALT-5}      ; 0x4F -        N/A - -------
.db 0x00,       0x00           ; 0x50 -        N/A - -------      ; 0x51 -        N/A - -------
.db ALT1+6,     0x00           ; 0x52 -        ['] - {ALT-6}      ; 0x53 -        N/A - -------
.db ALT1+7,     ALT1+8         ; 0x54 -        [[] - {ALT-7}      ; 0x55 -        [=] - {ALT-8}
.db 0x00,       0x00           ; 0x56 -        N/A - -------      ; 0x57 -        N/A - -------
.db CS+KEY_2,   0x00           ; 0x58 - [CapsLock] - [CapsLock]   ;*0x59 -  [R.Shift] - [CapsShift]
.db KEY_EN,     ALT1+9         ; 0x5A -    [ENTER] - [ENTER]      ; 0x5B -        []] - {ALT-9}
.db 0x00,       ALT1+10        ; 0x5C -        N/A - -------      ; 0x5D -        [\] - {ALT-10}
.db 0x00,       0x00           ; 0x5E -        N/A - -------      ; 0x5F -        N/A - -------
.db 0x00,       0x00           ; 0x60 -        N/A - -------      ; 0x61 -        N/A - -------
.db 0x00,       0x00           ; 0x62 -        N/A - -------      ; 0x63 -        N/A - -------
.db 0x00,       0x00           ; 0x64 -        N/A - -------      ; 0x65 -        N/A - -------
.db CS+KEY_0,   0x00           ; 0x66 -  [BackSpc] - [DELETE]     ; 0x67 -        N/A - -------
.db 0x00,       KEY_1          ; 0x68 -        N/A - -------      ; 0x69 -     kp [1] - [1]
.db 0x00,       KEY_4          ; 0x6A -        N/A - -------      ; 0x6B -     kp [4] - [4]
.db KEY_7,      0x00           ; 0x6C -     kp [7] - [7]          ; 0x6D -        N/A - -------
.db 0x00,       0x00           ; 0x6E -        N/A - -------      ; 0x6F -        N/A - -------
.db KEY_0,      SS+KEY_M       ; 0x70 -     kp [0] - [0]          ; 0x71 -     kp [.] - [.]
.db KEY_2,      KEY_5          ; 0x72 -     kp [2] - [2]          ; 0x73 -     kp [5] - [5]
.db KEY_6,      KEY_8          ; 0x74 -     kp [6] - [6]          ; 0x75 -     kp [8] - [8]
.db SS+KEY_CS,  0x00           ; 0x76 -      [ESC] - [Ext Mode]   ;*0x77 -  [NumLock] -
.db 0x00,       SS+KEY_K       ;*0x78 -      [F11] - [ExtBtn1]    ; 0x79 -     kp [+] - [+]
.db KEY_3,      SS+KEY_J       ; 0x7A -     kp [3] - [3]          ; 0x7B -     kp [-] - [-]
.db SS+KEY_B,   KEY_9          ; 0x7C -     kp [*] - [*]          ; 0x7D -     kp [9] - [9]
.db 0x00,       0x00           ;*0x7E -  [ScrLock] -              ; 0x7F -        N/A - -------

;-----------------------------------------------------------------------------
; Scan Code 2 с префиксом 0E0h
;-----------------------------------------------------------------------------
;
KEYTABLE_E0:                   ; KeyCode        PC   ZX             KeyCode        PC   ZX

.db 0x00,       0x00           ; 0x00 -        N/A - -------      ; 0x01 -        N/A - -------
.db 0x00,       0x00           ; 0x02 -        N/A - -------      ; 0x03 -        N/A - -------
.db 0x00,       0x00           ; 0x04 -        N/A - -------      ; 0x05 -        N/A - -------
.db 0x00,       0x00           ; 0x06 -        N/A - -------      ; 0x07 -        N/A - -------
.db 0x00,       0x00           ; 0x08 -        N/A - -------      ; 0x09 -        N/A - -------
.db 0x00,       0x00           ; 0x0A -        N/A - -------      ; 0x0B -        N/A - -------
.db 0x00,       0x00           ; 0x0C -        N/A - -------      ; 0x0D -        N/A - -------
.db 0x00,       0x00           ; 0x0E -        N/A - -------      ; 0x0F -        N/A - -------
.db 0x00,       CS+KEY_4       ; 0x10 - [WWW Srch] - -------      ; 0x11 -    [R Alt] - [INV VID]
.db 0x00,       0x00           ;*0x12 -  [PrtScn1] - [RESET]      ; 0x13 -        N/A - -------
.db 0x00,       0x00           ;*0x14 -   [R Ctrl] - [SymbShift]  ; 0x15 -  [MM Prev] - -------
.db 0x00,       0x00           ; 0x16 -        N/A - -------      ; 0x17 -        N/A - -------
.db 0x00,       0x00           ; 0x18 -  [WWW fwd] - -------      ; 0x19 -        N/A - -------
.db 0x00,       0x00           ; 0x1A -        N/A - -------      ; 0x1B -        N/A - -------
.db 0x00,       0x00           ; 0x1C -        N/A - -------      ; 0x1D -        N/A - -------
.db 0x00,       SS+KEY_EN      ; 0x1E -        N/A - -------      ; 0x1F -  [LeftWIN] - [ENTER]
.db 0x00,       0x00           ; 0x20 - [WWW refr] - -------      ; 0x21 -     [Vol-] - -------
.db 0x00,       0x00           ; 0x22 -        N/A - -------      ; 0x23 -     [Mute] - -------
.db 0x00,       0x00           ; 0x24 -        N/A - -------      ; 0x25 -        N/A - -------
.db 0x00,       ALT1+21        ; 0x26 -        N/A - -------      ; 0x27 - [RightWIN] - {ALT1-21}
.db 0x00,       0x00           ; 0x28 - [WWW stop] - -------      ; 0x29 -        N/A - -------
.db 0x00,       0x00           ; 0x2A -        N/A - -------      ; 0x2B - [Calculat] - -------
.db 0x00,       0x00           ; 0x2C -        N/A - -------      ; 0x2D -        N/A - -------
.db 0x00,       0x00           ; 0x2E -        N/A - -------      ; 0x2F -     [APPS] - -------
.db 0x00,       0x00           ; 0x30 -  [WWW fwd] - -------      ; 0x31 -        N/A - -------
.db 0x00,       0x00           ; 0x32 -     [vol+] - -------      ; 0x33 -        N/A - -------
.db 0x00,       0x00           ; 0x34 - [pl/pause] - -------      ; 0x35 -        N/A - -------
.db 0x00,       0x00           ; 0x36 -        N/A - -------      ; 0x37 -    [Power] - -------
.db 0x00,       0x00           ; 0x38 - [WWW back] - -------      ; 0x39 -        N/A - -------
.db 0x00,       0x00           ; 0x3A - [WWW home] - -------      ; 0x3B -  [MM stop] - -------
.db 0x00,       0x00           ; 0x3C -        N/A - -------      ; 0x3D -        N/A - -------
.db 0x00,       0x00           ; 0x3E -        N/A - -------      ; 0x3F -    [Sleep] - -------
.db 0x00,       0x00           ; 0x40 -   [MyComp] - -------      ; 0x41 -        N/A - -------
.db 0x00,       0x00           ; 0x42 -        N/A - -------      ; 0x43 -        N/A - -------
.db 0x00,       0x00           ; 0x44 -        N/A - -------      ; 0x45 -        N/A - -------
.db 0x00,       0x00           ; 0x46 -        N/A - -------      ; 0x47 -        N/A - -------
.db 0x00,       0x00           ; 0x48 -    [EMail] - -------      ; 0x49 -        N/A - -------
.db SS+KEY_V,   0x00           ; 0x4A -     kp [/] - [/]          ; 0x4B -        N/A - -------
.db 0x00,       0x00           ; 0x4C -        N/A - -------      ; 0x4D -  [MM Next] - -------
.db 0x00,       0x00           ; 0x4E -        N/A - -------      ; 0x4F -        N/A - -------
.db 0x00,       0x00           ; 0x50 - [MMselect] - -------      ; 0x51 -        N/A - -------
.db 0x00,       0x00           ; 0x52 -        N/A - -------      ; 0x53 -        N/A - -------
.db 0x00,       0x00           ; 0x54 -        N/A - -------      ; 0x55 -        N/A - -------
.db 0x00,       0x00           ; 0x56 -        N/A - -------      ; 0x57 -        N/A - -------
.db 0x00,       0x00           ; 0x58 -        N/A - -------      ; 0x59 -        N/A - -------
.db KEY_EN,     0x00           ; 0x5A - kp [ENTER] - [ENTER]      ; 0x5B -        N/A - -------
.db 0x00,       0x00           ; 0x5C -        N/A - -------      ; 0x5D -        N/A - -------
.db 0x00,       0x00           ; 0x5E -  [Wake Up] -              ; 0x5F -        N/A - -------
.db 0x00,       0x00           ; 0x60 -        N/A - -------      ; 0x61 -        N/A - -------
.db 0x00,       0x00           ; 0x62 -        N/A - -------      ; 0x63 -        N/A - -------
.db 0x00,       0x00           ; 0x64 -        N/A - -------      ; 0x65 -        N/A - -------
.db 0x00,       0x00           ; 0x66 -        N/A - -------      ; 0x67 -        N/A - -------
.db 0x00,       SS+KEY_E       ; 0x68 -        N/A - -------      ; 0x69 -      [End] - >=
.db 0x00,       ALT2+2         ; 0x6A -        N/A - -------      ; 0x6B -     [Left] - {ALT2-2}
.db SS+KEY_Q,   0x00           ; 0x6C -     [Home] - <=           ; 0x6D -        N/A - -------
.db 0x00,       0x00           ; 0x6E -        N/A - -------      ; 0x6F -        N/A - -------
.db SS+KEY_W,   CS+KEY_9       ; 0x70 -   [Insert] - <>           ; 0x71 -      [Del] - [GRAPH]
.db ALT2+1,     0x00           ; 0x72 -     [Down] - {ALT2-1}     ; 0x73 -        N/A - -------
.db ALT2+3,     ALT2+0         ; 0x74 -    [Right] - {ALT2-3}     ; 0x75 -       [Up] - {ALT2-0}
.db 0x00,       0x00           ; 0x76 -        N/A - -------      ; 0x77 -        N/A - -------
.db 0x00,       0x00           ; 0x78 -        N/A - -------      ; 0x79 -        N/A - -------
.db CS+KEY_4,   0x00           ; 0x7A -  [Pg Down] - [INV VID]    ; 0x7B -        N/A - -------
.db 0x00,       CS+KEY_3       ;*0x7C -  [PrtScn2] - -------      ; 0x7D -    [Pg Up] - [TRUE VID]
.db 0x00,       0x00           ; 0x7E -        N/A - -------      ; 0x7F -        N/A - -------

;----------------------------------------------------------------
; Таблица клавиш с двумя кодами, до 32 строк!
; Only SS flag! Dont use CS flag, use EM for E mode before key
;----------------------------------------------------------------
; 1код - без CapsShift
; 2код -  с  CapsShift
;
KEYTABLE_ALT:                     ; Keycode KEYS          Value in table
                               
.db SS+KEY_X,      EM+SS+KEY_A    ; 0x0E    [`] / [~]     {ALT-0} для второго значения требуется переход в режим E
.db SS+KEY_N,      SS+KEY_R       ; 0x41    [,] / [<]     {ALT-1}
.db SS+KEY_M,      SS+KEY_T       ; 0x49    [.] / [>]     {ALT-2}
.db SS+KEY_V,      SS+KEY_C       ; 0x4A    [/] / [?]     {ALT-3}
.db SS+KEY_O,      SS+KEY_Z       ; 0x4C    [;] / [:]     {ALT-4}
.db SS+KEY_J,      SS+KEY_0       ; 0x4E    [-] / [_]     {ALT-5}
.db SS+KEY_7,      SS+KEY_P       ; 0x52    ['] / ["]     {ALT-6}
.db EM+SS+KEY_Y,   EM+SS+KEY_F    ; 0x54    [[] / [{]     {ALT-7} требуется переход в режим E
.db SS+KEY_L,      SS+KEY_K       ; 0x55    [=] / [+]     {ALT-8}
.db EM+SS+KEY_U,   EM+SS+KEY_G    ; 0x5B    []] / [}]     {ALT-9} требуется переход в режим E
.db SS+KEY_D,      SS+KEY_S       ; 0x5C    [\] / [|]     {ALT-10}
.db KEY_6,         SS+KEY_H       ; 0x3E    [6] / [^]     {ALT-11}
.db KEY_7,         SS+KEY_6       ; 0x46    [7] / [']     {ALT-12}
.db KEY_8,         SS+KEY_B       ; 0x3E    [8] / [*]     {ALT-13}
.db KEY_9,         SS+KEY_8       ; 0x46    [9] / [(]     {ALT-14}
.db KEY_0,         SS+KEY_9       ; 0x45    [0] / [)]     {ALT-15}
.db KEY_1,         SS+KEY_1       ; 0x16    [1] / [!]     {ALT-16}
.db KEY_2,         SS+KEY_2       ; 0x1E    [2] / [@]     {ALT-17}
.db KEY_3,         SS+KEY_3       ; 0x26    [3] / [#]     {ALT-18}
.db KEY_4,         SS+KEY_4       ; 0x25    [4] / [$]     {ALT-19}
.db KEY_5,         SS+KEY_5       ; 0x2E    [5] / [%]     {ALT-20}
.db EM+SS+KEY_P,   EM+SS+KEY_P    ; 0xA7 [Copy] / [Copy]  {ALT-21}
;----------------------------------------------------------------------------------

;----------------------------------------------------------------
; Таблица клавиш с двумя кодами при нажатом NUMLOCK, до 32 строк!
;----------------------------------------------------------------
; 1код - без NumLock
; 2код -  с  NumLock
;
KEYTABLE_ALT2:                    ; Keycode              KEYS          Value in table
                               
.db KEY_9,         CS+KEY_7       ; 0x75      [Sinclair Up] / [Up]     {ALT2-0}
.db KEY_8,         CS+KEY_6       ; 0x72    [Sinclair Down] / [Down]   {ALT2-1}
.db KEY_6,         CS+KEY_5       ; 0x6B    [Sinclair Left] / [Left]   {ALT2-2}
.db KEY_7,         CS+KEY_8       ; 0x74   [Sinclair Right] / [Right]  {ALT2-3}
.db KEY_0,         KEY_SP         ; 0x75    [Sinclair Fire] / [Space]  {ALT2-4}
;----------------------------------------------------------------------------------


;--------- так, чисто прикол )))
.db 0x0D,0x0A,"KBD_EMU V5.6",0x0D,0x0A
.db "http://avray.ru ",0x0D,0x0A
.db "Fixed by Northwood",0x0D,0x0A,0x00,0x00
