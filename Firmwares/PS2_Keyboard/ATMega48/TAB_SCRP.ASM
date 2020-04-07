	ORG	980h
;===================================
; биты данных сканирования (d2..d0) [номер строки +1]
D0	EQU	001H
D1	EQU	002H
D2	EQU	003H
D3	EQU	004H
D4	EQU	005H
; биты адреса сканирования (d5..d3) [номер колонки *8]
A08	EQU	000H
A09	EQU	008H
A10	EQU	010H
A11	EQU	018H
A12	EQU	020H
A13	EQU	028H
A14	EQU	030H
A15	EQU	038H
; Префиксные биты (d7..d6)
CS	EQU	080H	;флаг Caps Shift
SS	EQU	040H	;флаг Symbol Shift
; скан-коды основных клавиш
; A11
K1	EQU	A11+D0
K2	EQU	A11+D1
K3	EQU	A11+D2
K4	EQU	A11+D3
K5	EQU	A11+D4
; A12
K6	EQU	A12+D4
K7	EQU	A12+D3
K8	EQU	A12+D2
K9	EQU	A12+D1
K0	EQU	A12+D0
; A10
KQ	EQU	A10+D0
KW	EQU	A10+D1
KE	EQU	A10+D2
KR	EQU	A10+D3
KT	EQU	A10+D4
; A13
KY	EQU	A13+D4
KU	EQU	A13+D3
KI	EQU	A13+D2
KO	EQU	A13+D1
KP	EQU	A13+D0
; A09
KA	EQU	A09+D0
KS	EQU	A09+D1
KD	EQU	A09+D2
KF	EQU	A09+D3
KG	EQU	A09+D4
; A14
KH	EQU	A14+D4
KJ	EQU	A14+D3
KK	EQU	A14+D2
KL	EQU	A14+D1
KCR	EQU	A14+D0  ;Enter
; A08
KCS	EQU	A08+D0  ;Caps Shift
KZ	EQU	A08+D1
KX	EQU	A08+D2
KC	EQU	A08+D3
KV	EQU	A08+D4
; A15
KB	EQU	A15+D4
KN	EQU	A15+D3
KM	EQU	A15+D2
KSS	EQU	A15+D1  ;Symbol Shift
KSP	EQU	A15+D0	;Пробел
;-----------------------------------
; Расширенные Скан-коды клавиш Спектрума
ZPT	EQU	SS+KN	;Запятая
TCK	EQU	SS+KM	;Точка
TZP	EQU	SS+KO	;Точка с запятой
DVT	EQU	SS+KZ	;Двоеточие
PLS	EQU	SS+KK	;Плюс
MNS	EQU	SS+KJ	;минус
EQV	EQU	SS+KL	;Равно
UMN	EQU	SS+KB	;Умножить
DEL	EQU	SS+KV	;Делить
KAV	EQU	SS+KP	;Кавычка "
EXT	EQU	SS+KCS	;EXTEND KEY
OSK	EQU	SS+K8	;Открывающая скобка (
ZSK	EQU	SS+K9	;Закрывающая скобка )
;--------------------------------------------
; Скриптовые команды
SNOP	EQU	0	;Нет команды - пауза 0.1 сек
S_RES	EQU	0C0h	;выдать RESET
S_NMI	EQU	0C1h	;выдать NMI
PAUSE	EQU	0C2h	;выдержать ПАУЗУ,N*10 мсек
CL_LED	EQU	0C3h	;сбросить индикаторы KBD
INV_CL	EQU	0C4h	;инвертировать CapsLock
INV_NL	EQU	0C5h	;инвертировать NumLock
INV_SL	EQU	0C6h	;инвертировать ScrollLock
SET_CS	EQU	0C7h	;установить адрес Code-script
S_RST	EQU	0C8h	;Рестарт системы
MOUSE	EQU	0C9h	;Передать команду мышке
;
no_scrp	EQU	0ffffh	;нельзя назначать скрипт
no_scan	EQU	0ffffh	;нет такого скан-кода
scrp_ff	equ	0ffffh	;не назначенный скрипт
;=================================================
; Буфер хранения адресов KBD-скриптов
;=================================================
tab_scr:
	Dw	no_scan		;00h
	Dw	scrp_ff		;01h+	F9
 	Dw	no_scan		;02h
	Dw	scrp_ff		;03h+	F5
	Dw	scrp_ff		;04h+	F3	
	Dw	scrp_ff		;05h+	F1
	Dw	TEST_MOUS	;06h+	F2
	Dw	no_scrp		;07h+	F12	NMI
	Dw	scrp_ff		;08h+(83h) F7
	Dw	TEST_COLOR	;09h+	F10	-> Тест цвета
	Dw	scrp_ff		;0Ah+	F8
	Dw	scrp_ff		;0Bh+	F6
	Dw	scrp_ff		;0Ch+	F4
;-----
	Dw	scrp_ff		;0Dh+	 Tab
	Dw	scrp_ff		;0Eh+	 `/~
	Dw	no_scan		;0Fh
;
	Dw	no_scan		;10h
	Dw	no_scrp		;11h+	Left Alt
	Dw	no_scrp		;12h+	Left Shift	SymSh
	Dw	no_scan		;13h
	Dw	no_scrp		;14h+	Left Ctrl	CapSh
	Dw	scrp_ff		;15h+	Q
	Dw	scrp_ff		;16h+	1/!
	Dw	no_scan		;17h
	Dw	no_scan		;18h
	Dw	no_scan		;19h
	Dw	scrp_ff		;1Ah+	Z
	Dw	scrp_ff		;1Bh+	S
	Dw	scrp_ff		;1Ch+	A
	Dw	scrp_ff		;1Dh+	W
	Dw	scrp_ff		;1Eh+	2/@
	Dw	no_scan		;1Fh
;
	Dw	no_scan		;20h
	Dw	scrp_ff		;21h+	C
	Dw	scrp_ff		;22h+	X
	Dw	scrp_ff		;23h+	D
	Dw	scrp_ff		;24h+	E
	Dw	scrp_ff		;25h+	4/$
	Dw	scrp_ff		;26h+	3/#
	Dw	no_scan		;27h
	Dw	no_scan		;28h
	Dw	scrp_ff		;29h+	SPACE
	Dw	t_vers		;2Ah+	V	Текст версии
	Dw	scrp_ff		;2Bh+	F
	Dw	TR_DOS		;2Ch+	T	-> RAND USR 15619<ET>
	Dw	TR_DO1		;2Dh+	R	-> RAND USR 1561
	Dw	scrp_ff		;2Eh+	5/%
	Dw	no_scan		;2Fh
;
	Dw	no_scan		;30h
	Dw	scrp_ff		;31h+	N
	Dw	scrp_ff		;32h+	B
	Dw	scrp_ff		;33h+	H
	Dw	scrp_ff		;34h+	G
	Dw	scrp_ff		;35h+	Y
	Dw	scrp_ff		;36h+	6/^
	Dw	no_scan		;37h
	Dw	no_scan		;38h
	Dw	no_scan		;39h
	Dw	scrp_ff		;3Ah+	M
	Dw	scrp_ff		;3Bh+	J
	Dw	scrp_ff		;3Ch+	U
	Dw	scrp_ff		;3Dh+	7/&
	Dw	scrp_ff		;3Eh+	8/*
	Dw	no_scan		;3Fh
;
	Dw	no_scan		;40h
	Dw	scrp_ff		;41h+	,/<
	Dw	scrp_ff		;42h+	K
	Dw	scrp_ff		;43h+	I
	Dw	scrp_ff		;44h+	O
	Dw	scrp_ff		;45h+	0/)
	Dw	scrp_ff		;46h+	9/(
	Dw	no_scan		;47h
	Dw	no_scan		;48h
	Dw	scrp_ff		;49h+	./>
	Dw	scrp_ff		;4Ah+	//?
	Dw	TAPE_LOAD	;4Bh+	L	-> LOAD ""<ET>
	Dw	scrp_ff		;4Ch+	;/:
	Dw	scrp_ff		;4Dh+	P
	Dw	scrp_ff		;4Eh+	-/_
	Dw	no_scan		;4Fh
;
	Dw	no_scan		;50h
	Dw	no_scan		;51h
	Dw	scrp_ff		;52h+	'/"
	Dw	no_scan		;53h
	Dw	scrp_ff		;54h+	[/{
	Dw	scrp_ff		;55h+	=/+
	Dw	no_scan		;56h
	Dw	no_scan		;57h
	Dw	scrp_ff		;58h+	Caps Lock
	Dw	no_scrp		;59h+ 	Right Shift
	Dw	scrp_ff		;5Ah+	ENTER
	Dw	scrp_ff		;5Bh+	]/}
	Dw	no_scan		;5Ch
	Dw	scrp_ff		;5Dh+	\/|
	Dw	no_scan		;5Eh
	Dw	no_scan		;5Fh
;
	Dw	no_scan		;60h
	Dw	no_scan		;61h
	Dw	no_scan		;62h
	Dw	no_scan		;63h
	Dw	no_scan		;64h
	Dw	no_scan		;65h
	Dw	scrp_ff		;66h+	BackSpace
	Dw	no_scan		;67h
	Dw	no_scan		;68h
	Dw	scrp_ff		;69h+	[1]
	Dw	no_scan		;6Ah
	Dw	scrp_ff		;6Bh+	[4]
	Dw	scrp_ff		;6Ch+	[7]
	Dw	no_scan		;6Dh
	Dw	no_scan		;6Eh
	Dw	no_scan		;6Fh
;
	Dw	RESTART		;70h+	[0]
	Dw	RESET		;71h+	[.]
	Dw	scrp_ff		;72h+	[2]
	Dw	scrp_ff		;73h+	[5]
	Dw	scrp_ff		;74h+	[6]
	Dw	scrp_ff		;75h+	[8]
	Dw	OpenSE_Reset_and_Load ;76h+	ESC
	Dw	no_scrp		;77h+	Num Lock
	Dw	TEST_SC		;78h+	F11 	-> Тест Scan Code
	Dw	scrp_ff		;79h+	[+]
	Dw	scrp_ff		;7Ah+	[3]
	Dw	scrp_ff		;7Bh+	[-]
	Dw	scrp_ff		;7Ch+	[*]
	Dw	scrp_ff		;7Dh+	[9]
	Dw	no_scrp		;7Eh+	Scroll Lock
	Dw	no_scan		;7Fh
;*************************************************
;******* КЛАВИАТУРНЫЕ СКРИПТЫ ********************
;*************************************************
TEST_MOUS:		;F2 -> Тест мышки
; 1 PRINT AT 0,0;
 DB K1,KP,SS+KI,K0,ZPT,K0,TZP,KCR
; 2 PRINT IN 64223;"  ";
 DB K2,KP,EXT,SS+KI,K6,K4,K2,K2,K3,TZP,KAV,KSP,KSP,KAV,TZP,KCR
; 3 PRINT IN 64479;"  ";
 DB K3,KP,EXT,SS+KI,K6,K4,K4,K7,K9,TZP,KAV,KSP,KSP,KAV,TZP,KCR
; 4 PRINT IN 65503;"  ";
 DB K4,KP,EXT,SS+KI,K6,K5,K5,K0,K3,TZP,KAV,KSP,KSP,KAV,TZP,KCR
; 5 PLOT IN 64479,IN 65503/1.5
 DB K5,KQ,EXT,SS+KI,K6,K4,K4,K7,K9,ZPT
 DB EXT,SS+KI,K6,K5,K5,K0,K3,SS+KV,K1,TCK,K5,KCR
; 6 GOTO 1
 DB K6,KG,K1,KCR
; RUN
 DB KR,KCR
 DB 0FFh		;конец скрипта
;-----------------------------------------
TEST_SC:		;F11 -> Тест Scan Code
; 1 LET a=32768
 DB K1,KL,KA,EQV,K3,K2,K7,K6,K8,KCR
; 2 FOR i=1 TO 28: READ d: POKE a+i,d: NEXT i
 DB K2,KF,KI,EQV,K1,SS+KF,K2,K8,DVT,EXT,KA,KD,DVT
 DB KO,KA,PLS,KI,ZPT,KD,DVT,KN,KI,KCR
; 3 RANDOMIZE USR (a+1)
 DB K3,KT,EXT,KL,OSK,KA,PLS,K1,ZSK,KCR
; 4 PRINT AT 0,0; PEEK a; "  "
 DB K4,KP,SS+KI,K0,ZPT,K0,TZP,EXT,KO,KA,TZP,KAV,KSP,KSP,KAV,KCR
; 5 GOTO 3
 DB K5,KG,K3,KCR
; 6 DATA 243,62,85,219,254,62,67,219,254
 DB K6,EXT,KD,K2,K4,K3,ZPT,K6,K2,ZPT,K8,K5,ZPT,K2,K1,K9,ZPT
 DB K2,K5,K4,ZPT,K6,K2,ZPT,K6,K7,ZPT,K2,K1,K9,ZPT,K2,K5,K4,KCR
; 7 DATA 219,254,7,7,7,7,230,240,79,219,254
 DB K7,EXT,KD,K2,K1,K9,ZPT,K2,K5,K4,ZPT,K7,ZPT,K7,ZPT,K7,ZPT,K7,ZPT,K2,K3,K0,ZPT
 DB K2,K4,K0,ZPT,K7,K9,ZPT,K2,K1,K9,ZPT,K2,K5,K4,KCR
; 8 DATA 230,15,177,50,0,128,251,201
 DB K8,EXT,KD,K2,K3,K0,ZPT,K1,K5,ZPT,K1,K7,K7,ZPT,K5,K0,ZPT,K0,ZPT,K1,K2,K8,ZPT
 DB K2,K5,K1,ZPT,K2,K0,K1,KCR
; RUN
 DB KR,KCR
 DB 0FFH		;конец скрипта
;-----------------------------------------
; Сброс компьютера WinMenu + Del
RESET:
 DB S_RES		;Выдать RESET
 DB 0FFh		;конец скрипта
;-------------------------------------------------
; Скрипт рестарта системы - WinMenu + INS/0
RESTART:
 DB S_RST		;RESTART контроллера
;-------------------------------------------------
t_vers:			;<WinMenu>+<V>
; "ZXKB v.1.3"
 DB KAV,CS+KZ,CS+KX,CS+KK,CS+KB,KSP,KV,TCK,K1,TCK,K3,KAV
 DB 0FFh
;-------------------------------------------------
; Скрипты от Alex_Nemo
;----------------------------------------
TR_DOS:		;Выход в TR-DOS(RAND. USR 15616)  <WinMenu>+<T>
; RANDOMIZE USR 15616<ENTER>
 DB KT,EXT,KL,K1,K5,K6,K1,K6,KCR
 DB 0FFh		;конец скрипта
;----------------------------------------
TR_DO1:		;Заготовка для TR-DOS(RAND. USR 1561(6/9))
; RANDOMIZE USR 1561    <WinMenu>+<R>
 DB KT,EXT,KL,K1,K5,K6,K1
 DB 0FFh		;конец скрипта
;----------------------------------------
TEST_COLOR:	;F10 Тест ЦВЕТА
; 1 BRIGHT 0
 DB K1,EXT,SS+KB,K0,KCR
; 2 FOR a=0 TO 21
 DB K2,KF,KA,EQV,K0,SS+KF,K2,K1,KCR
; 3 FOR s=0 TO 7
 DB K3,KF,KS,EQV,K0,SS+KF,K7,KCR
; 4 IF a>10 THEN BRIGHT 1
 DB K4,KU,KA,SS+KT,K1,K0,SS+KG,EXT,SS+KB,K1,KCR
; 5 PAPER s: PRINT "    ";
 DB K5,EXT,SS+KC,KS,DVT,KP,SNOP,KAV,KSP,KSP,KSP,KSP,KAV,TZP,KCR
; 6 NEXT s:NEXT a
 DB K6,KN,KS,DVT,KN,KA,KCR
; 7 BRIGHT 0
 DB K7,EXT,SS+KB,K0,KCR
; RUN
 DB KR,KCR
 DB 0FFH		;конец скрипта
;----------------------------------------
TAPE_LOAD:   ; ГРУЗИМСЯ С ЛЕНТЫ    <WinMenu>+<L>
; RESET,LOAD""<ENTER>
 DB S_RES
 DB PAUSE,100 ; пауза 1 секунда
; DB K1,PAUSE,100,K6,K6,K6,KCR ;- для Кворум 128
 DB KJ,KAV,KAV,KCR
 DB 0FFh		;конец скрипта
;-------------------------------------------------
; скрипты от zst для OpenSE BASIC
;-------------------------------------------------
OpenSE_Reset_and_Load:  ;ESC -> Сброс компьютера и загрузка с магнитофона
 DB S_RES
 DB PAUSE,50 ; пауза 0.5 секунд
; DB K1,PAUSE,50,K6,KCR ;- для Кворум 128
 DB CS+KL,CS+KO,CS+KA,CS+KD,KAV,KAV,KCR ; ВВОД ПОСИМВОЛЬНО: LOAD""ENTER
 DB 0FFh		;конец скрипта
;*************************************************
; end tab_scrp.asm
	end
