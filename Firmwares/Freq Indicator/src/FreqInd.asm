.include "tn2313def.inc"

.EQU F3_0	=0b01101011;	5
.EQU F3_1	=0b11101101;	3.
.EQU F3_2	=0b00000000

.EQU F7_0	=0b01110111;	0
.EQU F7_1	=0b10100101;	7.
.EQU F7_2	=0b00000000

.EQU F14_0	=0b01110111;	0
.EQU F14_1	=0b10101110;	4.
.EQU F14_2	=0b00100100;	1

.EQU LED_Turbo		=0b00001000;
.EQU LED_Power		=0b00010000;
.EQU Button_7MHz	=0b00100000;
.EQU Button_14MHz	=0b01000000;

.CSEG
.ORG 0x0000
RJMP Start

.ORG 0x0006
Int_Timer0_OVF:
RJMP Interrupt

.ORG 0x0015
Start:
LDI R16,RAMEND
OUT SPL,R16
LDI R16,(1<<TOIE0);	Прерывание по переполнению таймера 0
OUT TIMSK,R16
LDI R16,(1<<CS01);	Коэффициент деления тактовой частоты для таймера = 8
OUT TCCR0B,R16
LDI R16,(1<<SE);	Sleep enable, idle mode
OUT MCUCR,R16
LDI R16,0b11111111
OUT DDRB,R16
LDI R16,0b00011111
OUT DDRD,R16
CLR R17
CLR R23
SEI

Main:
SLEEP
RJMP Main

Interrupt:;		R17 = номер разряда

SBIC PINA,0
RCALL PwrFlash
SBIS PINA,0
LDI R22,LED_Power

IN R18,PIND
ANDI R18,(Button_7MHz|Button_14MHz)
BREQ LedTurboOff
LDI R21,LED_Turbo
RJMP Itr0
LedTurboOff:
CLR R21
Itr0:
OR R21,R22
LSR R18
LSR R18
LSR R18
ADD R18,R17


LDI ZH,HIGH(DigitTable*2)
LDI ZL,LOW(DigitTable*2)
ADD ZL,R18
BRCC NoIncZH
INC ZH
NoIncZH:

LDI R18,1;			По умолчанию выбираем младший разряд
MOV R19,R17

LDigitNum:
DEC R19
BRMI OutDigitNum
LSL R18
RJMP LDigitNum

OutDigitNum:
LPM R20,Z

OR R19,R21
OR R18,R21

OUT PORTD,R19;		Гасим индикатор
OUT PORTB,R20;		Включаем выбранную цифру в разряде
OUT PORTD,R18;		Зажигаем выбранный разряд

INC R17
CPI R17,3
BRNE IntRet
CLR R17

IntRet:
RETI

PwrFlash:
INC R23
CPI R23,82
BRNE RetFlash
LDI R23,LED_Power
EOR R22,R23
CLR R23

RetFlash:
RET

DigitTable:
.DB F3_0, F3_1, F3_2, 0
.DB F7_0, F7_1, F7_2, 0
.DB F14_0, F14_1, F14_2, 0
.DB F14_0, F14_1, F14_2, 0
