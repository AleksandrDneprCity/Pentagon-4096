	ORG	800H
;-------------------------------------------------
; “аблицы раскладки клавиатуры дл€ работы в режиме
; *********** Scan Code 2 ************************
; ќсновна€ таблица состоит из двух половин, перва€
; соответствует клавишам, которые при нажатии выдают
; ќднобайтный скан-код, втора€ половина клавишам,
; которые при нажатии выдают дополнительно префикс 0xE0.
; ¬ этой таблице каждому скан-коду IBM-клавиатуры
; соответствует один байт, который содержит информацию
; о номере колонки и номере строки, в которой будет
; имитироватс€ замыкание контакта клавиатуры —пектрума.
; ƒополнительно каждому коду можно добавить признак
; нажати€ функциональной клавиши:
; d6 сигнализирует о дополнительном нажатии Symbol Shift;
; d7 о нажатии Caps Shift.
; ƒл€ клавиш IBM клавиатуры, которые в зависимости от
; нажати€ Shift имеют разные коды, предусмотрено перек-
; лючение таблицы на дополнительную, признаком этого
; €вл€етс€ d7 и d6=1.
; ѕропущенные скан-коды можно забить любым кодом.
; Ќезадействованные скан-коды заполн€ютс€ кодом 0.
; ѕоскольку таблица жестко св€зана со скан-кодами,
; нельз€ ни пропускать, ни добавл€ть в нее строки.
; ƒополнительную таблицу можно расшир€ть в сторону
; увеличени€ практически до 63 строк. Ќо начало
; этой таблицы тоже жестко определено.
;--------------------------------------------------------
; биты данных сканировани€ (d2..d0) [номер строки +1]
D0	EQU	001H
D1	EQU	002H
D2	EQU	003H
D3	EQU	004H
D4	EQU	005H
; биты адреса сканировани€ (d5..d3) [номер колонки *8]
A08	EQU	000H
A09	EQU	008H
A10	EQU	010H
A11	EQU	018H
A12	EQU	020H
A13	EQU	028H
A14	EQU	030H
A15	EQU	038H
; ѕрефиксные биты (d7..d6)
CapSh	EQU	080H	;флаг Caps Shift
SymSh	EQU	040H	;флаг Symbol Shift
AltTb	EQU	0C0H	;флаг доп.таблицы
; скан-коды основных клавиш
Kl_1	EQU	A11+D0
Kl_2	EQU	A11+D1
Kl_3	EQU	A11+D2
Kl_4	EQU	A11+D3
Kl_5	EQU	A11+D4
;
Kl_6	EQU	A12+D4
Kl_7	EQU	A12+D3
Kl_8	EQU	A12+D2
Kl_9	EQU	A12+D1
Kl_0	EQU	A12+D0
;
Kl_Q	EQU	A10+D0
Kl_W	EQU	A10+D1
Kl_E	EQU	A10+D2
Kl_R	EQU	A10+D3
Kl_T	EQU	A10+D4
;
Kl_Y	EQU	A13+D4
Kl_U	EQU	A13+D3
Kl_I	EQU	A13+D2
Kl_O	EQU	A13+D1
Kl_P	EQU	A13+D0
;
Kl_A	EQU	A09+D0
Kl_S	EQU	A09+D1
Kl_D	EQU	A09+D2
Kl_F	EQU	A09+D3
Kl_G	EQU	A09+D4
;
Kl_H	EQU	A14+D4
Kl_J	EQU	A14+D3
Kl_K	EQU	A14+D2
Kl_L	EQU	A14+D1
Kl_CR	EQU	A14+D0  ;Enter
;
Kl_CS	EQU	A08+D0  ;Caps Shift
Kl_Z	EQU	A08+D1
Kl_X	EQU	A08+D2
Kl_C	EQU	A08+D3
Kl_V	EQU	A08+D4
;
Kl_B	EQU	A15+D4
Kl_N	EQU	A15+D3
Kl_M	EQU	A15+D2
Kl_SS	EQU	A15+D1  ;Symbol Shift
Kl_Sp	EQU	A15+D0	;ѕробел
;----------------------------------------------------------------
; Scan Code 2 без префикса 0E0h
;		это скан-код IBM vvv
tab_kbd:			;	vvv - а это клавиша IBM
	DB	0FFH		;00h
	DB	SymSh+Kl_D	;01h+	F9
	DB	0FFH		;02h
	DB	SymSh+Kl_U	;03h+	F5
	DB	SymSh+Kl_E	;04h+	F3	
	DB	SymSh+Kl_Q	;05h+	F1
	DB	SymSh+Kl_W	;06h+	F2
	DB	000H		;07h+	F12	NMI
	DB	SymSh+Kl_A	;08h+(83h) F7
	DB	SymSh+Kl_F	;09h+	F10
	DB	SymSh+Kl_S	;0Ah+	F8
	DB	SymSh+Kl_I	;0Bh+	F6
	DB	SymSh+Kl_Y	;0Ch+	F4
;-----
	DB	CapSh+Kl_1	;0Dh+	 Tab	CapSh+"1" Edit
	DB	AltTb+0		;0Eh+	 `/~ 	-> AltTab
	DB	0FFH		;0Fh
;
	DB	0FFH		;10h
	DB	CapSh+Kl_3	;11h+	Left Alt
	DB	Kl_SS		;12h+	Left Shift	SymSh
	DB	0FFH		;13h
	DB	Kl_CS		;14h+	Left Ctrl	CapSh
	DB	Kl_Q		;15h+	Q
	DB	Kl_1		;16h+	1/!
	DB	0FFH		;17h
	DB	0FFH		;18h
	DB	0FFH		;19h
	DB	Kl_Z		;1Ah+	Z
	DB	Kl_S		;1Bh+	S
	DB	Kl_A		;1Ch+	A
	DB	Kl_W		;1Dh+	W
	DB	Kl_2		;1Eh+	2/@
	DB	0FFH		;1Fh
;
	DB	0FFH		;20h
	DB	Kl_C		;21h+	C
	DB	Kl_X		;22h+	X
	DB	Kl_D		;23h+	D
	DB	Kl_E		;24h+	E
	DB	Kl_4		;25h+	4/$
	DB	Kl_3		;26h+	3/#
	DB	0FFH		;27h
	DB	0FFH		;28h
	DB	Kl_Sp		;29h+	SPACE
	DB	Kl_V		;2Ah+	V
	DB	Kl_F		;2Bh+	F
	DB	Kl_T		;2Ch+	T
	DB	Kl_R		;2Dh+	R
	DB	Kl_5		;2Eh+	5/%
	DB	0FFH		;2Fh
;
	DB	0FFH		;30h
	DB	Kl_N		;31h+	N
	DB	Kl_B		;32h+	B
	DB	Kl_H		;33h+	H
	DB	Kl_G		;34h+	G
	DB	Kl_Y		;35h+	Y
	DB	AltTb+11 ;Kl_6	;36h+	6/^	-> AltTab
	DB	0FFH		;37h
	DB	0FFH		;38h
	DB	0FFH		;39h
	DB	Kl_M		;3Ah+	M
	DB	Kl_J		;3Bh+	J
	DB	Kl_U		;3Ch+	U
	DB	AltTb+12 ;Kl_7	;3Dh+	7/&	-> AltTab
	DB	AltTb+13 ;Kl_8	;3Eh+	8/*	-> AltTab
	DB	0FFH		;3Fh
;
	DB	0FFH		;40h
	DB	AltTb+1		;41h+	,/<	-> AltTab
	DB	Kl_K		;42h+	K
	DB	Kl_I		;43h+	I
	DB	Kl_O		;44h+	O
	DB	AltTb+15 ;Kl_0	;45h+	0/)	-> AltTab
	DB	AltTb+14 ;Kl_9	;46h+	9/(	-> AltTab
	DB	SymSh+Kl_D	;47h
	DB	0FFH		;48h
	DB	AltTb+2		;49h+	./>	-> AltTab
	DB	AltTb+3		;4Ah+	//?	-> AltTab
	DB	Kl_L		;4Bh+	L
	DB	AltTb+4		;4Ch+	;/:	-> AltTab
	DB	Kl_P		;4Dh+	P
	DB	AltTb+5		;4Eh+	-/_	-> AltTab
	DB	0FFH		;4Fh
;
	DB	0FFH		;50h
	DB	0FFH		;51h
	DB	AltTb+6		;52h+	'/" 	-> AltTab
	DB	0FFH		;53h
	DB	AltTb+7		;54h+	[/{ 	-> AltTab
	DB	AltTb+8		;55h+	=/+ 	-> AltTab
	DB	0FFH		;56h
	DB	000H		;57h
	DB	AltTb+16	;58h+	Caps Lock
	DB	000H		;59h+ 	Right Shift -> 12h
	DB	Kl_CR		;5Ah+	ENTER
	DB	AltTb+9		;5Bh+	]/} -> AltTab
	DB	0FFH		;5Ch
	DB	AltTb+10	;5Dh+	\/| -> AltTab
	DB	000H		;5Eh
	DB	000H		;5Fh
;
	DB	0FFH		;60h
	DB	0FFH		;61h
	DB	0FFH		;62h
	DB	0FFH		;63h
	DB	0FFH		;64h
	DB	0FFH		;65h
	DB	CapSh+Kl_0	;66h+	BackSpace
	DB	0FFH		;67h
	DB	0FFH		;68h
	DB	Kl_1		;69h+	[1]
	DB	0FFH		;6Ah
	DB	Kl_4		;6Bh+	[4]
	DB	Kl_7		;6Ch+	[7]
	DB	0FFH		;6Dh
	DB	0FFH		;6Eh
	DB	0FFH		;6Fh
;
	DB	Kl_0		;70h+	[0]
	DB	SymSh+Kl_M	;71h+	[.]
	DB	Kl_2		;72h+	[2]
	DB	Kl_5		;73h+	[5]
	DB	Kl_6		;74h+	[6]
	DB	Kl_8		;75h+	[8]
	DB	CapSh+Kl_SS	;76h+	ESC
	DB	000H		;77h+	Num Lock
	DB	CapSh+Kl_9	;78h+	F11
	DB	SymSh+Kl_K	;79h+	[+]
	DB	Kl_3		;7Ah+	[3]
	DB	SymSh+Kl_J	;7Bh+	[-]
	DB	SymSh+Kl_B	;7Ch+	[*]
	DB	Kl_9		;7Dh+	[9]
	DB	000H		;7Eh+	Scroll Lock
	DB	0FFH		;7Fh
; лавиши с префиксом 0E0h
tab_kbd_E0:
	DB	0FFh		;00h
	DB	0FFh		;01h
	DB	0FFh		;02h
	DB	0FFh		;03h
	DB	0FFh		;04h
	DB	0FFh		;05h
	DB	0FFh		;06h
	DB	0FFh		;07h
	DB	0FFh		;08h
	DB	0FFh		;09h
	DB	0FFh		;0Ah
	DB	0FFh		;0Bh
	DB	0FFh		;0Ch
	DB	0FFh		;0Dh
	DB	0FFh		;0Eh
	DB	0FFh		;0Fh
;
	DB	0FFh		;10h
	DB	CapSh+Kl_4	;11h+	R Alt
	DB	000H		;12h+	Print Screen RESET
	DB	0FFh		;13h
	DB	0FFh		;14h+	R Ctrl -> L Ctrl (11h)
	DB	0FFh		;15h
	DB	0FFh		;16h
	DB	0FFh		;17h
	DB	0FFh		;18h
	DB	0FFh		;19h
	DB	0FFh		;1Ah
	DB	0FFh		;1Bh
	DB	0FFh		;1Ch
	DB	0FFh		;1Dh
	DB	0FFh		;1Eh
	DB	SymSh+Kl_CR	;1Fh+	Left Fly Win
;
	DB	0FFh		;20h
	DB	0FFh		;21h
	DB	0FFh		;22h
	DB	0FFh		;23h
	DB	0FFh		;24h
	DB	0FFh		;25h
	DB	0FFh		;26h
	DB	SymSh+Kl_CR	;27h+	Right Fly Win
	DB	0FFh		;28h
	DB	0FFh		;29h
	DB	0FFh		;2Ah
	DB	0FFh		;2Bh
	DB	0FFh		;2Ch
	DB	0FFh		;2Dh
	DB	0FFh		;2Eh
	DB	000h		;2Fh+	Win Menu
;
	DB	0FFh		;30h
	DB	0FFh		;31h
	DB	0FFh		;32h
	DB	0FFh		;33h
	DB	0FFh		;34h
	DB	0FFh		;35h
	DB	0FFh		;36h
	DB	000H		;37h+	[Power]
	DB	0FFh		;38h
	DB	0FFh		;39h
	DB	0FFh		;3Ah
	DB	0FFh		;3Bh
	DB	0FFh		;3Ch
	DB	0FFh		;3Dh
	DB	0FFh		;3Eh
	DB	000H		;3Fh+	[Sleep]
;
	DB	0FFh		;40h
	DB	0FFh		;41h
	DB	0FFh		;42h
	DB	0FFh		;43h
	DB	0FFh		;44h
	DB	0FFh		;45h
	DB	0FFh		;46h
	DB	0FFh		;47h
	DB	0FFh		;48h
	DB	0FFh		;49h
	DB	SymSh+Kl_V	;4Ah+	[/]
	DB	0FFh		;4Bh
	DB	0FFh		;4Ch
	DB	0FFh		;4Dh
	DB	0FFh		;4Eh
	DB	0FFh		;4Fh
;
	DB	0FFh		;50h
	DB	0FFh		;51h
	DB	0FFh		;52h
	DB	0FFh		;53h
	DB	0FFh		;54h
	DB	0FFh		;55h
	DB	0FFh		;56h
	DB	0FFh		;57h
	DB	0FFh		;58h
	DB	0FFh		;59h
	DB	Kl_CR		;5Ah+	[Enter]
	DB	0FFh		;5Bh
	DB	0FFh		;5Ch
	DB	0FFh		;5Dh
	DB	000H		;5Eh+	[Wake Up]
	DB	0FFh		;5Fh
;
	DB	0FFh		;60h
	DB	0FFh		;61h
	DB	0FFh		;62h
	DB	0FFh		;63h
	DB	0FFh		;64h
	DB	0FFh		;65h
	DB	0FFh		;66h
	DB	0FFh		;67h
	DB	0FFh		;68h
	DB	SymSh+Kl_E	;69h+	[End]
	DB	0FFh		;6Ah
	DB	CapSh+Kl_5	;6Bh+	[Left]
	DB	SymSh+Kl_Q	;6Ch+	[Home]
	DB	0FFh		;6Dh
	DB	0FFh		;6Eh
	DB	0FFh		;6Fh
;
	DB	SymSh+Kl_W	;70h+	[Insert]
	DB	CapSh+Kl_9	;71h+	[Del]
	DB	CapSh+Kl_6	;72h+	[Down]
	DB	0FFh		;73h
	DB	CapSh+Kl_8	;74h+	[Right]
	DB	CapSh+Kl_7	;75h+	[Up]
	DB	0FFh		;76h
	DB	0FFh		;77h
	DB	0FFh		;78h
	DB	0FFh		;79h
	DB	CapSh+Kl_4	;7Ah+	[Pg Down]
	DB	0FFh		;7Bh
	DB	0FFh		;7Ch
	DB	CapSh+Kl_3	;7Dh+	[Pg Up]
	DB	0FFh		;7Eh
	DB	0FFh		;7Fh
;--------------------------------------------
; “аблица клавиш с двум€ кодами:
; 1код - без Shift
; 2код -  с  Shift
AltTab:
	DB	SymSh+Kl_X,SymSh+Kl_A	;0Eh `/~ -> AltTab+0
	DB	SymSh+Kl_N,SymSh+Kl_R	;41h ,/< -> AltTab+1
	DB	SymSh+Kl_M,SymSh+Kl_T	;49h ./> -> AltTab+2
	DB	SymSh+Kl_V,SymSh+Kl_C	;4Ah //? -> AltTab+3
	DB	SymSh+Kl_O,SymSh+Kl_Z	;4Ch ;/: -> AltTab+4
	DB	SymSh+Kl_J,SymSh+Kl_0	;4Eh -/_ -> AltTab+5
	DB	SymSh+Kl_7,SymSh+Kl_P	;52h '/" -> AltTab+6
	DB	SymSh+Kl_Y,SymSh+Kl_F	;54h [/{ -> AltTab+7
	DB	SymSh+Kl_L,SymSh+Kl_K	;55h =/+ -> AltTab+8
	DB	SymSh+Kl_U,SymSh+Kl_G	;5Bh ]/} -> AltTab+9
	DB	SymSh+Kl_D,SymSh+Kl_S	;5Ch \/| -> AltTab+10
	DB	Kl_6,SymSh+Kl_H		;3Eh 6/^ -> AltTab+11
	DB	Kl_7,SymSh+Kl_6		;46h 7/' -> AltTab+12
	DB	Kl_8,SymSh+Kl_B		;3Eh 8/* -> AltTab+13
	DB	Kl_9,SymSh+Kl_8		;46h 9/( -> AltTab+14
	DB	Kl_0,SymSh+Kl_9		;45h 0/) -> AltTab+15
; Caps Lock при нажатии с Shift не выдает код
	DB	CapSh+Kl_2,00h		;14h Caps Lock -> AltTab+16
;********************************************
	END
