
build: ReflowControl.bas
	python ./PicaxePreprocess/picaxepreprocess.py --tablesertxd -i ReflowControl.bas -o CompiledReflowControl.bas

syntax:
	python ./PicaxePreprocess/picaxepreprocess.py -s --tablesertxd -P ./PicaxePreprocess/compilers/ -i ReflowControl.bas -o CompiledReflowControl.bas

upload:
	python ./PicaxePreprocess/picaxepreprocess.py -u -c /dev/tty.usbserial-210 --tablesertxd -P ./PicaxePreprocess/compilers/ -i ReflowControl.bas -o CompiledReflowControl.bas


syntaxCoprocessor:
	python ./PicaxePreprocess/picaxepreprocess.py -s -P ./PicaxePreprocess/compilers/ -i servoCoprocessor.bas -o CompiledServoCoprocessor.bas

uploadCoprocessor:
	python ./PicaxePreprocess/picaxepreprocess.py -u -c /dev/tty.usbserial-210 -P ./PicaxePreprocess/compilers/ -i servoCoprocessor.bas -o CompiledServoCoprocessor.bas
