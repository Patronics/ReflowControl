


;***** SPI symbol definitions *****
symbol sclk = B.2				; clock (output pin)
'symbol sdata = 			; data (output pin for shiftout)
symbol serdata = pinB.0			; data (input pin for shiftin, note input7)
symbol counter = b7			; variable used during loop

symbol var_in = w5			; data variable used durig shiftin

symbol bits = 16				; number of bits
'symbol MSBvalue = 128			; MSBvalue =128 for 8 bits, 512 for 10 bits, 2048 for 12 bits)
symbol ThermoCS = B.1  'was B.1

''''''''temperature variables''''''''

symbol ext_raw = w7
symbol int_raw = w8
symbol ext_f = w9
symbol int_f = w10

symbol errorFlags = b0
symbol SCVFault = bit2
symbol SCGFault = bit1
symbol OCFault = bit2

''''''''Display Symbols''''''''''

symbol disp=C.0
symbol dispbaud=n4800_16





setup:
setfreq m16
serout disp, dispbaud, (254, 1)
pause 120    '30ms @16mHz



main:
low ThermoCS
gosub shiftin_MSB_Pre
ext_raw=var_in
gosub shiftin_MSB_Pre
int_raw=var_in
high ThermoCS

'measured temperature
ext_f =ext_raw/4*9/5/4+32     'spiData/4*9/5/4+32

'measured reference temperature
int_f = int_raw/256*9/5+32
errorFlags = int_raw& %0000000000000111

serout disp, dispbaud, (254, 128,"Meas ",#ext_f,"   ")
serout disp, dispbaud, (254, 192,"Ref  ",#int_f,"   ")'," Err: ", #ThermoError,"    ")
if errorFlags <>0  then
	serout disp, dispbaud, (254, 148,"Therm Err:  ",#errorFlags,"   ")
endif
debug
goto main


shiftin_MSB_Pre:

	let var_in = 0
	for counter = 1 to bits		; number of bits
	  var_in = var_in * 2		; shift left as MSB first
	  if serdata <> 0 then 
	    var_in = var_in + 1		; set LSB if serdata = 1
	  end if
	  pulsout sclk,1		; pulse clock to get next data bit
	next counter
	return