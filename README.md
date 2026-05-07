# ReflowControl
Reflow oven controller for a toaster oven, using servo and themocouple

Uses a custom control board with PICAXE 20M2 originally developed for my Mech 90 project, along with an additional breakout board for the servo and thermocouple.

To build the software, you'll need the [PicaxePreprocess](https://github.com/Patronics/PicaxePreprocess) preprocessor.

Thermal profiles are read from an i2c 24LC256 EEPROM, with the format defined by the synalize-it grammar. Editing the ProfileList.reflow.bin files is recommended to be done in [Synalize-it](https://www.synalysis.net).

To upload to the EEPROM, I recommend using [pk2cmd](https://github.com/jaka-fi/pk2cmd) with a pickit 2 or pickit 3.

To backup the EEPROM before updating it, run `./pk2cmd -P24LC256 -#0x54 -GU"./backups/backupFileName.reflow.bin"`

To upload the new file, run `./pk2cmd -P24LC256 -#0x54 -F./Path/To/ProfileList.reflow.bin -MP -YP`