



#PICAXE 20M2

'----------Global Symbols-------------------
symbol tempvar=b7
symbol tempvar2=b10

symbol statusFlags = b0
	symbol homeNotFoundFlag = bit0
	symbol eepromConfiguredFlag = bit1
	symbol largeBinTableFlag = bit2
	symbol emptyBinConfiguredFlag = bit3
	symbol ThermoError = b11
'----------Rotary Encoder symbols------------
symbol sw=pinC.5     ' |   Rotary Encoder Switch
symbol clk=pinC.4    ' |   Rotary Encoder 
symbol dt=pinC.3     ' |   Rotary Encoder 

'symbol l1=B.4
'symbol l2=B.5
'symbol l3=B.6

symbol encpos=b2    'location entered in encoder
symbol encstatus=b3   ''which position the rotary encoder input is in
symbol encdir=b4   'outputs the change (if any) in the encoder's movement
symbol curpos=b5
symbol destpos=b6

'---------Stepper Motor Symbols-----------
'symbol coilA = B.0
'symbol coilB = B.1
'symbol coilC = B.2
'symbol coilD = B.3
symbol ThermoData = pinB.0  'was B.0
symbol ThermoCS = B.1  'was B.1
symbol ThermoClk = B.2

'uses stepcount as the counter
symbol spiData = w10
symbol CurTemp = w11


'symbol mDirNeg = B.2    'should always be low, can (and should) be replaced by a ground wire
symbol knobServo = B.3     'active low
'low mDirNeg
symbol stepcount = w7

symbol stepcount2 = w8
symbol eepromWPtr = w9
	symbol eepromWPtrL  = b18
	symbol eepromWPtrH = b19

debug
symbol steptime=8   '4
symbol numsteps=500   '1023     '128
symbol numsubsteps=100
symbol maxbins=9    'the number of bins that physically fit on the device with the spacing defined by numsteps

'----------------motor speeds---------------
	'pwmout pwmdiv64, B.1, 77, 156   '200 hz
	'pwmout pwmdiv64, B.1, 249, 500   '250 hz
	'pwmout pwmdiv64, B.1, 124, 250    '500hz
	'pwmout pwmdiv16, B.1, 249, 500    '1000hz
	
	'pwmout pwmdiv16, B.1, 165, 333   '1500hz
	'pwmout pwmdiv16, B.1, 124, 250    '2000hz,   for stress testing

	'pwmout pwmdiv4, B.1, 249, 500     '4000hz     works fine without bins




symbol disp=C.0
symbol dispbaud=n4800_16

'----------Menu Symbols---------
symbol menupos=b9




'-----------Rotary LEDs Symbols-----------
symbol auto_inc                = %10000000   'enable auto increment, send or-ed with each byte to slave for incrementing though led registers
symbol auto_inc_leds        = %10100000
symbol auto_inc_led_start = auto_inc_leds or $02

symbol ai02 = auto_inc or $02     ''First Byte of PWM output control
symbol ai14 = auto_inc or $14     ''First Byte of LEDOUT Registers, to enable and configure leds
symbol ledptr=b8

'serout disp, N2400_16,(254,128,"")
setup:
'pullup 1    'pull up resistor on B.0 for homing sensor
pause 15
high thermoCS   'chip select is active low
gosub setupleds
gosub clearleds


for tempvar = 0 to 15     'animation while waiting for display to initialize
	pause 30
	ledptr=tempvar + 2 or auto_inc_leds
	hi2cout ledptr,(255)
next tempvar
setfreq m16
gosub cleardisp
if sw=1 then
	serout disp, dispbaud, (254, 128, "Knob Homing...")', 254, 192, "", 254, 148,  "Description...")
'	gosub autohome
	servo knobServo, 100
else
	do
	loop until sw=1
endif
serout disp, dispbaud, (254, 192, "Scanning Bins...")
'gosub updateBinList
gosub setupExtEEPROM
gosub populateBinListCache
'serout disp, dispbaud, (254, 128, "Bin ", 254, 192, "Bin Title CanBe Long", 254, 148,  "Description...")
gosub clearleds
hi2cout 2, (255) 'light bin 0's led
gosub cleardisp
serout disp, dispbaud, (254, 128, "Bin 0")
curpos = 0
destpos=0
encpos=0      'not sure why this is being set to 255 in populateBinList
stepcount=0
stepcount2=0
gosub showBinInfo



main:
serout disp, dispbaud,(254,128)
if sw=1 then
	'serout disp, N2400_16,("H")
else
	stepcount=0
	do
		inc stepcount
		pause 7
		if stepcount = 250 then
			exit
		endif
	loop until sw=1
	if stepcount=250 then     'held for one second, wants the menu
		goto menu
	else
		destpos=encpos   'b5=b2
		
	endif
endif

gosub checkencoders

encpos=encpos+encdir


if encdir=1 or encdir=255 then
	if encpos = 255 then
		encpos = maxbins
	elseif encpos >maxbins then
		encpos = 0
	endif
	gosub i2cLEDs
	ledptr=encpos - 1 % 16 + 2  or auto_inc_leds ''set address to the led before encpos
	'if encpos <> curpos then
	 	hi2cout ledptr, (0,100,0)
	'else
	'	hi2cout ledptr, (255, 100) 
	'endif
	ledptr=curpos % 16 + 2
	hi2cout ledptr, (255)
'elseif encdir=255 then
	'ledptr=encpos % 16 + 2  or auto_inc_leds ''set address to encpos
	'if encpos <> curpos  then
	' 	hi2cout ledptr,(100,0)
	'else
	'	hi2cout ledptr,(100,255)
	'endif
'else
	gosub showBinInfo

	
endif


goto main


ackwait:     'wait for user to click the scrollwheel to acknowledge
	if sw=0 then
		do
			
		loop until sw=1
		return
	endif
	goto ackwait


checkencoders:
encdir=0
if clk=1 and dt=1 then
	encstatus=1    ''at one of the 'stops'
elseif clk=0 and dt=0 then
	encstatus=2
elseif clk > dt and encstatus=1 then
	encdir=1      'one
	encstatus=0
elseif clk < dt and encstatus=1 then
	encdir=255   'negative 1
	encstatus=0
elseif clk < dt and encstatus=2 then
	encstatus=0
elseif clk > dt and encstatus=2 then
	encstatus=0
endif

return

setupleds:

hi2csetup i2cmaster, %11011110, i2cfast_16, i2cbyte
hi2cout $00, (%0000000)   'leds active, don't respond to subaddress
hi2cout ai14, ($FF,$FF,$FF,$FF)  '

return

i2cleds:    'resetup i2cbyte and led adress
hi2csetup i2cmaster, %11011110, i2cfast_16, i2cbyte
return

clearleds:
hi2csetup i2cmaster, %11011110, i2cfast_16, i2cbyte
hi2cout auto_inc_led_start, (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
return

flashleds:
hi2csetup i2cmaster, %11011110, i2cfast_16, i2cbyte
hi2cout ai14, ($55,$55,$55,$55)    'all leds full brightness
pause 200 '50ms at 16MHz
hi2cout ai14, ($FF,$FF,$FF,$FF)       'back to individual led control
return

cleardisp:
serout disp, dispbaud, (254,1)
pause 120  '30ms at 6MHz
return

flashledsandcleardisp:      'clears display and momentairly flashes leds simultaneously
serout disp, dispbaud, (254,1)
hi2csetup i2cmaster, %11011110, i2cfast_16, i2cbyte
hi2cout ai14, ($55,$55,$55,$55)    'all leds full brightness
pause 200 '50ms at 16MHz
hi2cout ai14, ($FF,$FF,$FF,$FF)       'back to individual led control

return

dispBinPage:
	serout disp, dispbaud, (254, 128, "Bin")
	gosub showBinInfo
return


menu:
menupos=0
gosub clearleds
gosub flashledsandcleardisp
serout disp, dispbaud, (254, 128, "Menu:",254,192,"> Man Ctrl", 254, 202, "  ", $b3,"dateDta", 254,148, "  Bin Data", 254, 158, "  Status  ", 254, 214, "option E", 254, 222, "  Return")
menuloop:
	gosub checkencoders
	if encdir = 1 then
		inc menupos
		gosub updatemenu
	elseif encdir = 255 then
		dec menupos
		gosub updatemenu
	endif
	
	'TODO:  implement menu!
	if sw=0 then
		do
			
		loop until sw=1
		branch menupos, (manctrlmenu, updateBinList, menuloop , showStatus, menuloop,backToMain)   'menuloop for unimplemented items
	endif
goto menuloop

showStatus:
	gosub flashledsandcleardisp
showStatusLoop:
	'serout disp, dispbaud, (254, 128, "Status: ")
	gosub getTemp
	if sw=0 then
		do
			
		loop until sw=1
		goto menu
	endif

goto showStatusLoop

updatemenu:
serout disp, dispbaud, (254,192," ", 254, 202, " ", 254,148, " ", 254, 158, " ", 254, 212, " ", 254, 222, " ")
tempvar=0
lookup menupos, (192, 202, 148, 158, 212, 222), tempvar

if menupos=255 then 'going backwards from first menu item
	menupos=5         'go to last item
	tempvar=222
	

elseif tempvar=0 then    'beyond last menu item
	menupos=0
	tempvar=192
endif
serout disp, dispbaud, (254, tempvar, ">")

return


manctrlmenu:
menupos=0
gosub clearleds
gosub flashledsandcleardisp
serout disp, dispbaud, (254, 128, "Manual Control:",254,192,"> Forward", 254, 202,"  Backward", 254,148, "  Rehome  ", 254, 158, "  Stop", 254, 212, "  RelaxMtr", 254, 222, "  Return")
manctrlmenuloop:
	gosub checkencoders
	if encdir = 1 then
		inc menupos
		gosub updatemenu
	elseif encdir = 255 then
		dec menupos
		gosub updatemenu
	endif
	
	'TODO:  implement menu!
	if sw=0 then
		do
			
		loop until sw=1
		branch menupos, (manctrlmenuloop, menu, menu, menu, menu, menu)   'manctrlmenuloop for unimplemented items
	endif
goto manctrlmenuloop


backToMain:
	gosub flashledsandcleardisp
	gosub dispBinPage
goto main

updatebin:
'TODO: implement
return

''''''''-----------Manual Control Subroutines--------------''''''''


'''''''------------Thermocouple subroutines-------------------''''''''
'handles thermocouple with this sensor https://www.adafruit.com/product/269
'datasheet: https://www.analog.com/media/en/technical-documentation/data-sheets/MAX31855.pdf


getTemp:

low ThermoCS
low ThermoClk
gosub shiftin_MSB_Post
ThermoError = spiData & 1
CurTemp =spiData/16*9/5+32     'spiData/4*9/5/4+32    '/16=C,  *9/5+32 converts to F

serout disp, dispbaud, (254, 128,"Int ",#CurTemp," Err: ", #ThermoError,"    ")

gosub shiftin_MSB_Post
high ThermoCS
pause 1
CurTemp = spiData/256*9/5+32    'spiData/16*9/5/16+32  
ThermoError = spiData & %111
serout disp, dispbaud, (254, 192,"Ext  ",#CurTemp," Err: ", #ThermoError,"    ")

return




shiftin_MSB_Post:
	spiData = 0
	for stepcount = 1 to 16		; number of bits
		spiData = spiData * 2		; shift left as MSB first	  
		if ThermoData <> 0 then 
			spiData = spiData + 1		; set LSB if serdata = 1
		end if
  		pulsout ThermoClk,1		; pulse clock to get next data bit
		'pause 1
	next stepcount
	return



'-------------EEPROM subroutines------------


setupExtEEPROM:
	hi2csetup i2cmaster, %10100000, i2cfast_16, i2cword   'socketed, removable eeprom
	hi2cin 0, (tempvar, tempvar2)
	if tempvar = $1A and tempvar2 = $01 then
		eepromConfiguredFlag = 1
		'sertxd("EEPROM configured",cr, lf)
	else
		eepromConfiguredFlag = 0
	endif
return

i2cExtEEPROM:     'set the i2c back to i2cword and eeprom address
	hi2csetup i2cmaster, %10100000, i2cfast_16, i2cword   'socketed, removable eeprom
return


populateBinListCache:
	'bptr=30
	'sertxd("listcache", cr,lf)
	hi2cin $09, (tempvar)
	for stepcount = tempvar to $6E step 2   '$6E is last non-special bin address
		bptr=stepcount+30-tempvar
		if bptr > 64  then 'more than 1 'page' of ram used for table (17 bins)
			largeBinTableFlag=1
		endif

		hi2cin stepcount, (eepromWPtrH, eepromWPtrL)   'read the 2-byte address, big endian order
		'sertxd ("address ", #eepromwptr,"at",#bptr, cr, lf)
		if eepromWPtr <> $FFFF then
			@bptrinc = eepromWPtrH
			@bptrinc = eepromWPtrL
		else
			@bptrinc = $0   'mark end of configured bins
			@bptrinc = $0
			exit
		endif
		
	next stepcount
 
	'gosub populateBinCache
	
	'repeat for special adresses (Currently Supports Just One, Error_Empty)
	hi2cin $0B, (tempvar)
	'for stepcount = tempvar to $FE step 2   '$6E is last non-special bin address
	bptr=28     'stepcount+30-tempvar
	'if bptr > 64  then 'more than 1 'page' of ram used for table (17 bins)
	'	largeBinTableFlag=1
	'endif
	
	hi2cin tempvar, (eepromWPtrH, eepromWPtrL)   'read the 2-byte address, big endian order
	'sertxd ("address ", #eepromwptr,"at",#bptr, cr, lf)
	if eepromWPtr <> $FFFF then
		@bptrinc = eepromWPtrH
		@bptrinc = eepromWPtrL
		emptyBinConfiguredFlag = 1
		'sertxd("error page at ",#eepromwptr)
	else
		'sertxd("empty data not found")
		emptyBinConfiguredFlag = 0
	'	@bptrinc = $FF
	'	@bptrinc = $FF
	'	exit
	endif
	'gosub populateSpecialCache
	'next stepcount
	
return

'populateSpecialCache:      'currently only handles Error_Empty
'	peek 28, word bptr  
'	if bptr <> $FFFF then
'		for stepcount2 = 0 to 63    'copy the bin data over
'			eepromWPtr = bptr ''''''Ignore this:     file table takes 128bytes on eeprom, but only 64 if small enough in picaxe ram, but save 64 more bytes for empty error message
'			hi2cin eepromWptr, (@bptrinc)
'		next stepcount2
'	endif
'return

'populateBinCache:
'	if largeBinTableFlag=0 then
'		for stepcount = 30 to 64 step 2 ''TODO: 128 or more for large bin tables (largeBinTableFlag set)
'			peek stepcount, word bptr
'			if bptr <> $FFFF then
'				for stepcount2 = 0 to 63    'copy the bin data over
'					eepromWPtr = bptr' +64 ''ignore this:      file table takes 128bytes on eeprom, but only 64 if small enough in picaxe ram, but save 64 more bytes for empty error message
'					hi2cin eepromWptr, (@bptrinc)
'				next stepcount2
'			else
'				exit
'			endif
'		next stepcount
	'else
		'Not yet implemented for large tables
'	endif
'return

showBinInfo:
	serout disp, dispbaud,(254,132,#encpos, "  ")
	eepromWPtr = encpos * 2 + 30   'location of bin in bintable
	'sertxd("showing bin at", #eepromWPtr)
	peek eepromWPtr,word stepcount2
	'sertxd("bptr:",#bptr)
	if stepcount2=0 then  'undefined bin
		peek 28, word stepcount2
		'sertxd("unlabled bin! bptr now ",#bptr)
	endif
	stepcount2 = stepcount2+9'10-1   'start of bin name string
	'stepcount2=stepcount2-1  'moved to above line'to get the value before the 1st read    '''todo: replace bptr above
	'sertxd("Name string at", #bptr)
	gosub i2cExtEEPROM
	serout disp, dispbaud, (254, 192)
	hi2cin stepcount2, (tempvar2) 'garbage data, but sets the address for reading correctly
	for stepcount = 0 to 19
		'sertxd("reading  address",#stepcount2)
		hi2cin (tempvar2)
		'if @bptr = 0 then
		if tempvar2=0 then 
			serout disp, dispbaud, (" ")
		else
			serout disp, dispbaud, (tempvar2)
		endif
	next stepcount
	peek eepromWPtr,word stepcount2
	if stepcount2=0 then  'undefined bin
		peek 28, word stepcount2
		'sertxd("unlabled bin! bptr now ",#bptr)
	endif
	stepcount2 = stepcount2+29   'start of bin description string - 1
	hi2cin stepcount2, (tempvar2) 'garbage data, but sets the address for reading correctly
	serout disp, dispbaud, (254, 148)
	for stepcount = 0 to 30    'populates the hidden display buffer too    'can be 20 for now
		hi2cin (tempvar2)
		'if @bptr = 0 then
		if tempvar2=0 then 
			serout disp, dispbaud, (" ")
		else
			serout disp, dispbaud, (tempvar2)
		endif
	next stepcount
return

updateBinList:
	gosub cleardisp
	serout disp, dispbaud, (254,128,"Updating Bin List", 254, 192)
	gosub setupExtEEPROM
	if eepromConfiguredFlag  = 1 then
		serout disp, dispbaud, ("Loading", 254, 148)
	else
		serout disp, dispbaud, ("Failed", 254, 148)
		goto menu	
	endif
	gosub populateBinListCache
goto menu


