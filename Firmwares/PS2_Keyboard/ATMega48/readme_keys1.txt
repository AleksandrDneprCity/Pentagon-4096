AVR ZX-Spectrum Keyboard Controller for Atmega48
Version 5.6.1 (30.04.2020)

Features:
- NoWait version
- Reset - F12
- Magic - Print Screen
- Pause - Pause/Break
- Fixed Button1 for Turbo On/Off - Scroll Lock
- Fixed Button1+Fixed Button2 - Rigth Shift + Scroll Lock (external generator only)
- C - Caps Lock
- E - ESC
- G - Del
- CapsShift - Shift (works really as on PC!)
- SymbolShift - Ctrl
- NumLock changes cursor keys and space to Sinclair Joystik

Interrupt WAIT CLK from Keyboard if no CLK 15 ms later
Increase small deyal for ATmega48PA-PU from 8 to 13 cycles

Removed saving indicators to EEPROM function
Extra optimized code

You may direct connect this controller to Keyboard port

/RDFE - is a signal from #FE port buffer Pin 1
(сигнал с дешифратора порта #FE, обычно приходит на певую ногу микросхемы ИР22 или ИР23 на которую идут биты данных клавиатуры)

Uploading:

	Use avrdude and USBAsp programmer (for external crystal oscillator)

	avrdude -p atmega48 -c USBasp -U flash:w:KBD13_M48_nw_MODIFIEDv5_6_1_20MHz.hex -U lfuse:w:0xEF:m -U hfuse:w:0xD4:m

	Use avrdude and USBAsp programmer (for external generator)

	avrdude -p atmega48 -c USBasp -U flash:w:KBD13_M48_nw_MODIFIEDv5_6_1_20MHz.hex -U lfuse:w:0xD0:m -U hfuse:w:0xD4:m


You may use sources to compile for different oscillators changing TIMING_COEFF value

ORIGIN: http://www.avray.ru