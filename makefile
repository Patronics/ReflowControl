
build: ReflowControl.bas
	python ./PicaxePreprocess/picaxepreprocess.py --tablesertxd -i ReflowControl.bas -o CompiledReflowControl.bas

syntax:
	python ./PicaxePreprocess/picaxepreprocess.py -s --tablesertxd -P ./PicaxePreprocess/compilers/ -i ReflowControl.bas -o CompiledReflowControl.bas

upload:
	python ./PicaxePreprocess/picaxepreprocess.py -u -c COM3 --tablesertxd -P ./PicaxePreprocess/compilers/ -i ReflowControl.bas -o CompiledReflowControl.bas

