# ReflowControl
Reflow oven controller for a toaster oven, using servo and themocouple

Uses a custom control board with PICAXE 20M2 originally developed for my Mech 90 project, along with an additional breakout board for the servo and thermocouple.

To build the software, you'll need the [PicaxePreprocess](https://github.com/Patronics/PicaxePreprocess) preprocessor.

Thermal profiles are read from an i2c 24LC256 EEPROM, with the format defined by the synalize-it grammar. Editing the ProfileList.reflow.bin files is recommended to be done in [Synalize-it](https://www.synalysis.net).

To upload to the EEPROM, I recommend using [pk2cmd](https://github.com/jaka-fi/pk2cmd) with a pickit 2 or pickit 3.
