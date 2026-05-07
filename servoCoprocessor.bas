'servoCoprocessor.bas
'Intended for use with ReflowControl.bas
'uses PICAXE 08M2 to operate servo, 
'avoiding jitter caused by other tasks on the main processor.
'other features on remaining GPIO are also supported

'receives commands at 9600 baud non-inverted UART on pin C.1
'valid commands: "L"/"M"/"H": set servo position/temperature to low/medium/high


#PICAXE 08M2

symbol servoLowVal = 220
symbol servoMidVal = 150
symbol servoHiVal = 75

symbol knobServo = C.2

symbol receivedCommand = b0
symbol lastCommand = b1
symbol lastServoPos = b2


setup:
	sertxd("Servo Coprocessor 1.0 starting")
	servo knobServo, servoLowVal
	hsersetup B9600_4, %01000   'hserial input, non-inverted, 9600baud, disable hserout


'trap:
'	gosub setServoLow
'	pause 20
'goto trap

main:
	receivedCommand = $FF   '0xFF = flag for no data received
	hserin receivedCommand
	if receivedCommand != $FF then
		lastCommand = receivedCommand;
		time = 0                           'reset safety timeout counter
		if receivedCommand = "L" then
			gosub setServoLow
		elseif receivedCommand = "M" then
			gosub setServoMid
		elseif receivedCommand = "H" then
			gosub setServoHigh
		else
			'invalid/unknown command, default to shutdown heating
			gosub setServoLow
		endif
	endif
	if time > 600 then      'safety timeout, disable heating if no commands received in 10 minutes
		gosub setServoLow
		time = 0
	endif
	pause 20   'time for picaxe to handle servo background task
	goto main



''''''''--------------Servo Subroutines--------------''''''''''

setServoLow:
'if lastServoPos != servoLowVal then
	servopos knobServo, servoLowVal
'	lastServoPos = servoLowVal
'endif
return

setServoMid:
servopos knobServo, servoMidVal
return

setServoHigh:
servopos knobServo, servoHiVal
return



