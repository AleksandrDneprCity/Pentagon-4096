;------------------------------------------------------------------------------------------------------
;Описание: Все порты и внутренние регистры микроконтроллера  ATTINY13
;------------------------------------------------------------------------------------------------------
;			.DEVICE ATtiny13

			.EQU ADCSRB =$03;
			.EQU ADCL   =$04;
			.EQU ADCH   =$05;
			.EQU ADCW   =$04; 		// 16 bit access
			.EQU ADCSRA =$06;
			.EQU ADMUX  =$07;
			.EQU ACSR   =$08;
			.EQU DIDR0  =$14;
			.EQU PCMSK  =$15;
			.EQU PINB   =$16;
			.EQU DDRB   =$17;
			.EQU PORTB  =$18;
			.EQU EECR   =$1C;
			.EQU EEDR   =$1D;
			.EQU EEAR   =$1E;
			.EQU WDTCR  =$21;
			.EQU CLKPR  =$26;
			.EQU GTCCR  =$28;
			.EQU OCR0B  =$29;
			.EQU DWDR   =$2E;
			.EQU TCCR0A =$2F;
			.EQU OSCCAL =$31;
			.EQU TCNT0  =$32;
			.EQU TCCR0B =$33;
			.EQU MCUSR  =$34;
			.EQU MCUCR  =$35;
			.EQU OCR0A  =$36;
			.EQU SPMCSR =$37;
			.EQU TIFR0  =$38;
			.EQU TIMSK0 =$39;
			.EQU GIFR   =$3A;
			.EQU GIMSK  =$3B;
			.EQU SPL    =$3D;
			.EQU SREG   =$3F;

